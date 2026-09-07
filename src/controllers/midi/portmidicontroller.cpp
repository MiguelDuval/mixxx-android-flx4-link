#include "controllers/midi/portmidicontroller.h"

#include "controllers/midi/midiutils.h"
#include "moc_portmidicontroller.cpp"

#ifdef __ANDROID__
namespace {
constexpr unsigned short kDdjFlx4VendorId = 0x2B73;
constexpr unsigned short kDdjFlx4ProductId = 0x0045;
constexpr int kUsbEndpointDirectionIn = 0x80;
constexpr int kUsbEndpointTransferTypeBulk = 0x02;

int midiCinLength(uint8_t cin) {
    switch (cin) {
    case 0x2: return 2;
    case 0x3:
    case 0x4:
    case 0x8:
    case 0x9:
    case 0xA:
    case 0xB:
    case 0xE: return 3;
    case 0x5:
    case 0xF: return 1;
    case 0x6:
    case 0xC:
    case 0xD: return 2;
    case 0x7: return 3;
    default: return 0;
    }
}

uint8_t midiCinForStatus(uint8_t status, int length) {
    const uint8_t opcode = status & 0xF0;
    if (status >= 0xF8) return 0xF;
    if (status >= 0xF0) {
        if (status == 0xF0) return length == 1 ? 0x5 : (length == 2 ? 0x6 : 0x4);
        if (status == 0xF1 || status == 0xF3) return 0x2;
        if (status == 0xF2) return 0x3;
        if (status == 0xF6) return 0x5;
        return 0xF;
    }
    switch (opcode) {
    case 0x80: return 0x8;
    case 0x90: return 0x9;
    case 0xA0: return 0xA;
    case 0xB0: return 0xB;
    case 0xC0: return 0xC;
    case 0xD0: return 0xD;
    case 0xE0: return 0xE;
    default: return 0xF;
    }
}
} // namespace
#endif

#ifndef __ANDROID__
namespace {
const QString kUnknownControllerName = QStringLiteral("Unknown PortMidiController");
} // namespace
#endif

#ifdef __ANDROID__
#include "controllers/android.h"

PortMidiController::PortMidiController(QJniObject usbDevice, QJniObject usbInterface)
        : MidiController([&usbDevice]() {
              const auto product = usbDevice.callMethod<jstring>("getProductName").toString();
              return product.isEmpty() ? QStringLiteral("Android USB MIDI") : product;
          }()),
          m_usbDevice(std::move(usbDevice)),
          m_usbInterface(std::move(usbInterface)),
          m_interfaceNumber(m_usbInterface.callMethod<jint>("getId")),
          m_vendorId(static_cast<uint16_t>(m_usbDevice.callMethod<jint>("getVendorId"))),
          m_productId(static_cast<uint16_t>(m_usbDevice.callMethod<jint>("getProductId"))) {
    m_vendorString = m_usbDevice.callMethod<jstring>("getManufacturerName").toString();
    m_productString = m_usbDevice.callMethod<jstring>("getProductName").toString();
    m_serialNumber = QStringLiteral("N/A");
    setInputDevice(true);
    setOutputDevice(true);
}

PortMidiController::~PortMidiController() {
    if (isOpen() || m_usbHandle) close();
}

bool PortMidiController::matchMapping(const MappingInfo& mapping) {
    const QList<ProductInfo>& products = mapping.getProducts();
    for (const auto& product : products) {
        if (m_vendorId && m_productId &&
                *m_vendorId == product.vendor_id.toUInt(nullptr, 16) &&
                *m_productId == product.product_id.toUInt(nullptr, 16) &&
                (product.interface_number.isEmpty() ||
                        m_interfaceNumber == product.interface_number.toInt(nullptr, 16))) {
            return true;
        }
    }
    return m_vendorId == kDdjFlx4VendorId && m_productId == kDdjFlx4ProductId;
}

