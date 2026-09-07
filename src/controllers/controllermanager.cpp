#include "controllers/controllermanager.h"

#include <QSet>
#include <QThread>

#include "controllers/controller.h"
#include "controllers/controllerlearningeventfilter.h"
#include "controllers/controllermappinginfoenumerator.h"
#include "controllers/defs_controllers.h"
#include "controllers/legacycontrollermappingfilehandler.h"
#include "moc_controllermanager.cpp"
#include "preferences/usersettings.h"
#include "util/cmdlineargs.h"
#include "util/compatibility/qmutex.h"
#include "util/duration.h"
#include "util/thread_affinity.h"
#include "util/time.h"

#if defined(__PORTMIDI__) || defined(__ANDROID__)
#include "controllers/midi/portmidienumerator.h"
#endif

#ifdef __HSS1394__
#include "controllers/midi/hss1394enumerator.h"
#endif

#ifdef __HID__
#include "controllers/hid/hidenumerator.h"
#endif

#ifdef __BULK__
#include "controllers/bulk/bulkenumerator.h"
#endif

#ifdef __LINUX__
const mixxx::Duration ControllerManager::kPollInterval = mixxx::Duration::fromMillis(5);
#else
const mixxx::Duration ControllerManager::kPollInterval = mixxx::Duration::fromMillis(1);
#endif

namespace {
QString sanitizeDeviceName(QString name) {
    return name.replace(" ", "_").replace("/", "_").replace("\\", "_");
}

QFileInfo findMappingFile(const QString& pathOrFilename, const QStringList& paths) {
    QFileInfo fileInfo(pathOrFilename);
    if (fileInfo.isAbsolute()) {
        return fileInfo;
    }
    for (const QString& path : paths) {
        fileInfo = QFileInfo(QDir(path).absoluteFilePath(pathOrFilename));
        if (fileInfo.exists()) {
            return fileInfo;
        }
    }
    return QFileInfo();
}

const QString kSettingsGroup = QLatin1String("[ControllerPreset]");
} // anonymous namespace

QString firstAvailableFilename(QSet<QString>& filenames,
        const QString& originalFilename) {
    QString filename = originalFilename;
    int i = 1;
    while (filenames.contains(filename)) {
        i++;
        filename = QString("%1--%2").arg(originalFilename, QString::number(i));
    }
    filenames.insert(filename);
    return filename;
}

bool controllerCompare(Controller* a, Controller* b) {
    return a->getName() < b->getName();
}

ControllerManager::ControllerManager(UserSettingsPointer pConfig)
        : QObject(),
          m_pConfig(pConfig),
          m_pControllerLearningEventFilter(
                  std::make_unique<ControllerLearningEventFilter>()),
          m_pollTimer(this),
          m_pThread(std::make_unique<QThread>()),
          m_skipPoll(false) {
    qRegisterMetaType<std::shared_ptr<LegacyControllerMapping>>(
            "std::shared_ptr<LegacyControllerMapping>");

    const QString userMappings = userMappingsPath(m_pConfig);
    if (!QDir(userMappings).exists()) {
        qDebug() << "Creating user controller mappings directory:" << userMappings;
        QDir().mkpath(userMappings);
    }

    m_pollTimer.setInterval(kPollInterval.toIntegerMillis());
    connect(&m_pollTimer, &QTimer::timeout, this, &ControllerManager::slotPollDevices);
    m_pThread->setObjectName("ControllerManager");
    moveToThread(m_pThread.get());
    m_pThread->start(QThread::HighPriority);

    connect(this, &ControllerManager::requestInitialize, this, &ControllerManager::slotInitialize);
    connect(this, &ControllerManager::requestSetUpDevices,
            this, &ControllerManager::slotSetUpDevices);
    connect(this, &ControllerManager::requestShutdown, this, &ControllerManager::slotShutdown);

    QMetaObject::invokeMethod(this, &ControllerManager::slotInitialize, Qt::QueuedConnection);
}

ControllerManager::~ControllerManager() {
    emit requestShutdown();
    m_pThread->wait();
}

ControllerLearningEventFilter* ControllerManager::getControllerLearningEventFilter() const {
    return m_pControllerLearningEventFilter.get();
}

void ControllerManager::slotInitialize() {
    DEBUG_ASSERT_THIS_QOBJECT_THREAD_AFFINITY();
    qDebug() << "ControllerManager:slotInitialize";

    m_pMainThreadUserMappingEnumerator =
            QSharedPointer<MappingInfoEnumerator>::create(userMappingsPath(m_pConfig));
    m_pMainThreadSystemMappingEnumerator =
            QSharedPointer<MappingInfoEnumerator>::create(resourceMappingsPath(m_pConfig));

    {
        auto locker = lockMutex(&m_mutex);
#if defined(__PORTMIDI__) || defined(__ANDROID__)
        m_enumerators.push_back(std::make_unique<PortMidiEnumerator>(m_pConfig));
#endif
#ifdef __HSS1394__
        m_enumerators.push_back(std::make_unique<Hss1394Enumerator>());
#endif
#ifdef __BULK__
        m_enumerators.push_back(std::make_unique<BulkEnumerator>());
#endif
#ifdef __HID__
        m_enumerators.push_back(std::make_unique<HidEnumerator>());
#endif
    }
    emit initialized();
}

void ControllerManager::slotShutdown() {
    DEBUG_ASSERT_THIS_QOBJECT_THREAD_AFFINITY();
    stopPolling();
    auto locker = lockMutex(&m_mutex);
    std::vector<std::unique_ptr<ControllerEnumerator>> enumerators = std::move(m_enumerators);
    locker.unlock();
    enumerators.clear();
    m_pThread->quit();
}

void ControllerManager::updateControllerList() {
    DEBUG_ASSERT_THIS_QOBJECT_THREAD_AFFINITY();
    auto locker = lockMutex(&m_mutex);
    if (m_enumerators.empty()) {
        qWarning() << "updateControllerList called but no enumerators have been added!";
        return;
    }
    std::vector<ControllerEnumerator*> enumerators;
    enumerators.reserve(m_enumerators.size());
    for (const auto& pEnumerator : m_enumerators) {
        enumerators.push_back(pEnumerator.get());
    }
    locker.unlock();

    QList<Controller*> newDeviceList;
    for (ControllerEnumerator* pEnumerator : enumerators) {
        newDeviceList.append(pEnumerator->queryDevices());
    }

    locker.relock();
    if (newDeviceList == m_controllers) {
        return;
    }
    m_controllers = std::move(newDeviceList);
    locker.unlock();
    emit devicesChanged();
}

QList<Controller*> ControllerManager::getControllers() const {
    const auto locker = lockMutex(&m_mutex);
    return m_controllers;
}

QList<Controller*> ControllerManager::getControllerList(bool bOutputDevices, bool bInputDevices) {
    qDebug() << "ControllerManager::getControllerList";

    auto locker = lockMutex(&m_mutex);
    QList<Controller*> controllers = m_controllers;
    locker.unlock();

    QList<Controller*> filteredDeviceList;
    for (Controller* device : controllers) {
        if ((bOutputDevices == device->isOutputDevice()) ||
            (bInputDevices == device->isInputDevice())) {
            filteredDeviceList.push_back(device);
        }
    }
    return filteredDeviceList;
}
