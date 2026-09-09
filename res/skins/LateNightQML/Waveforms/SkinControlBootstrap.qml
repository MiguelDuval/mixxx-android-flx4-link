pragma ComponentBehavior: Bound

import Mixxx 1.0 as Mixxx
import QtQuick

Item {
    id: root

    visible: false
    property bool ready: false

    // The control must exist before any DeckWaveform ControlProxy for this
    // key completes. The ready flag is raised only after the creator has
    // completed, so the waveform UI can then be instantiated safely.
    Mixxx.SkinControlCreator {
        group: "[Skin]"
        key: "show_beatgrid_controls"
        defaultValue: 1.0
        persist: true
    }

    Component.onCompleted: {
        root.ready = true;
    }
}
