pragma ComponentBehavior: Bound

import QtQuick
import Mixxx 1.0 as Mixxx

Item {
    id: root

    required property string group

    readonly property real beatgridControlsX: beatgridControls.x
    readonly property real beatgridControlsWidth: beatgridControls.width
    readonly property bool beatgridControlsVisible: beatgridControls.visible

    // Access per-deck beatgrid visibility from parent FullDeck
    readonly property bool showBeatgridControls: root.showBeatgridControls

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
        visible: root.showBeatgridControls
        width: Math.min(implicitWidth, Math.max(0, parent.width - 26))
        z: 1
    }
}
