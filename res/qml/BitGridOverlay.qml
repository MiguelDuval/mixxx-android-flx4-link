import "." as Skin
import Mixxx 1.0 as Mixxx
import QtQuick 2.12
import "Theme"

Item {
    id: root

    property int activeDeck: 0
    property bool panelOpen: false

    anchors.fill: parent
    z: 100000

    Mixxx.ControlProxy { id: trackLoaded1; group: "[Channel1]"; key: "track_loaded" }
    Mixxx.ControlProxy { id: trackLoaded2; group: "[Channel2]"; key: "track_loaded" }
    Mixxx.ControlProxy { id: bpm1; group: "[Channel1]"; key: "bpm" }
    Mixxx.ControlProxy { id: bpm2; group: "[Channel2]"; key: "bpm" }
    Mixxx.ControlProxy { id: phase1; group: "[Channel1]"; key: "beat_distance" }
    Mixxx.ControlProxy { id: phase2; group: "[Channel2]"; key: "beat_distance" }
    Mixxx.ControlProxy { id: lock1; group: "[Channel1]"; key: "bpmlock" }
    Mixxx.ControlProxy { id: lock2; group: "[Channel2]"; key: "bpmlock" }
    Mixxx.ControlProxy { id: undoPossible1; group: "[Channel1]"; key: "beats_undo_possible" }
    Mixxx.ControlProxy { id: undoPossible2; group: "[Channel2]"; key: "beats_undo_possible" }

    // Native Mixxx BeatGrid actions. QML is only the UI layer.
    Mixxx.ControlProxy { id: faster1; group: "[Channel1]"; key: "beats_adjust_faster" }
    Mixxx.ControlProxy { id: slower1; group: "[Channel1]"; key: "beats_adjust_slower" }
    Mixxx.ControlProxy { id: earlier1; group: "[Channel1]"; key: "beats_translate_earlier" }
    Mixxx.ControlProxy { id: later1; group: "[Channel1]"; key: "beats_translate_later" }
    Mixxx.ControlProxy { id: half1; group: "[Channel1]"; key: "beats_translate_half" }
    Mixxx.ControlProxy { id: align1; group: "[Channel1]"; key: "beats_translate_curpos" }
    Mixxx.ControlProxy { id: match1; group: "[Channel1]"; key: "beats_translate_match_alignment" }
    Mixxx.ControlProxy { id: undo1; group: "[Channel1]"; key: "beats_undo_adjustment" }
    Mixxx.ControlProxy { id: tap1; group: "[Channel1]"; key: "bpm_tap" }
    Mixxx.ControlProxy { id: halve1; group: "[Channel1]"; key: "beats_set_halve" }
    Mixxx.ControlProxy { id: twoThirds1; group: "[Channel1]"; key: "beats_set_twothirds" }
    Mixxx.ControlProxy { id: threeFourths1; group: "[Channel1]"; key: "beats_set_threefourths" }
    Mixxx.ControlProxy { id: fourFifths1; group: "[Channel1]"; key: "beats_set_fourfifths" }
    Mixxx.ControlProxy { id: fiveFourths1; group: "[Channel1]"; key: "beats_set_fivefourths" }
    Mixxx.ControlProxy { id: fourThirds1; group: "[Channel1]"; key: "beats_set_fourthirds" }
    Mixxx.ControlProxy { id: threeHalves1; group: "[Channel1]"; key: "beats_set_threehalves" }
    Mixxx.ControlProxy { id: double1; group: "[Channel1]"; key: "beats_set_double" }

    Mixxx.ControlProxy { id: faster2; group: "[Channel2]"; key: "beats_adjust_faster" }
    Mixxx.ControlProxy { id: slower2; group: "[Channel2]"; key: "beats_adjust_slower" }
    Mixxx.ControlProxy { id: earlier2; group: "[Channel2]"; key: "beats_translate_earlier" }
    Mixxx.ControlProxy { id: later2; group: "[Channel2]"; key: "beats_translate_later" }
    Mixxx.ControlProxy { id: half2; group: "[Channel2]"; key: "beats_translate_half" }
    Mixxx.ControlProxy { id: align2; group: "[Channel2]"; key: "beats_translate_curpos" }
    Mixxx.ControlProxy { id: match2; group: "[Channel2]"; key: "beats_translate_match_alignment" }
    Mixxx.ControlProxy { id: undo2; group: "[Channel2]"; key: "beats_undo_adjustment" }
    Mixxx.ControlProxy { id: tap2; group: "[Channel2]"; key: "bpm_tap" }
    Mixxx.ControlProxy { id: halve2; group: "[Channel2]"; key: "beats_set_halve" }
    Mixxx.ControlProxy { id: twoThirds2; group: "[Channel2]"; key: "beats_set_twothirds" }
    Mixxx.ControlProxy { id: threeFourths2; group: "[Channel2]"; key: "beats_set_threefourths" }
    Mixxx.ControlProxy { id: fourFifths2; group: "[Channel2]"; key: "beats_set_fourfifths" }
    Mixxx.ControlProxy { id: fiveFourths2; group: "[Channel2]"; key: "beats_set_fivefourths" }
    Mixxx.ControlProxy { id: fourThirds2; group: "[Channel2]"; key: "beats_set_fourthirds" }
    Mixxx.ControlProxy { id: threeHalves2; group: "[Channel2]"; key: "beats_set_threehalves" }
    Mixxx.ControlProxy { id: double2; group: "[Channel2]"; key: "beats_set_double" }

    property var deck: activeDeck === 1 ? {
        loaded: trackLoaded1.value > 0,
        bpm: bpm1, phase: phase1, lock: lock1, undoPossible: undoPossible1,
        faster: faster1, slower: slower1, earlier: earlier1, later: later1,
        half: half1, align: align1, match: match1, undo: undo1, tap: tap1,
        halve: halve1, twoThirds: twoThirds1, threeFourths: threeFourths1,
        fourFifths: fourFifths1, fiveFourths: fiveFourths1, fourThirds: fourThirds1,
        threeHalves: threeHalves1, doubleBpm: double1
    } : {
        loaded: trackLoaded2.value > 0,
        bpm: bpm2, phase: phase2, lock: lock2, undoPossible: undoPossible2,
        faster: faster2, slower: slower2, earlier: earlier2, later: later2,
        half: half2, align: align2, match: match2, undo: undo2, tap: tap2,
        halve: halve2, twoThirds: twoThirds2, threeFourths: threeFourths2,
        fourFifths: fourFifths2, fiveFourths: fiveFourths2, fourThirds: fourThirds2,
        threeHalves: threeHalves2, doubleBpm: double2
    }

    property bool controlsInitialized: deck.bpm.initialized && deck.phase.initialized && deck.lock.initialized
    property bool canEdit: controlsInitialized && deck.loaded && deck.lock.value < 0.5

    function phaseText(proxy) {
        if (!proxy.initialized) return "—";
        var v = proxy.value * 100.0;
        return (v >= 0 ? "+" : "") + v.toFixed(1) + "%";
    }

    function bpmText(proxy) {
        if (!proxy.initialized || !deck.loaded) return "—";
        return Number(proxy.value).toFixed(2);
    }

    function open(deckNumber) {
        activeDeck = deckNumber;
        panelOpen = true;
    }

    function close() {
        panelOpen = false;
    }

    Row {
        id: entryBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 270
        anchors.topMargin: 4
        spacing: 4
        z: 3

        Skin.Button {
            width: 108; height: 44; text: "BITGRID 1"
            highlight: root.panelOpen && root.activeDeck === 1
            onClicked: root.open(1)
        }
        Skin.Button {
            width: 108; height: 44; text: "BITGRID 2"
            highlight: root.panelOpen && root.activeDeck === 2
            onClicked: root.open(2)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        visible: root.panelOpen
        z: 1
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
        id: panel
        width: Math.min(root.width - 32, 500)
        height: Math.min(root.height - 96, 620)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 58
        radius: 8
        color: Theme.backgroundColor
        border.color: Theme.darkGray3
        border.width: 1
        visible: root.panelOpen
        z: 2
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Row {
                width: parent.width; height: 40; spacing: 8
                Text {
                    width: parent.width - 56; height: parent.height
                    color: Theme.lightGray1
                    font.bold: true; font.family: Theme.fontFamily; font.pixelSize: 18
                    verticalAlignment: Text.AlignVCenter
                    text: "BEATGRID " + root.activeDeck
                }
                Skin.Button { width: 48; height: 36; text: "×"; onClicked: root.close() }
            }

            Rectangle {
                width: parent.width; height: 54; radius: 5; color: Theme.darkGray3
                Row {
                    anchors.fill: parent; anchors.margins: 8; spacing: 8
                    Column {
                        width: parent.width / 2 - 8; spacing: 2
                        Text { color: Theme.lightGray3; font.family: Theme.fontFamily; font.pixelSize: 11; text: "BPM" }
                        Text { color: Theme.lightGray1; font.bold: true; font.family: Theme.fontFamily; font.pixelSize: 20; text: root.bpmText(root.deck.bpm) }
                    }
                    Column {
                        width: parent.width / 2 - 8; spacing: 2
                        Text { color: Theme.lightGray3; font.family: Theme.fontFamily; font.pixelSize: 11; text: "PHASE" }
                        Text { color: Theme.lightGray1; font.bold: true; font.family: Theme.fontFamily; font.pixelSize: 20; text: root.phaseText(root.deck.phase) }
                    }
                }
            }

            Row {
                width: parent.width; height: 42; spacing: 6
                Skin.Button { width: (parent.width - 12) / 3; height: 42; text: "BPM −"; enabled: root.canEdit; autoRepeat: true; onClicked: root.deck.slower.trigger() }
                Skin.Button { width: (parent.width - 12) / 3; height: 42; text: "BPM +"; enabled: root.canEdit; autoRepeat: true; onClicked: root.deck.faster.trigger() }
                Skin.Button { width: (parent.width - 12) / 3; height: 42; text: "TAP BPM"; enabled: root.canEdit; onClicked: root.deck.tap.trigger() }
            }

            Text { color: Theme.lightGray3; font.bold: true; font.family: Theme.fontFamily; font.pixelSize: 12; text: "GRID PHASE" }

            Row {
                width: parent.width; height: 42; spacing: 6
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "EARLIER"; enabled: root.canEdit; autoRepeat: true; onClicked: root.deck.earlier.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "LATER"; enabled: root.canEdit; autoRepeat: true; onClicked: root.deck.later.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "½ BEAT"; enabled: root.canEdit; onClicked: root.deck.half.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "ALIGN"; enabled: root.canEdit; highlight: true; onClicked: root.deck.align.trigger() }
            }

            Row {
                width: parent.width; height: 42; spacing: 6
                Skin.Button { width: (parent.width - 6) / 2; height: 42; text: "MATCH DECK"; enabled: root.canEdit; onClicked: root.deck.match.trigger() }
                Skin.Button { width: (parent.width - 6) / 2; height: 42; text: "UNDO"; enabled: root.controlsInitialized && root.deck.undoPossible.value > 0; onClicked: root.deck.undo.trigger() }
            }

            Text { color: Theme.lightGray3; font.bold: true; font.family: Theme.fontFamily; font.pixelSize: 12; text: "BPM INTERPRETATION" }

            Flow {
                width: parent.width; height: 92; spacing: 6
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "½×"; enabled: root.canEdit; onClicked: root.deck.halve.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "⅔×"; enabled: root.canEdit; onClicked: root.deck.twoThirds.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "¾×"; enabled: root.canEdit; onClicked: root.deck.threeFourths.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "⅘×"; enabled: root.canEdit; onClicked: root.deck.fourFifths.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "5/4×"; enabled: root.canEdit; onClicked: root.deck.fiveFourths.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "4/3×"; enabled: root.canEdit; onClicked: root.deck.fourThirds.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "3/2×"; enabled: root.canEdit; onClicked: root.deck.threeHalves.trigger() }
                Skin.Button { width: (parent.width - 18) / 4; height: 42; text: "2×"; enabled: root.canEdit; onClicked: root.deck.doubleBpm.trigger() }
            }

            Row {
                width: parent.width; height: 42; spacing: 6
                Skin.Button {
                    width: (parent.width - 6) / 2; height: 42
                    text: root.deck.lock.value > 0.5 ? "UNLOCK GRID" : "LOCK GRID"
                    highlight: root.deck.lock.value > 0.5
                    enabled: root.controlsInitialized
                    onClicked: root.deck.lock.trigger()
                }
                Text {
                    width: (parent.width - 6) / 2; height: 42
                    color: root.canEdit ? Theme.lightGray3 : Theme.lightGray4
                    font.family: Theme.fontFamily; font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    text: !root.deck.loaded ? "No track loaded" :
                          root.deck.lock.value > 0.5 ? "BeatGrid locked" :
                          root.controlsInitialized ? "Ready" : "Engine unavailable"
                }
            }
        }
    }
}
