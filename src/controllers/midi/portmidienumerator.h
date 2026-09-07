#pragma once

#include "controllers/controllerenumerator.h"

#include "util/timer.h"

class PortMidiEnumerator final : public ControllerEnumerator {
  public:
    PortMidiEnumerator(UserSettingsPointer pConfig);
    ~PortMidiEnumerator() override;

    QList<Controller*> queryDevices() override;

  private:
    UserSettingsPointer m_pConfig;
    QList<Controller*> m_devices;
};