bool PortMidiController::findEndpoints() {
    m_inputEndpoint = 0;
    m_outputEndpoint = 0;
    const int endpointCount = m_usbInterface.callMethod<jint>("getEndpointCount");
    for (int i = 0; i < endpointCount; ++i) {
        auto endpoint = m_usbInterface.callMethod<jobject>(
                "getEndpoint", "(I)Landroid/hardware/usb/UsbEndpoint;", i);
        const int address = endpoint.callMethod<jint>("getAddress");
        if (endpoint.callMethod<jint>("getType") != kUsbEndpointTransferTypeBulk) continue;
        if (address & kUsbEndpointDirectionIn) {
            m_inputEndpoint = static_cast<uint8_t>(address);
        } else {
            m_outputEndpoint = static_cast<uint8_t>(address);
        }
    }
    qInfo() << "Android USB MIDI endpoints for" << getName()
            << "interface" << m_interfaceNumber
            << "IN" << QString::number(m_inputEndpoint, 16)
            << "OUT" << QString::number(m_outputEndpoint, 16);
    return m_inputEndpoint != 0;
}

int PortMidiController::open(const QString& resourcePath) {
    if (isOpen()) return -1;
    Q_UNUSED(resourcePath);
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    QJniObject usbService = QJniObject::getStaticObjectField(
            "android/content/Context", "USB_SERVICE", "Ljava/lang/String;");
    auto usbManager = context.callObjectMethod(
            "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", usbService.object());
    if (!usbManager.isValid()) return -1;
    if (!usbManager.callMethod<jboolean>("hasPermission", "(Landroid/hardware/usb/UsbDevice;)Z", m_usbDevice)) {
        const auto& pendingIntent = mixxx::android::getIntent();
        usbManager.callMethod<void>("requestPermission",
                "(Landroid/hardware/usb/UsbDevice;Landroid/app/PendingIntent;)V",
                m_usbDevice, pendingIntent);
        if (!mixxx::android::waitForPermission(m_usbDevice)) return -1;
    }
    // The serial number may only be queried after USB permission is granted.
    const auto serial = m_usbDevice.callMethod<jstring>("getSerialNumber").toString();
    if (!serial.isEmpty()) m_serialNumber = serial;

    m_usbDeviceConnection = usbManager.callObjectMethod(
            "openDevice", "(Landroid/hardware/usb/UsbDevice;)Landroid/hardware/usb/UsbDeviceConnection;", m_usbDevice);
    if (!m_usbDeviceConnection.isValid()) return -1;
    if (!findEndpoints()) {
        m_usbDeviceConnection = QJniObject();
        return -1;
    }
    const auto fileDescriptor = static_cast<intptr_t>(
            m_usbDeviceConnection.callMethod<jint>("getFileDescriptor"));
    if (fileDescriptor < 0) {
        m_usbDeviceConnection = QJniObject();
        return -1;
    }
    const int initResult = libusb_init(&m_libusbContext);
    if (initResult != LIBUSB_SUCCESS || !m_libusbContext) {
        qCWarning(m_logBase) << "libusb_init failed:" << initResult;
        m_libusbContext = nullptr;
        m_usbDeviceConnection = QJniObject();
        return -1;
    }
    libusb_set_option(m_libusbContext, LIBUSB_OPTION_NO_DEVICE_DISCOVERY);
    const int wrapResult = libusb_wrap_sys_device(m_libusbContext, fileDescriptor, &m_usbHandle);
    if (wrapResult != LIBUSB_SUCCESS || !m_usbHandle) {
        qCWarning(m_logBase) << "libusb_wrap_sys_device failed:" << wrapResult;
        libusb_exit(m_libusbContext);
        m_libusbContext = nullptr;
        m_usbHandle = nullptr;
        m_usbDeviceConnection = QJniObject();
        return -1;
    }
    const int claimResult = libusb_claim_interface(m_usbHandle, m_interfaceNumber);
    if (claimResult != LIBUSB_SUCCESS) {
        qCWarning(m_logBase) << "Unable to claim USB MIDI interface" << m_interfaceNumber
                             << "error" << claimResult;
        libusb_close(m_usbHandle);
        m_usbHandle = nullptr;
        libusb_exit(m_libusbContext);
        m_libusbContext = nullptr;
        m_usbDeviceConnection = QJniObject();
        return -1;
    }
    m_timestamp.start();
    startEngine();
    if (!applyMapping(resourcePath)) {
        qCWarning(m_logBase) << "Failed to apply MIDI mapping to" << getName();
    }
    setOpen(true);
    return 0;
}

int PortMidiController::close() {
    if (!isOpen() && !m_usbHandle) return 0;
    stopEngine();
    MidiController::close();
    if (m_usbHandle) {
        libusb_release_interface(m_usbHandle, m_interfaceNumber);
        libusb_close(m_usbHandle);
        m_usbHandle = nullptr;
    }
    if (m_libusbContext) {
        libusb_exit(m_libusbContext);
        m_libusbContext = nullptr;
    }
    m_usbDeviceConnection = QJniObject();
    setOpen(false);
    return 0;
}

