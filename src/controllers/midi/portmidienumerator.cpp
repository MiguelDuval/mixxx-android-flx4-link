#include "controllers/midi/portmidienumerator.h"

#include "controllers/midi/portmidicontroller.h"
#include "moc_portmidienumerator.cpp"

#ifdef __ANDROID__

#include <android/log.h>
#include <libusb.h>

#include <QNativeInterface>
#include <QJniObject>

namespace {
constexpr int kUsbClassAudio = 0x01;
constexpr int kUsbSubclassMidiStreaming = 0x03;
constexpr int kDdjFlx4VendorId = 0x2B73;
constexpr int kDdjFlx4ProductId = 0x0045;
}

PortMidiEnumerator::PortMidiEnumerator(UserSettingsPointer pConfig)
        : m_pConfig(std::move(pConfig)) {
}

PortMidiEnumerator::~PortMidiEnumerator() {
    qDebug() << "Deleting Android USB MIDI devices...";
    while (!m_devices.isEmpty()) {
        delete m_devices.takeLast();
    }
}

QList<Controller*> PortMidiEnumerator::queryDevices() {
    qInfo() << "Scanning Android USB MIDI devices";

    while (!m_devices.isEmpty()) {
        delete m_devices.takeLast();
    }

    QJniObject context = QNativeInterface::QAndroidApplication::context();
    QJniObject usbService = QJniObject::getStaticObjectField(
            "android/content/Context", "USB_SERVICE", "Ljava/lang/String;");
    auto usbManager = context.callObjectMethod(
            "getSystemService",
            "(Ljava/lang/String;)Ljava/lang/Object;",
            usbService.object());
    if (!usbManager.isValid()) {
        qCWarning(QLoggingCategory("controller.android-usb-midi"))
                << "Android USB manager is invalid";
        return {};
    }

    QJniObject deviceListObject = usbManager.callObjectMethod(
            "getDeviceList", "()Ljava/util/HashMap;");
    if (!deviceListObject.isValid()) {
        return {};
    }
    auto values = deviceListObject.callObjectMethod(
            "values", "()Ljava/util/Collection;");
    if (!values.isValid()) {
        return {};
    }
    QJniArray<QJniObject> devices(values.callObjectMethod<jobjectArray>("toArray"));

    for (const auto& device : devices) {
        const int vendorId = device.callMethod<jint>("getVendorId");
        const int productId = device.callMethod<jint>("getProductId");
        const QString productName = device.callMethod<jstring>("getProductName").toString();

        for (int interfaceIndex = 0;
                interfaceIndex < device.callMethod<jint>("getInterfaceCount");
                ++interfaceIndex) {
            auto usbInterface = device.callObjectMethod(
                    "getInterface",
                    "(I)Landroid/hardware/usb/UsbInterface;",
                    interfaceIndex);
            if (!usbInterface.isValid()) {
                continue;
            }

            const int interfaceClass =
                    usbInterface.callMethod<jint>("getInterfaceClass");
            const int interfaceSubclass =
                    usbInterface.callMethod<jint>("getInterfaceSubclass");
            const int interfaceNumber = usbInterface.callMethod<jint>("getId");

            qCInfo(QLoggingCategory("controller.android-usb-midi"))
                    << "USB device" << productName
                    << "VID" << QString::number(vendorId, 16)
                    << "PID" << QString::number(productId, 16)
                    << "interface" << interfaceNumber
                    << "class" << interfaceClass
                    << "subclass" << interfaceSubclass;

            // USB MIDI 1.0 is carried by an Audio-class MIDIStreaming interface.
            // FLX4 firmware exposes this as interface MI_03 / interface #3.
            if (interfaceClass != kUsbClassAudio ||
                    interfaceSubclass != kUsbSubclassMidiStreaming) {
                continue;
            }

            if (vendorId == kDdjFlx4VendorId && productId == kDdjFlx4ProductId) {
                qInfo() << "Found Pioneer DDJ-FLX4 USB MIDI interface #" << interfaceNumber;
            } else {
                qInfo() << "Found USB MIDI interface #" << interfaceNumber
                        << "on" << productName;
            }

            auto* controller = new PortMidiController(device, usbInterface);
            m_devices.push_back(controller);
        }
    }

    qInfo() << "Android USB MIDI enumeration found" << m_devices.size() << "devices";
    return m_devices;
}

#else

#include <portmidi.h>

#include <QRegularExpression>

#include "controllers/defs_controllers.h"
#include "util/cmdlineargs.h"

