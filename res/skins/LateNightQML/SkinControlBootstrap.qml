pragma ComponentBehavior: Bound

import Mixxx 1.0 as Mixxx
import QtQuick

Item {
    id: root

    visible: false
    property bool ready: false

    // Controls referenced by QML children must exist before their ControlProxy
    // objects finish construction. The upstream LateNight QML skin creates
    // these controls in a bootstrap component for exactly that reason.
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
