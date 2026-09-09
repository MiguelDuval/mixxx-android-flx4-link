pragma ComponentBehavior: Bound

import QtQuick
import Mixxx 1.0 as Mixxx

Item {
    id: root

    required property string group

    readonly property real beatgridControlsX: beatgridControls.x
    readonly property real beatgridControlsWidth: beatgridControls.width
    readonly property bool beatgridControlsVisible: beatgridControls.visible

    Mixxx.ControlProxy {
        id: showBeatgridControlsProxy
        group: "[Skin]"
        key: "show_beatgrid_controls"
    }

    LateNightWaveformDisplay {
        id: waveformDisplay

        anchors.fill: parent
        group: root.group
    }

    BeatgridControls {
        id: beatgridControls

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 26
        anchors.top: parent.top
        group: root.group
        visible: showBeatgridControlsProxy.value > 0
        width: Math.min(implicitWidth, Math.max(0, parent.width - 26))
        z: 1
    }
}