namespace {

bool recognizeDevice(const PmDeviceInfo& deviceInfo, UserSettingsPointer pConfig) {
    return CmdlineArgs::Instance().getDeveloper() ||
            pConfig->getValue(kMidiThroughCfgKey, false) ||
            !QLatin1String(deviceInfo.name)
                     .startsWith(kMidiThroughPortPrefix, Qt::CaseInsensitive);
}

const QRegularExpression kMidiDeviceNameRegex(QStringLiteral("^(.*) MIDI (\\d+)( .*)?$"));
const QRegularExpression kInputRegex(QStringLiteral("^(.*) in( \\d+)?( .*)?$"),
        QRegularExpression::CaseInsensitiveOption);
const QRegularExpression kOutputRegex(QStringLiteral("^(.*) out( \\d+)?( .*)?$"),
        QRegularExpression::CaseInsensitiveOption);
const QRegularExpression kDeviceNameRegex(QStringLiteral("^(.*) (\\d+)( [^0-9]+)?$"));

bool namesMatchRegexes(const QRegularExpression& inputRegex,
        const QString& inputName,
        const QRegularExpression& outputRegex,
        const QString& outputName) {
    const auto inputMatch = inputRegex.match(inputName);
    const auto outputMatch = outputRegex.match(outputName);
    return inputMatch.hasMatch() && outputMatch.hasMatch() &&
            outputMatch.captured(1).compare(inputMatch.captured(1), Qt::CaseInsensitive) == 0 &&
            outputMatch.captured(2) == inputMatch.captured(2);
}

bool namesMatchMidiPattern(const QString& inputName, const QString& outputName) {
    return namesMatchRegexes(kMidiDeviceNameRegex, inputName,
            kMidiDeviceNameRegex, outputName);
}

bool namesMatchInOutPattern(const QString& inputName, const QString& outputName) {
    return namesMatchRegexes(kInputRegex, inputName, kOutputRegex, outputName);
}

bool namesMatchPattern(const QString& inputName, const QString& outputName) {
    return namesMatchRegexes(kDeviceNameRegex, inputName, kDeviceNameRegex, outputName);
}

bool namesMatchAllowableEdgeCases(const QString& inputName, const QString& outputName) {
    return (inputName == "KAOSS DJ CONTROL" && outputName == "KAOSS DJ SOUND") ||
            (inputName == "MIDIIN2 (Ableton Push)" && outputName == "MIDIOUT2 (Ableton Push)") ||
            (inputName == "Launchpad X LPX DAW Out" && outputName == "Launchpad X LPX DAW In");
}

} // namespace

PortMidiEnumerator::PortMidiEnumerator(UserSettingsPointer pConfig)
        : m_pConfig(std::move(pConfig)) {
    PmError err = Pm_Initialize();
    if (err != pmNoError) {
        qWarning() << "PortMidi error:" << Pm_GetErrorText(err);
    }
}

PortMidiEnumerator::~PortMidiEnumerator() {
    qDebug() << "Deleting PortMIDI devices...";
    QListIterator<Controller*> dev_it(m_devices);
    while (dev_it.hasNext()) {
        delete dev_it.next();
    }
    PmError err = Pm_Terminate();
    if (err != pmNoError) {
        qWarning() << "PortMidi error:" << Pm_GetErrorText(err);
    }
}

bool shouldLinkInputToOutput(const QString& input_name,
        const QString& output_name) {
    if (input_name == output_name || namesMatchAllowableEdgeCases(input_name, output_name)) {
        return true;
    }
    QString input_name_stripped = input_name;
    if (input_name.indexOf("from", 0, Qt::CaseInsensitive) == 0) {
        input_name_stripped = input_name.right(input_name.length() - 4);
    }
    QString output_name_stripped = output_name;
    if (output_name.indexOf("to", 0, Qt::CaseInsensitive) == 0) {
        output_name_stripped = output_name.right(output_name.length() - 2);
    }
    if (output_name_stripped != input_name_stripped) {
        int offset = input_name_stripped.indexOf(" input ", 0, Qt::CaseInsensitive);
        if (offset != -1) {
            input_name_stripped.replace(offset, 7, " ");
        }
        offset = output_name_stripped.indexOf(" output ", 0, Qt::CaseInsensitive);
        if (offset != -1) {
            output_name_stripped.replace(offset, 8, " ");
        }
    }
    return input_name_stripped == output_name_stripped ||
            namesMatchMidiPattern(input_name_stripped, output_name_stripped) ||
            namesMatchMidiPattern(input_name, output_name) ||
            namesMatchInOutPattern(input_name_stripped, output_name_stripped) ||
            namesMatchInOutPattern(input_name, output_name) ||
            namesMatchPattern(input_name_stripped, output_name_stripped) ||
            namesMatchPattern(input_name, output_name);
}

QList<Controller*> PortMidiEnumerator::queryDevices() {
    qDebug() << "Scanning PortMIDI devices:";
    const int iNumDevices = Pm_CountDevices();
    for (Controller* device : std::as_const(m_devices)) {
        delete device;
    }
    m_devices.clear();

    const PmDeviceInfo* inputDeviceInfo = nullptr;
    const PmDeviceInfo* outputDeviceInfo = nullptr;
    int inputDevIndex = -1;
    int outputDevIndex = -1;
    QMap<int, QString> unassignedOutputDevices;

    for (int i = 0; i < iNumDevices; i++) {
        const PmDeviceInfo* pDeviceInfo = Pm_GetDeviceInfo(i);
        VERIFY_OR_DEBUG_ASSERT(pDeviceInfo) continue;
        if (!recognizeDevice(*pDeviceInfo, m_pConfig) || !pDeviceInfo->output) {
            continue;
        }
        unassignedOutputDevices[i] = pDeviceInfo->name;
    }

    for (int i = 0; i < iNumDevices; i++) {
        const PmDeviceInfo* pDeviceInfo = Pm_GetDeviceInfo(i);
        VERIFY_OR_DEBUG_ASSERT(pDeviceInfo) continue;
        if (!recognizeDevice(*pDeviceInfo, m_pConfig) || !pDeviceInfo->input) {
            continue;
        }
        inputDeviceInfo = pDeviceInfo;
        inputDevIndex = i;
        outputDeviceInfo = nullptr;
        outputDevIndex = -1;
        QMapIterator<int, QString> j(unassignedOutputDevices);
        while (j.hasNext()) {
            j.next();
            if (shouldLinkInputToOutput(inputDeviceInfo->name, j.value())) {
                outputDevIndex = j.key();
                outputDeviceInfo = Pm_GetDeviceInfo(outputDevIndex);
                unassignedOutputDevices.remove(outputDevIndex);
                break;
            }
        }
        m_devices.push_back(new PortMidiController(
                inputDeviceInfo, outputDeviceInfo, inputDevIndex, outputDevIndex));
    }
    return m_devices;
}

#endif
