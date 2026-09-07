#include "controllers/controllermappinginfoenumerator.h"

#include <QDirIterator>

#include "controllers/defs_controllers.h"

namespace {
bool mappingInfoNameComparator(const MappingInfo& a, const MappingInfo& b) {
    if (a.getDirPath() == b.getDirPath()) {
        // FIXME: Mixxx copies every loaded mapping into the user mapping folder
        // with a different file name. This is confusing, especially when developing
        // a mapping and working on it in the user mapping folder. Sorting
        // by file path here is a quick hack to keep the identically named mappings
        // in a consistent order.
        if (a.getName() == b.getName()) {
            return a.getPath() < b.getPath();
        } else {
            return a.getName() < b.getName();
        }
    } else {
        return a.getDirPath() < b.getDirPath();
    }
}
} // namespace

MappingInfoEnumerator::MappingInfoEnumerator(const QString& searchPath)
        : MappingInfoEnumerator(QList<QString>{searchPath}) {
}

MappingInfoEnumerator::MappingInfoEnumerator(const QStringList& searchPaths)
        : m_controllerDirPaths(searchPaths) {
    loadSupportedMappings();
}

QList<MappingInfo> MappingInfoEnumerator::getMappingsByExtension(const QString& extension) {
    if (extension == MIDI_MAPPING_EXTENSION) {
        return m_midiMappings;
    } else if (extension == HID_MAPPING_EXTENSION) {
        return m_hidMappings;
    } else if (extension == BULK_MAPPING_EXTENSION) {
        return m_bulkMappings;
    }

    qDebug() << "Extension not registered to mappinginfo" << extension;
    return QList<MappingInfo>();
}

void MappingInfoEnumerator::loadSupportedMappings() {
    m_midiMappings.clear();
    m_hidMappings.clear();
    m_bulkMappings.clear();

    for (const QString& dirPath : std::as_const(m_controllerDirPaths)) {
        QDirIterator it(dirPath);
        while (it.hasNext()) {
            it.next();
            const QFileInfo fileInfo = it.fileInfo();
            const QString path = fileInfo.filePath();

            if (path.endsWith(MIDI_MAPPING_EXTENSION, Qt::CaseInsensitive)) {
                m_midiMappings.append(MappingInfo(fileInfo));
            } else if (path.endsWith(HID_MAPPING_EXTENSION, Qt::CaseInsensitive)) {
                m_hidMappings.append(MappingInfo(fileInfo));
            } else if (path.endsWith(BULK_MAPPING_EXTENSION, Qt::CaseInsensitive)) {
                m_bulkMappings.append(MappingInfo(fileInfo));
            }
        }
    }

#ifdef __ANDROID__
    // Android assets are accessible through QFile but are not consistently
    // enumerable through QDirIterator on all Qt/Android combinations. The
    // FLX4 mapping is shipped in the APK already, so explicitly register it
    // when it is not returned by directory enumeration.
    const QString flx4Path =
            QStringLiteral("assets:/controllers/Pioneer-DDJ-FLX4.midi.xml");
    bool flx4AlreadyListed = false;
    for (const MappingInfo& mapping : std::as_const(m_midiMappings)) {
        if (mapping.getPath() == flx4Path) {
            flx4AlreadyListed = true;
            break;
        }
    }
    if (!flx4AlreadyListed) {
        const QFileInfo flx4File(flx4Path);
        if (flx4File.exists() && flx4File.isReadable()) {
            const MappingInfo flx4Mapping(flx4File);
            if (flx4Mapping.isValid()) {
                m_midiMappings.append(flx4Mapping);
            }
        }
    }
#endif

    std::sort(m_midiMappings.begin(), m_midiMappings.end(), mappingInfoNameComparator);
    std::sort(m_hidMappings.begin(), m_hidMappings.end(), mappingInfoNameComparator);
    std::sort(m_bulkMappings.begin(), m_bulkMappings.end(), mappingInfoNameComparator);

    qDebug() << "Extension" << MIDI_MAPPING_EXTENSION << "total"
             << m_midiMappings.length() << "mappings";
    qDebug() << "Extension" << HID_MAPPING_EXTENSION << "total"
             << m_hidMappings.length() << "mappings";
    qDebug() << "Extension" << BULK_MAPPING_EXTENSION << "total"
             << m_bulkMappings.length() << "mappings";
}
