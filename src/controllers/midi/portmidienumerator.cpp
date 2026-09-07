#include "controllers/midi/portmidienumerator.h"

#ifndef __ANDROID__
#include <portmidi.h>
#endif

#include <QRegularExpression>
#ifdef __ANDROID__
#include <QJniEnvironment>
#include <QJniObject>
#endif

#include "controllers/defs_controllers.h"
#include "controllers/midi/portmidicontroller.h"
#include "util/cmdlineargs.h"

#ifdef __ANDROID__
#include "controllers/android.h"
#endif

namespace {

#ifndef __ANDROID__
bool recognizeDevice(const PmDeviceInfo& deviceInfo, UserSettingsPointer pConfig) {
    // In developer mode we show the MIDI Through Port, otherwise ignore it
    // since it routinely causes trouble.
    return CmdlineArgs::Instance().getDeveloper() ||
            pConfig->getValue(kMidiThroughCfgKey, false) ||
            !QLatin1String(deviceInfo.name)
                     .startsWith(kMidiThroughPortPrefix, Qt::CaseInsensitive);
}
#endif

// Some platforms format MIDI device names as "deviceName MIDI ###" where
// ### is the instance # of the device. Therefore we want to link two
// devices that have an equivalent "deviceName" and ### section.
const QRegularExpression kMidiDeviceNameRegex(QStringLiteral("^(.*) MIDI (\\d+)( .*)?$"));

const QRegularExpression kInputRegex(QStringLiteral("^(.*) in( \\d+)?( .*)?$"),
        QRegularExpression::CaseInsensitiveOption);
const QRegularExpression kOutputRegex(QStringLiteral("^(.*) out( \\d+)?( .*)?$"),
        QRegularExpression::CaseInsensitiveOption);

// This is a broad pattern that matches a text blob followed by a numeral
// potentially followed by non-numeric text. The non-numeric requirement is
// meant to avoid corner cases around devices with names like "Hercules RMX
// 2" where we would potentially confuse the number in the device name as the
// ordinal index of the device.
const QRegularExpression kDeviceNameRegex(QStringLiteral("^(.*) (\\d+)( [^0-9]+)?$"));

bool namesMatchRegexes(const QRegularExpression& kInputRegex,
        const QString& input_name,
        const QRegularExpression& kOutputRegex,
        const QString& output_name) {
    QRegularExpressionMatch inputMatch = kInputRegex.match(input_name);
    if (inputMatch.hasMatch()) {
        QString inputDeviceName = inputMatch.captured(1);
        QString inputDeviceIndex = inputMatch.captured(2);
        QRegularExpressionMatch outputMatch = kOutputRegex.match(output_name);
        if (outputMatch.hasMatch()) {
            QString outputDeviceName = outputMatch.captured(1);
            QString outputDeviceIndex = outputMatch.captured(2);
            if (outputDeviceName.compare(inputDeviceName, Qt::CaseInsensitive) == 0 &&
                outputDeviceIndex == inputDeviceIndex) {
                return true;
            }
        }
    }
    return false;
}

bool namesMatchMidiPattern(const QString& input_name,
        const QString& output_name) {
    return namesMatchRegexes(kMidiDeviceNameRegex, input_name, kMidiDeviceNameRegex, output_name);
}

bool namesMatchInOutPattern(const QString& input_name,
        const QString& output_name) {
    return namesMatchRegexes(kInputRegex, input_name, kOutputRegex, output_name);
}

bool namesMatchPattern(const QString& input_name,
        const QString& output_name) {
    return namesMatchRegexes(kDeviceNameRegex, input_name, kDeviceNameRegex, output_name);
}

bool namesMatchAllowableEdgeCases(const QString& input_name,
        const QString& output_name) {
    // Mac OS 10.12 & Korg Kaoss DJ 1.6:
    // Korg Kaoss DJ has input 'KAOSS DJ CONTROL' and output 'KAOSS DJ SOUND'.
    // This means it doesn't pass the shouldLinkInputToOutput test. Without an
    // output linked, the MIDI output for the device fails, as the device is
    // NULL in PortMidiController
    if (input_name == "KAOSS DJ CONTROL" && output_name == "KAOSS DJ SOUND") {
        return true;
    }
    // Ableton Push on Windows
    // Shows 2 different devices for MIDI input and output.
    if (input_name == "MIDIIN2 (Ableton Push)" && output_name == "MIDIOUT2 (Ableton Push)") {
        return true;
    }

    // Novation Launchpad X (macOS)
    if (input_name == "Launchpad X LPX DAW Out" && output_name == "Launchpad X LPX DAW In") {
        return true;
    }

    return false;
}

} // namespace

PortMidiEnumerator::PortMidiEnumerator(UserSettingsPointer pConfig)
        : m_pConfig(pConfig) {
#ifndef __ANDROID__
    PmError err = Pm_Initialize();
    // Based on reading the source, it's not possible for this to fail.
    if (err != pmNoError) {
        qWarning() << "PortMidi error:" << Pm_GetErrorText(err);
    }
#endif
}