bool PortMidiController::parseUsbMidiPacket(const uint8_t* packet, int packetSize) {
    if (packetSize < 4) return false;
    const uint8_t cin = packet[0] & 0x0F;
    const int length = midiCinLength(cin);
    if (length <= 0) return false;
    const auto timestamp = mixxx::Duration::fromMillis(m_timestamp.elapsed());
    const uint8_t* data = packet + 1;
    if (cin == 0x4 || cin == 0x5 || cin == 0x6 || cin == 0x7) {
        return false; // SysEx handled through raw receive path in a future extension.
    }
    if (length >= 3) receivedShortMessage(data[0], data[1], data[2], timestamp);
    else if (length == 2) receivedShortMessage(data[0], data[1], 0, timestamp);
    else receivedShortMessage(data[0], 0, 0, timestamp);
    return true;
}

bool PortMidiController::poll() {
    if (!m_usbHandle || !isOpen() || m_inputEndpoint == 0) return false;
    uint8_t buffer[64];
    int actualLength = 0;
    const int result = libusb_bulk_transfer(
            m_usbHandle, m_inputEndpoint, buffer, sizeof(buffer), &actualLength, 1);
    if (result == LIBUSB_ERROR_TIMEOUT || actualLength <= 0) return false;
    if (result != LIBUSB_SUCCESS) {
        qCWarning(m_logInput) << "USB MIDI read failed:" << result;
        return false;
    }
    bool processed = false;
    for (int offset = 0; offset + 4 <= actualLength; offset += 4) {
        processed |= parseUsbMidiPacket(buffer + offset, 4);
    }
    return processed;
}

bool PortMidiController::sendUsbMidiPacket(uint8_t cin, const uint8_t* data, int length) {
    if (!m_usbHandle || m_outputEndpoint == 0 || length <= 0 || length > 3) return false;
    uint8_t packet[4] = {cin, 0, 0, 0};
    for (int i = 0; i < length; ++i) packet[i + 1] = data[i];
    int actualLength = 0;
    const int result = libusb_bulk_transfer(
            m_usbHandle, m_outputEndpoint, packet, sizeof(packet), &actualLength, 10);
    if (result != LIBUSB_SUCCESS || actualLength != 4) {
        qCWarning(m_logOutput) << "USB MIDI write failed:" << result
                               << "bytes" << actualLength;
        return false;
    }
    return true;
}

void PortMidiController::sendShortMsg(unsigned char status, unsigned char byte1,
        unsigned char byte2) {
    const int length = ((status & 0xF0) == 0xC0 || (status & 0xF0) == 0xD0) ? 2 : 3;
    const uint8_t data[] = {status, byte1, byte2};
    sendUsbMidiPacket(midiCinForStatus(status, length), data, length);
}

bool PortMidiController::sendBytes(const QByteArray& data) {
    if (!m_usbHandle || m_outputEndpoint == 0 || data.isEmpty()) return false;
    int offset = 0;
    while (offset < data.size()) {
        const int remaining = data.size() - offset;
        const int length = qMin(3, remaining);
        const bool isLast = remaining <= 3;
        const uint8_t cin = isLast ? (length == 1 ? 0x5 : (length == 2 ? 0x6 : 0x7)) : 0x4;
        const auto* bytes = reinterpret_cast<const uint8_t*>(data.constData() + offset);
        if (!sendUsbMidiPacket(cin, bytes, length)) return false;
        offset += length;
    }
    return true;
}

#else

PortMidiController::PortMidiController(const PmDeviceInfo* inputDeviceInfo,
        const PmDeviceInfo* outputDeviceInfo,
        int inputDeviceIndex,
        int outputDeviceIndex)
        : MidiController((inputDeviceInfo || outputDeviceInfo)
                          ? QString::fromLocal8Bit(inputDeviceInfo ? inputDeviceInfo->name : outputDeviceInfo->name)
                          : kUnknownControllerName),
          m_cReceiveMsg_index(0),
          m_bInSysex(false) {
    for (int k = 0; k < MIXXX_PORTMIDI_BUFFER_LEN; ++k) m_midiBuffer[k] = {0, 0};
    if (inputDeviceInfo) {
        setInputDevice(inputDeviceInfo->input);
        m_pInputDevice.reset(new PortMidiDevice(inputDeviceInfo, inputDeviceIndex));
    }
    if (outputDeviceInfo) {
        setOutputDevice(outputDeviceInfo->output);
        m_pOutputDevice.reset(new PortMidiDevice(outputDeviceInfo, outputDeviceIndex));
    }
}

