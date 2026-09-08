#pragma once

#ifndef __ANDROID__
#include <portmidi.h>
#include <QScopedPointer>
#else
#include <QElapsedTimer>
#include <QJniObject>
#include <libusb.h>
#endif

#include "controllers/midi/midicontroller.h"

#ifndef __ANDROID__
#define MIXXX_PORTMIDI_BUFFER_LEN 1024
#define MIXXX_SYSEX_BUFFER_LEN 1024
#define MIXXX_PORTMIDI_NO_DEVICE_STRING "None"
#else
#define MIXXX_SYSEX_BUFFER_LEN 1024
#endif

class PortMidiController final : public MidiController {
    Q_OBJECT
  public:
#ifndef __ANDROID__
    PortMidiController(const PmDeviceInfo* inputDeviceInfo,
            const PmDeviceInfo* outputDeviceInfo,
            int inputDeviceIndex,
            int outputDeviceIndex);
#else
    PortMidiController(QJniObject usbDevice, QJniObject usbInterface);
#endif
    ~PortMidiController() override;

    PhysicalTransportProtocol getPhysicalTransportProtocol() const override {
#ifndef __ANDROID__
        return PhysicalTransportProtocol::UNKNOWN;
#else
        return PhysicalTransportProtocol::USB;
#endif
    }

    QString getVendorString() const override {
#ifdef __ANDROID__
        return m_vendorString;
#else
        return QString();
#endif
    }

    QString getProductString() const override {
#ifdef __ANDROID__
        return m_productString;
#else
        if (m_pInputDevice) {
            return QString::fromLocal8Bit(m_pInputDevice->info()->name);
        }
        if (m_pOutputDevice) {
            return QString::fromLocal8Bit(m_pOutputDevice->info()->name);
        }
        return QString();
#endif
    }

    std::optional<uint16_t> getVendorId() const override {
#ifdef __ANDROID__
        return m_vendorId;
#else
        return std::nullopt;
#endif
    }

    std::optional<uint16_t> getProductId() const override {
#ifdef __ANDROID__
        return m_productId;
#else
        return std::nullopt;
#endif
    }

    QString getSerialNumber() const override {
#ifdef __ANDROID__
        return m_serialNumber;
#else
        return QString();
#endif
    }

    std::optional<uint8_t> getUsbInterfaceNumber() const override {
#ifdef __ANDROID__
        if (m_interfaceNumber >= 0) {
            return static_cast<uint8_t>(m_interfaceNumber);
        }
#endif
        return std::nullopt;
    }

    bool matchMapping(const MappingInfo& mapping) override;

  private slots:
    bool poll() override;

  protected:
    void sendShortMsg(unsigned char status, unsigned char byte1,
                      unsigned char byte2) override;

  private:
    int open(const QString& resourcePath) override;
    int close() override;
    bool sendBytes(const QByteArray& data) override;

#ifdef __ANDROID__
    bool isPolling() const override {
        return true;
    }

    bool findEndpoints();
    bool parseUsbMidiPacket(const uint8_t* packet, int packetSize);
    bool sendUsbMidiPacket(uint8_t cin, const uint8_t* data, int length);

    QJniObject m_usbDevice;
    QJniObject m_usbInterface;
    QJniObject m_usbDeviceConnection;
    libusb_context* m_libusbContext{nullptr};
    libusb_device_handle* m_usbHandle{nullptr};
    int m_interfaceNumber{-1};
    uint8_t m_inputEndpoint{0};
    uint8_t m_outputEndpoint{0};
    QElapsedTimer m_timestamp;
    std::optional<uint16_t> m_vendorId;
    std::optional<uint16_t> m_productId;
    QString m_vendorString;
    QString m_productString;
    QString m_serialNumber;
#else
    bool isPolling() const override {
        return true;
    }

    QScopedPointer<class PortMidiDevice> m_pInputDevice;
    QScopedPointer<class PortMidiDevice> m_pOutputDevice;
    PmEvent m_midiBuffer[MIXXX_PORTMIDI_BUFFER_LEN];
    unsigned char m_cReceiveMsg[MIXXX_SYSEX_BUFFER_LEN];
    int m_cReceiveMsg_index{0};
    bool m_bInSysex{false};
#endif
};