PortMidiEnumerator::~PortMidiEnumerator() {
    qDebug() << "Deleting PortMIDI devices...";
    QListIterator<Controller*> dev_it(m_devices);
    while (dev_it.hasNext()) {
        delete dev_it.next();
    }
#ifndef __ANDROID__
    PmError err = Pm_Terminate();
    // Based on reading the source, it's not possible for this to fail.
    if (err != pmNoError) {
        qWarning() << "PortMidi error:" << Pm_GetErrorText(err);
    }
#endif
}

bool shouldLinkInputToOutput(const QString& input_name,
        const QString& output_name) {
    // Early exit.
    if (input_name == output_name || namesMatchAllowableEdgeCases(input_name, output_name)) {
        return true;
    }

    // Some device drivers prepend "To" and "From" to the names of their MIDI
    // ports. If the output and input device names don't match, let's try
    // trimming those words from the start, and seeing if they then match.

    // Ignore "From" text in the beginning of device input name.
    QString input_name_stripped = input_name;
    if (input_name.indexOf("from", 0, Qt::CaseInsensitive) == 0) {
        input_name_stripped = input_name.right(input_name.length() - 4);
    }

    // Ignore "To" text in the beginning of device output name.
    QString output_name_stripped = output_name;
    if (output_name.indexOf("to", 0, Qt::CaseInsensitive) == 0) {
        output_name_stripped = output_name.right(output_name.length() - 2);
    }

    if (output_name_stripped != input_name_stripped) {
        // Ignore " input " text in the device names
        int offset = input_name_stripped.indexOf(" input ", 0,
                                                 Qt::CaseInsensitive);
        if (offset != -1) {
            input_name_stripped = input_name_stripped.replace(offset, 7, " ");
        }

        // Ignore " output " text in the device names
        offset = output_name_stripped.indexOf(" output ", 0,
                                              Qt::CaseInsensitive);
        if (offset != -1) {
            output_name_stripped = output_name_stripped.replace(offset, 8, " ");
        }
    }

    if (input_name_stripped == output_name_stripped ||
        namesMatchMidiPattern(input_name_stripped, output_name_stripped) ||
        namesMatchMidiPattern(input_name, output_name) ||
        namesMatchInOutPattern(input_name_stripped, output_name_stripped) ||
        namesMatchInOutPattern(input_name, output_name) ||
        namesMatchPattern(input_name_stripped, output_name_stripped) ||
        namesMatchPattern(input_name, output_name)) {
        return true;
    }

    return false;
}

/// Enumerate the MIDI devices
/// This method needs a bit of intelligence because PortMidi (and the underlying
/// MIDI APIs) like to split output and input into separate devices. Eg.
/// PortMidi would tell us the Hercules is two half-duplex devices. To help
/// simplify a lot of code, we're going to aggregate these two streams into a
/// single full-duplex device.
QList<Controller*> PortMidiEnumerator::queryDevices() {
#ifdef __ANDROID__
    qDebug() << "Scanning Android USB MIDI devices:";

    QListIterator<Controller*> dev_it(m_devices);
    while (dev_it.hasNext()) {
        delete dev_it.next();
    }
    m_devices.clear();

    const QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        qWarning() << "Android context is invalid while enumerating USB MIDI devices";
        return m_devices;
    }

    const QJniObject usbService = QJniObject::getStaticObjectField(
            "android/content/Context", "USB_SERVICE", "Ljava/lang/String;");
    const QJniObject usbManager = context.callObjectMethod(
            "getSystemService",
            "(Ljava/lang/String;)Ljava/lang/Object;",
            usbService.object());
    if (!usbManager.isValid()) {
        qWarning() << "Android USB manager is invalid";
        return m_devices;
    }

    const QJniObject deviceList = usbManager.callObjectMethod(
            "getDeviceList",
            "()Ljava/util/HashMap;");
    if (!deviceList.isValid()) {
        qWarning() << "Android USB device list is invalid";
        return m_devices;
    }

    const QJniObject values = deviceList.callObjectMethod(
            "values",
            "()Ljava/util/Collection;");
    const QJniObject devicesArrayObject = values.callObjectMethod(
            "toArray",
            "()[Ljava/lang/Object;");
    if (!devicesArrayObject.isValid()) {
        qWarning() << "Android USB device array is invalid";
        return m_devices;
    }

    const auto devicesArray = devicesArrayObject.object<jobjectArray>();
    QJniEnvironment env;
    const jsize deviceCount = env->GetArrayLength(devicesArray);

    for (jsize deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const jobject deviceObject = env->GetObjectArrayElement(devicesArray, deviceIndex);
        if (!deviceObject) {
            continue;
        }

        const QJniObject device(deviceObject);
        env->DeleteLocalRef(deviceObject);

        const jint vendorId = device.callMethod<jint>("getVendorId");
        const jint productId = device.callMethod<jint>("getProductId");
        const QJniObject productNameObject = device.callObjectMethod(
                "getProductName",
                "()Ljava/lang/String;");
        const QString productName = productNameObject.toString();

        const jint interfaceCount = device.callMethod<jint>("getInterfaceCount");
        qDebug() << "USB device" << productName
                 << "VID" << QString::number(vendorId, 16)
                 << "PID" << QString::number(productId, 16)
                 << "interfaces" << interfaceCount;

        for (jint interfaceIndex = 0; interfaceIndex < interfaceCount; ++interfaceIndex) {
            const QJniObject usbInterface = device.callObjectMethod(
                    "getInterface",
                    "(I)Landroid/hardware/usb/UsbInterface;",
                    interfaceIndex);
            if (!usbInterface.isValid()) {
                continue;
            }

            const jint interfaceClass = usbInterface.callMethod<jint>("getInterfaceClass");
            const jint interfaceSubclass = usbInterface.callMethod<jint>("getInterfaceSubclass");

            qDebug() << "  interface" << interfaceIndex
                     << "class" << interfaceClass
                     << "subclass" << interfaceSubclass;

            // USB Audio class (0x01), MIDI Streaming subclass (0x03).
            // HID interfaces on the same composite controller are deliberately
            // ignored here; they are enumerated by the HID controller backend.
            if (interfaceClass != 0x01 || interfaceSubclass != 0x03) {
                continue;
            }

            auto* midiDevice = new PortMidiController(device, usbInterface);
            m_devices.push_back(midiDevice);
        }
    }

    qDebug() << "Android USB MIDI devices found:" << m_devices.size();
    return m_devices;