PortMidiController::~PortMidiController() { if (isOpen()) close(); }

int PortMidiController::open(const QString& resourcePath) {
    if (isOpen()) return -1;
    if (getName() == MIXXX_PORTMIDI_NO_DEVICE_STRING) return -1;
    m_bInSysex = false;
    m_cReceiveMsg_index = 0;
    if (m_pInputDevice && isInputDevice()) {
        if (m_pInputDevice->openInput(MIXXX_PORTMIDI_BUFFER_LEN) != pmNoError) return -2;
    }
    if (m_pOutputDevice && isOutputDevice()) {
        if (m_pOutputDevice->openOutput() != pmNoError) return -2;
    }
    startEngine();
    applyMapping(resourcePath);
    setOpen(true);
    return 0;
}

int PortMidiController::close() {
    if (!isOpen()) return -1;
    stopEngine();
    MidiController::close();
    int result = 0;
    if (m_pInputDevice && m_pInputDevice->isOpen()) {
        if (m_pInputDevice->close() != pmNoError) result = -1;
    }
    if (m_pOutputDevice && m_pOutputDevice->isOpen()) {
        if (m_pOutputDevice->close() != pmNoError) result = -1;
    }
    setOpen(false);
    return result;
}

bool PortMidiController::poll() {
    if (m_pInputDevice.isNull() || !m_pInputDevice->isOpen()) return false;
    int numEvents = m_pInputDevice->read(m_midiBuffer, MIXXX_PORTMIDI_BUFFER_LEN);
    if (numEvents < 0) return false;
    for (int i = 0; i < numEvents; i++) {
        unsigned char status = Pm_MessageStatus(m_midiBuffer[i].message);
        mixxx::Duration timestamp = mixxx::Duration::fromMillis(m_midiBuffer[i].timestamp);
        if ((status & 0xF8) == 0xF8) {
            receivedShortMessage(status, 0, 0, timestamp);
            continue;
        }
reprocessMessage:
        if (!m_bInSysex) {
            if (status == 0xF0) { m_bInSysex = true; status = 0; }
            else receivedShortMessage(status, Pm_MessageData1(m_midiBuffer[i].message), Pm_MessageData2(m_midiBuffer[i].message), timestamp);
        }
        if (m_bInSysex) {
            if (status > 0x7F && status < 0xF7) {
                m_bInSysex = false;
                m_cReceiveMsg_index = 0;
                goto reprocessMessage;
            }
            uint8_t data = 0;
            for (int shift = 0; shift < 32 && data != MidiUtils::opCodeValue(MidiOpCode::EndOfExclusive); shift += 8) {
                data = (m_midiBuffer[i].message >> shift) & 0xFF;
                if (m_cReceiveMsg_index < MIXXX_SYSEX_BUFFER_LEN) m_cReceiveMsg[m_cReceiveMsg_index++] = data;
            }
            if (data == MidiUtils::opCodeValue(MidiOpCode::EndOfExclusive)) {
                m_bInSysex = false;
                const char* buffer = reinterpret_cast<const char*>(m_cReceiveMsg);
                receive(QByteArray::fromRawData(buffer, m_cReceiveMsg_index), timestamp);
                m_cReceiveMsg_index = 0;
            }
        }
    }
    return numEvents > 0;
}

void PortMidiController::sendShortMsg(unsigned char status, unsigned char byte1, unsigned char byte2) {
    if (m_pOutputDevice.isNull() || !m_pOutputDevice->isOpen()) return;
    const unsigned int word = (((unsigned int)byte2) << 16) | (((unsigned int)byte1) << 8) | status;
    m_pOutputDevice->writeShort(word);
}

bool PortMidiController::sendBytes(const QByteArray& data) {
    if (!data.endsWith(MidiUtils::opCodeValue(MidiOpCode::EndOfExclusive)) ||
            m_pOutputDevice.isNull() || !m_pOutputDevice->isOpen()) return false;
    return m_pOutputDevice->writeSysEx((unsigned char*)data.constData()) == pmNoError;
}

#endif
