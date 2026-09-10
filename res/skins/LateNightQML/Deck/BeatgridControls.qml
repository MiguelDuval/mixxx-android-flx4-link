import QtQuick
import QtQuick.Layouts
import Mixxx 1.0 as Mixxx
import "../LateNightTheme"
import "../Waveforms" as Waveforms

// Deck-local Android adapter for the BeatGrid editor.
//
// FullDeck.qml instantiates BeatgridControls without a namespace. Because this
// file lives in the Deck directory it provides a deck-local implementation and
// explicitly delegates the real editor to Waveforms.BeatgridControls.
// This is intentional: it lets us remove the dependency on the old global
// [Skin] show_beatgrid_controls path while retaining the upstream engine keys.
Item {
    id: root

    required property string group
    width: 104
    height: 52

    // Make the deck-local editor usable even if the old [Skin] visibility
    // control has never been initialized. This is deliberately one-way: the
    // existing FullDeck toggle can still hide it afterwards.
    Component.onCompleted: {
        var p = parent;
        while (p && p.showBeatgridControlsLocal === undefined) {
            p = p.parent;
        }
        if (p) {
            p.showBeatgridControlsLocal = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: LateNightTheme.deckPanelColor
        border.width: 1
        border.color: LateNightTheme.deckPanelBorderLight
    }

    // The actual upstream Mixxx editor. Its controls are bound directly to
    // [Channel1] / [Channel2] via root.group.
    Waveforms.BeatgridControls {
        id: upstreamControls
        anchors.fill: parent
        group: root.group
    }

    // A compact, explicit action row is provided in addition to the upstream
    // controls. These are real engine controls, not UI-only state.
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 24
        spacing: 1
        visible: false

        LateNightControlButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            group: root.group
            key: "beats_translate_earlier"
            text: "<"
        }

        LateNightControlButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            group: root.group
            key: "beats_translate_curpos"
            text: "SET"
        }

        LateNightControlButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            group: root.group
            key: "beats_translate_later"
            text: ">"
        }
    }
}