#else
    qDebug() << "Scanning PortMIDI devices:";

    int iNumDevices = Pm_CountDevices();

    QListIterator<Controller*> dev_it(m_devices);
    while (dev_it.hasNext()) {
        delete dev_it.next();
    }

    m_devices.clear();

    const PmDeviceInfo* inputDeviceInfo = nullptr;
    const PmDeviceInfo* outputDeviceInfo = nullptr;
    int inputDevIndex = -1;
    int outputDevIndex = -1;
    QMap<int, QString> unassignedOutputDevices;

    // Build a complete list of output devices for later pairing
    for (int i = 0; i < iNumDevices; i++) {
        const PmDeviceInfo* pDeviceInfo = Pm_GetDeviceInfo(i);
        VERIFY_OR_DEBUG_ASSERT(pDeviceInfo) {
            continue;
        }
        if (!recognizeDevice(*pDeviceInfo, m_pConfig) || !pDeviceInfo->output) {
            continue;
        }
        qDebug() << " Found output device"
                 << "#" << i << pDeviceInfo->name;
        QString deviceName = pDeviceInfo->name;
        unassignedOutputDevices[i] = deviceName;
    }

    // Search for input devices and pair them with output devices if applicable
    for (int i = 0; i < iNumDevices; i++) {
        const PmDeviceInfo* pDeviceInfo = Pm_GetDeviceInfo(i);
        VERIFY_OR_DEBUG_ASSERT(pDeviceInfo) {
            continue;
        }
        if (!recognizeDevice(*pDeviceInfo, m_pConfig) || !pDeviceInfo->input) {
            // Is there a use case for output-only devices such as message
            // displays? Then this condition has to be split and
            // deviceInfo->output also needs to be checked and handled.
            continue;
        }

        qDebug() << " Found input device"
                 << "#" << i << pDeviceInfo->name;
        inputDeviceInfo = pDeviceInfo;
        inputDevIndex = i;

        //Reset our output device variables before we look for one in case we find none.
        outputDeviceInfo = nullptr;
        outputDevIndex = -1;

        //Search for a corresponding output device
        QMapIterator<int, QString> j(unassignedOutputDevices);
        while (j.hasNext()) {
            j.next();

            QString deviceName = inputDeviceInfo->name;
            QString outputName = QString(j.value());

            if (shouldLinkInputToOutput(deviceName, outputName)) {
                outputDevIndex = j.key();
                outputDeviceInfo = Pm_GetDeviceInfo(outputDevIndex);

                unassignedOutputDevices.remove(outputDevIndex);

                qDebug() << "    Linking to output device #" << outputDevIndex << outputName;
                break;
            }
        }

        // So at this point, we either have an input-only MIDI device
        // (outputDeviceInfo == NULL) or we've found a matching output MIDI
        // device (outputDeviceInfo != NULL).

        //.... so create our (aggregate) MIDI device!
        PortMidiController* currentDevice =
                new PortMidiController(inputDeviceInfo,
                        outputDeviceInfo,
                        inputDevIndex,
                        outputDevIndex);
        m_devices.push_back(currentDevice);
    }
    return m_devices;
#endif
}
