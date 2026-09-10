import QtQuick
import QtQuick.Layouts
import Mixxx 1.0 as Mixxx
import "../Controls" as Controls
import "../LateNightTheme"
import "../Waveforms"

Controls.Panel {
    id: root

    implicitHeight: root.minimized ? 80 : 206
    implicitWidth: 620

    required property string group
    property bool minimized: false
    property bool editMode: false
    readonly property bool showBeatjumpControls: showBeatjumpControlsProxy.value > 0
    readonly property bool showBigSpinnyOrCover: selectBigSpinnyProxy.value > 0
    readonly property bool showHotcues: showHotcuesProxy.value > 0
    readonly property bool show8Hotcues: show8HotcuesProxy.value > 0
    readonly property bool showIntroOutroCues: showIntroOutroCuesProxy.value > 0
    readonly property bool showKeyControls: showKeyControlsProxy.value > 0
    readonly property bool showLoopControls: showLoopControlsProxy.value > 0
    readonly property bool showRateControlButtons: showRateControlButtonsProxy.value > 0
    readonly property bool showRateControls: showRateControlsProxy.value > 0
    readonly property bool showSmallSpinnyOrCover: selectBigSpinnyProxy.value <= 0 && !root.minimized
    readonly property bool showVinylControls: showVinylControlsProxy.value > 0

    // BeatGrid visibility is local to this deck. Do not synchronize it through [Skin].
    // Start visible so the actual editor is independently testable before adding UI toggles.
    property bool showBeatgridControlsLocal: true
    readonly property bool showBeatgridControls: showBeatgridControlsLocal
    readonly property int beatgridControlsWidth: timingShiftButtonsProxy.value > 0 ? 130 : 104

    signal toggleFocus

    color: LateNightTheme.deckPanelColor

    Mixxx.ControlProxy { id: selectBigSpinnyProxy; group: "[Skin]"; key: "select_big_spinny_or_cover" }
    Mixxx.ControlProxy { id: showKeyControlsProxy; group: "[Skin]"; key: "show_key_controls" }
    Mixxx.ControlProxy { id: showVinylControlsProxy; group: "[Skin]"; key: "show_vinylcontrol" }
    Mixxx.ControlProxy { id: show4EffectUnitsProxy; group: "[Skin]"; key: "show_4effectunits" }
    Mixxx.ControlProxy { id: showHotcuesProxy; group: "[Skin]"; key: "show_hotcues" }
    Mixxx.ControlProxy { id: show8HotcuesProxy; group: "[Skin]"; key: "show_8_hotcues" }
    Mixxx.ControlProxy { id: showIntroOutroCuesProxy; group: "[Skin]"; key: "show_intro_outro_cues" }
    Mixxx.ControlProxy { id: showLoopControlsProxy; group: "[Skin]"; key: "show_loop_controls" }
    Mixxx.ControlProxy { id: showBeatjumpControlsProxy; group: "[Skin]"; key: "show_beatjump_controls" }
    Mixxx.ControlProxy { id: showRateControlsProxy; group: "[Skin]"; key: "show_rate_controls" }
    Mixxx.ControlProxy { id: showRateControlButtonsProxy; group: "[Skin]"; key: "show_rate_control_buttons" }
    Mixxx.ControlProxy { id: timingShiftButtonsProxy; group: "[Skin]"; key: "timing_shift_buttons" }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 1
        anchors.topMargin: 2
        anchors.rightMargin: 1
        anchors.bottomMargin: 2
        spacing: 2

        ColumnLayout {
            id: mainDeckColumn
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            spacing: 1

            RowLayout {
                id: topPlaceholderRow
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Layout.minimumHeight: 20
                Layout.maximumHeight: 20
                Layout.fillHeight: false
                visible: !root.minimized
                spacing: 1

                Row {
                    spacing: 0
                    Repeater {
                        model: show4EffectUnitsProxy.value > 0 ? 4 : 2
                        delegate: Item {
                            id: fxAssignButton
                            required property int index
                            width: show4EffectUnitsProxy.value > 0 && index > 0 ? 20 : 26
                            height: 20
                            readonly property bool active: fxAssignProxy.value > 0
                            readonly property color activeColor: index < 2 ? (LateNightTheme.isClassic ? LateNightTheme.effectsUnitColor12 : LateNightTheme.effectsUnitDimColor12) : (LateNightTheme.isClassic ? LateNightTheme.effectsUnitColor34 : LateNightTheme.effectsUnitDimColor34)
                            readonly property color inactiveColor: LateNightTheme.deckEmbeddedButtonInactiveColor
                            readonly property color fillColor: active ? activeColor : inactiveColor
                            Mixxx.ControlProxy { id: fxAssignProxy; group: `[EffectRack1_EffectUnit${index + 1}]`; key: `group_${root.group}_enable` }
                            Rectangle { anchors.fill: parent; color: fxAssignButton.fillColor }
                            Image {
                                anchors.fill: parent
                                source: index === 0
                                    ? (fxAssignButton.active ? LateNightTheme.lateNightButton("btn_embedded_library_active.svg") : LateNightTheme.lateNightButton("btn_embedded_library.svg"))
                                    : (fxAssignButton.active ? LateNightTheme.lateNightButton("btn_embedded_grid_active.svg") : LateNightTheme.lateNightButton("btn_embedded_grid.svg"))
                                fillMode: Image.Stretch
                            }
                            Text {
                                anchors.centerIn: parent
                                text: show4EffectUnitsProxy.value > 0 && index > 0 ? (index + 1).toString() : "FX" + (show4EffectUnitsProxy.value > 0 && index === 0 ? "1" : (index + 1).toString())
                                font.family: "Open Sans"; font.pixelSize: 10; font.bold: true
                                color: fxAssignButton.active ? (LateNightTheme.isClassic ? "#000000" : LateNightTheme.mixerControlTextColor) : (LateNightTheme.isClassic ? "#d2d2d1" : "#666666")
                            }
                            MouseArea { anchors.fill: parent; onClicked: fxAssignProxy.value = !fxAssignProxy.value }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: LateNightTheme.deckPanelBorderDark }
                }

                Item {
                    id: beatgridToggle
                    Layout.preferredWidth: 58; Layout.minimumWidth: 58; Layout.maximumWidth: 58
                    Layout.preferredHeight: 20; Layout.minimumHeight: 20; Layout.maximumHeight: 20
                    Layout.alignment: Qt.AlignVCenter; z: 20
                    Rectangle {
                        anchors.fill: parent; radius: 2
                        color: root.showBeatgridControls ? LateNightTheme.deckDimButtonInactiveColor : LateNightTheme.deckTopRowBackgroundColor
                        border.width: 1; border.color: LateNightTheme.deckPanelBorderLight
                    }
                    Text {
                        anchors.fill: parent; text: "BEATGRID"
                        color: root.showBeatgridControls ? LateNightTheme.primaryDeckTextColor : LateNightTheme.secondaryDeckTextColor
                        font.family: "Open Sans"; font.pixelSize: 9; font.bold: true
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: root.showBeatgridControlsLocal = !root.showBeatgridControlsLocal }
                }

                VinylControlsPlaceholder { Layout.preferredWidth: 158; Layout.preferredHeight: 20; Layout.maximumHeight: 20; group: root.group; visible: root.showVinylControls }
                Item { Layout.preferredWidth: root.showVinylControls ? 2 : 0; Layout.fillHeight: true; visible: root.showVinylControls }
                KeyControlsPlaceholder { Layout.preferredWidth: 111; Layout.maximumWidth: 111; Layout.preferredHeight: 20; Layout.maximumHeight: 20; group: root.group; visible: root.showKeyControls }
            }

            RowLayout {
                id: middleDeckRow
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.minimumHeight: root.minimized ? 68 : 122
                Layout.preferredHeight: root.minimized ? 68 : 122
                Layout.maximumHeight: root.minimized ? 68 : 122
                spacing: 8

                SpinnyCoverSlot { id: leftSpinnyBig; Layout.preferredHeight: 114; Layout.preferredWidth: 114; group: root.group; visible: root.showBigSpinnyOrCover && !root.minimized }

                ColumnLayout {
                    id: titleOverviewColumn
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: root.minimized ? 68 : 122
                    spacing: 2

                    TitleTimeRows {
                        id: titleTimeRows
                        Layout.fillWidth: true
                        Layout.minimumHeight: root.minimized ? 48 : 55
                        Layout.preferredHeight: root.minimized ? 48 : 55
                        Layout.maximumHeight: root.minimized ? 48 : 55
                        group: root.group
                        TapHandler { onDoubleTapped: root.toggleFocus() }
                    }

                    RowLayout {
                        id: overviewAndSpinnyRow
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.minimumHeight: root.minimized ? 20 : 63
                        Layout.preferredHeight: root.minimized ? 20 : 63
                        Layout.maximumHeight: root.minimized ? 20 : 63
                        spacing: 1

                        // Explicit unique local component, first in the layout so it cannot be pushed off-screen.
                        DeckBeatgridEditor {
                            id: beatgridControls
                            Layout.preferredWidth: root.showBeatgridControls ? root.beatgridControlsWidth : 0
                            Layout.minimumWidth: root.showBeatgridControls ? root.beatgridControlsWidth : 0
                            Layout.maximumWidth: root.beatgridControlsWidth
                            Layout.preferredHeight: 52
                            Layout.maximumHeight: 52
                            Layout.alignment: Qt.AlignVCenter
                            group: root.group
                            visible: root.showBeatgridControls
                            z: 20
                        }

                        SpinnyCoverSlot { id: leftSpinnySmall; Layout.preferredHeight: 63; Layout.preferredWidth: 63; group: root.group; visible: root.showSmallSpinnyOrCover }
                        OverviewRow { id: overviewRow; Layout.fillWidth: true; Layout.fillHeight: true; group: root.group }
                    }
                }
            }

            TransportLoopBeatjumpPlaceholders {
                id: transportRow
                Layout.fillWidth: true; Layout.fillHeight: false
                Layout.minimumHeight: 55; Layout.preferredHeight: 55; Layout.maximumHeight: 55
                group: root.group
                showHotcues: root.showHotcues
                show8Hotcues: root.show8Hotcues
                showIntroOutroCues: root.showIntroOutroCues
                showLoopControls: root.showLoopControls
                showBeatjumpControls: root.showBeatjumpControls
                visible: !root.minimized
            }
        }

        RatePlaceholder {
            id: rateControls
            Layout.preferredWidth: 90; Layout.fillHeight: false
            Layout.minimumHeight: 202; Layout.preferredHeight: 202; Layout.maximumHeight: 202
            Layout.alignment: Qt.AlignTop
            group: root.group
            showRateControlButtons: root.showRateControlButtons
            visible: !root.minimized && root.showRateControls
        }
    }

    Mixxx.PlayerDropArea { anchors.fill: parent; group: root.group }

    // ================================================================
    // PHASE 1: DIAGNOSTIC OVERLAY
    // Independent of any BeatGrid layout, clipping, or skin state.
    // ================================================================
    Item {
        id: beatgridDiagnosticOverlay
        anchors.fill: parent
        clip: false
        z: 10000

        property string buildMarker: "BG-DIAG " + Qt.formatDateTime(new Date(), "yyyy-MM-dd-HH-mm-ss")

        // Build marker text
        Text {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 10
            text: beatgridDiagnosticOverlay.buildMarker
            color: "#FF00FF"
            font.bold: true
            font.pixelSize: 12
            z: 10002
        }
    }

    // ================================================================
    // CHANNEL 1 DIAGNOSTIC BLOCK
    // ================================================================
    Item {
        id: diagChannel1
        width: 140
        height: 48
        x: 6
        y: 6
        z: 10001

        Rectangle {
            anchors.fill: parent
            color: "#FF0000"
            border.color: "#FFFFFF"
            border.width: 3
            radius: 4
        }

        Text {
            anchors.centerIn: parent
            text: "CHANNEL1\nBITGRID 1 TEST"
            color: "#FFFFFF"
            font.bold: true
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        Text {
            anchors.top: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: beatgridDiagnosticOverlay.buildMarker
            color: "#FFFF00"
            font.bold: true
            font.pixelSize: 9
        }
    }

    // ================================================================
    // CHANNEL 2 DIAGNOSTIC BLOCK
    // ================================================================
    Item {
        id: diagChannel2
        width: 140
        height: 48
        x: 6
        y: 60
        z: 10001

        Rectangle {
            anchors.fill: parent
            color: "#0000FF"
            border.color: "#FFFFFF"
            border.width: 3
            radius: 4
        }

        Text {
            anchors.centerIn: parent
            text: "CHANNEL2\nBITGRID 2 TEST"
            color: "#FFFFFF"
            font.bold: true
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        Text {
            anchors.top: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: beatgridDiagnosticOverlay.buildMarker
            color: "#FFFF00"
            font.bold: true
            font.pixelSize: 9
        }
    }

    // ================================================================
    // TOUCH TEST - Independent of Mixxx controls
    // ================================================================
    Item {
        id: touchTestItem
        width: 140
        height: 48
        x: 6
        y: 114
        z: 10001

        property bool touched: false

        Rectangle {
            id: touchRect
            anchors.fill: parent
            color: touched ? "#00FF00" : "#FFFF00"
            border.color: "#000000"
            border.width: 2
            radius: 4
        }

        Text {
            anchors.centerIn: parent
            text: "TOUCH TEST\n" + (touched ? "TOUCHED!" : "PRESS ME")
            color: "#000000"
            font.bold: true
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        MouseArea {
            anchors.fill: parent
            onPressed: { touchTestItem.touched = true }
            onReleased: { touchTestItem.touched = false }
        }
    }

    // ================================================================
    // ALIGN TEST - Uses real Mixxx control path
    // ================================================================
    Item {
        id: alignTestItem
        width: 140
        height: 48
        x: 6
        y: 168
        z: 10001

        LateNightControlButton {
            anchors.fill: parent
            group: root.group
            key: "beats_translate_curpos"
            toggleable: false
            backgroundSource: LateNightTheme.lateNightSubRegionButton("medium")
            iconSource: LateNightTheme.assetDeckBeatCurposLargeButton
            activeBackgroundSuffix: "active"
            pressedBackgroundSuffix: "active"
            activeOpacity: 1.0
            inactiveOpacity: 0.82
            activeColor: LateNightTheme.activePlayCueColor
            inactiveColor: LateNightTheme.deckDimButtonInactiveColor

            // Label to identify it
            Text {
                anchors.bottom: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ALIGN TEST\n(" + root.group + ")"
                color: "#FF00FF"
                font.bold: true
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

}
