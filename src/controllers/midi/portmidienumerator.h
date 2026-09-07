#pragma once

#include "controllers/midi/midienumerator.h"
#include "preferences/usersettings.h"

#ifdef __ANDROID__
#include <QJniObject>
#else
#include <portmidi.h>
#endif

/// Handles discovery of MIDI controllers.
/// Desktop builds use PortMidi. Android builds enumerate class-compliant
/// USB MIDI Streaming interfaces directly through Android USB/libusb.
class PortMidiEnumerator : public MidiEnumerator {
    Q_OBJECT
  public:
    explicit PortMidiEnumerator(UserSettingsPointer pConfig);
    ~PortMidiEnumerator() override;

    QList<Controller*> queryDevices() override;

  private:
    QList<Controller*> m_devices;
    UserSettingsPointer m_pConfig;
};

#ifndef __ANDROID__
bool shouldLinkInputToOutput(const QString& input_name,
        const QString& output_name);
#endif
