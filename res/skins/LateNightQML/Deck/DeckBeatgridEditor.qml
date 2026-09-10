import QtQuick
import "../Waveforms" as Waveforms

Item {
    id: root
    required property string group
    implicitWidth: 104
    implicitHeight: 52

    // This editor is explicitly instantiated by FullDeck, so it cannot be
    // confused with another BeatgridControls type imported from Waveforms.
    // The actual buttons remain the upstream Mixxx implementation and use the
    // deck group supplied by FullDeck ([Channel1] / [Channel2]).
    Waveforms.BeatgridControls {
        anchors.fill: parent
        group: root.group
    }
}
