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
    property bool showBeatgridControlsLocal: false
    readonly property bool showBeatgridControls: showBeatgridControlsLocal
    readonly property int beatgridControlsWidth: timingShiftButtonsProxy.value > 0 ? 130 : 104

    signal toggleFocus

    color: LateNightTheme.deckPanelColor

    Mixxx.ControlProxy {
        id: selectBigSpinnyProxy
        group: "[Skin]"
        key: "select_big_spinny_or_cover"
    }

    Mixxx.ControlProxy {
        id: showKeyControlsProxy
        group: "[Skin]"
        key: "show_key_controls"
    }

    Mixxx.ControlProxy {
        id: showVinylControlsProxy
        group: "[Skin]"
        key: "show_vinylcontrol"
    }

    Mixxx.ControlProxy {
        id: show4EffectUnitsProxy
        group: "[Skin]"
        key: "show_4effectunits"
    }

    Mixxx.ControlProxy {
        id: showHotcuesProxy
        group: "[Skin]"
        key: "show_hotcues"
    }

    Mixxx.ControlProxy {
        id: show8HotcuesProxy
        group: "[Skin]"
        key: "show_8_hotcues"
    }

    Mixxx.ControlProxy {
        id: showIntroOutroCuesProxy
        group: "[Skin]"
        key: "show_intro_outro_cues"
    }

    Mixxx.ControlProxy {
        id: showLoopControlsProxy
        group: "[Skin]"
        key: "show_loop_controls"
    }

    Mixxx.ControlProxy {
        id: showBeatjumpControlsProxy
        group: "[Skin]"
        key: "show_beatjump_controls"
    }

    Mixxx.ControlProxy {
        id: showRateControlsProxy
        group: "[Skin]"
        key: "show_rate_controls"
    }

    Mixxx.ControlProxy {
        id: showRateControlButtonsProxy
        group: "[Skin]"
        key: "show_rate_control_buttons"
    }

    Mixxx.ControlProxy {
        id: timingShiftButtonsProxy
        group: "[Skin]"
        key: "timing_shift_buttons"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 1
        anchors.topMargin: 2
        anchors.rightMargin: 1
        anchors.bottomMargin: 2
        spacing: 2

        // Central main deck column
        ColumnLayout {
            id: mainDeckColumn
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            spacing: 1

            // Top row: FX assignment, BeatGrid, and key controls.
            RowLayout {
                id: topPlaceholderRow
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Layout.minimumHeight: 20
                Layout.maximumHeight: 20
                Layout.fillHeight: false
                visible: !root.minimized
                spacing: 1

                // FX assignment buttons: toggle effect unit assignment for this deck
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

                            Mixxx.ControlProxy {
                                id: fxAssignProxy
                                group: `[EffectRack1_EffectUnit${index + 1}]`
                                key: `group_${root.group}_enable`
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: fxAssignButton.fillColor
                            }

                            Image {
                                anchors.fill: parent
                                source: {
                                    if (index === 0) {
                                        return fxAssignButton.active
                                            ? LateNightTheme.lateNightButton("btn_embedded_library_active.svg")
                                            : LateNightTheme.lateNightButton("btn_embedded_library.svg");
                                    } else {
                                        return fxAssignButton.active
                                            ? LateNightTheme.lateNightButton("btn_embedded_grid_active.svg")
                                            : LateNightTheme.lateNightButton("btn_embedded_grid.svg");
                                    }
                                }
                                fillMode: Image.Stretch
                            }

                            Text {
                                anchors.centerIn: parent
                                text: show4EffectUnitsProxy.value > 0 && index > 0 ? (index + 1).toString() : "FX" + (show4EffectUnitsProxy.value > 0 && index === 0 ? "1" : (index + 1).toString())
                                font.family: "Open Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: fxAssignButton.active ? (LateNightTheme.isClassic ? "#000000" : LateNightTheme.mixerControlTextColor) : (LateNightTheme.isClassic ? "#d2d2d1" : "#666666")
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    fxAssignProxy.value = !fxAssignProxy.value;
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: LateNightTheme.deckPanelBorderDark
                    }
                }

                Item {
                    id: beatgridToggle
                    Layout.preferredWidth: 58
                    Layout.minimumWidth: 58
                    Layout.maximumWidth: 58
                    Layout.preferredHeight: 20
                    Layout.minimumHeight: 20
                    Layout.maximumHeight: 20
                    Layout.alignment: Qt.AlignVCenter
                    z: 20

                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        color: root.showBeatgridControls
                                ? LateNightTheme.deckDimButtonInactiveColor
                                : LateNightTheme.deckTopRowBackgroundColor
                        border.width: 1
                        border.color: LateNightTheme.deckPanelBorderLight
                    }

                    Text {
                        anchors.fill: parent
                        text: "BEATGRID"
                        color: root.showBeatgridControls
                                ? LateNightTheme.primaryDeckTextColor
                                : LateNightTheme.secondaryDeckTextColor
                        font.family: "Open Sans"
                        font.pixelSize: 9
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: {
                            root.showBeatgridControlsLocal = !root.showBeatgridControlsLocal;
                        }
                    }
                }

                VinylControlsPlaceholder {
                    Layout.preferredWidth: 158
                    Layout.preferredHeight: 20
                    Layout.maximumHeight: 20
                    group: root.group
                    visible: root.showVinylControls
                }

                Item {
                    Layout.preferredWidth: root.showVinylControls ? 2 : 0
                    Layout.fillHeight: true
                    visible: root.showVinylControls
                }

                KeyControlsPlaceholder {
                    Layout.preferredWidth: 111
                    Layout.maximumWidth: 111
                    Layout.preferredHeight: 20
                    Layout.maximumHeight: 20
                    group: root.group
                    visible: root.showKeyControls
                }
            }

            // Middle Row: Big Spinny on the left, Title/Overview on the right
            RowLayout {
                id: middleDeckRow
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.minimumHeight: root.minimized ? 68 : 122
                Layout.preferredHeight: root.minimized ? 68 : 122
                Layout.maximumHeight: root.minimized ? 68 : 122
                spacing: 8

                SpinnyCoverSlot {
                    id: leftSpinnyBig
                    Layout.preferredHeight: 114
                    Layout.preferredWidth: 114
                    group: root.group
                    visible: root.showBigSpinnyOrCover && !root.minimized
                }

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

                        TapHandler {
                            onDoubleTapped: root.toggleFocus()
                        }
                    }

                    RowLayout {
                        id: overviewAndSpinnyRow
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.minimumHeight: root.minimized ? 20 : 63
                        Layout.preferredHeight: root.minimized ? 20 : 63
                        Layout.maximumHeight: root.minimized ? 20 : 63
                        spacing: 1

                        // Put the real BeatGrid editor first so it receives a guaranteed
                        // layout allocation on narrow Android screens instead of being
                        // pushed off the right edge by OverviewRow.
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

                        SpinnyCoverSlot {
                            id: leftSpinnySmall
                            Layout.preferredHeight: 63
                            Layout.preferredWidth: 63
                            group: root.group
                            visible: root.showSmallSpinnyOrCover
                        }

                        OverviewRow {
                            id: overviewRow
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            group: root.group
                        }
                    }
                }
            }

            TransportLoopBeatjumpPlaceholders {
                id: transportRow
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.minimumHeight: 55
                Layout.preferredHeight: 55
                Layout.maximumHeight: 55
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
            Layout.preferredWidth: 90
            Layout.fillHeight: false
            Layout.minimumHeight: 202
            Layout.preferredHeight: 202
            Layout.maximumHeight: 202
            Layout.alignment: Qt.AlignTop
            group: root.group
            showRateControlButtons: root.showRateControlButtons
            visible: !root.minimized && root.showRateControls
        }
    }

    Mixxx.PlayerDropArea {
        anchors.fill: parent
        group: root.group
    }
}
