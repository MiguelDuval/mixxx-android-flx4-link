import "." as Skin
import Mixxx 1.0 as Mixxx
import QtQuick
import QtQuick.Layouts
import "Effects" as Effects
import "Theme"

Item {
    id: root

    readonly property string deck1Unit: "[EffectRack1_EffectUnit2]"
    readonly property string deck2Unit: "[EffectRack1_EffectUnit3]"
    implicitHeight: 236

    Rectangle {
        anchors.fill: parent
        color: Theme.toolbarBackgroundColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: Theme.darkGray
                radius: 5
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    height: 28
                    spacing: 6

                    Text {
                        color: Theme.white
                        font.bold: true
                        font.pixelSize: 13
                        text: "PAD FX • DECK 1"
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Skin.ControlKnob {
                        Layout.alignment: Qt.AlignVCenter
                        arcStart: Skin.Knob.ArcStart.Minimum
                        color: Theme.effectUnitColor
                        group: root.deck1Unit
                        height: 30
                        key: "mix"
                        width: 30
                    }

                    Skin.ControlButton {
                        activeColor: Theme.effectUnitColor
                        group: root.deck1Unit
                        height: 26
                        key: "enabled"
                        text: "ON"
                        toggleable: true
                        width: 42
                    }
                }

                Effects.EffectSlot {
                    Layout.fillWidth: true
                    effectNumber: 1
                    expanded: false
                    height: 50
                    unitNumber: 2
                }
                Effects.EffectSlot {
                    Layout.fillWidth: true
                    effectNumber: 2
                    expanded: false
                    height: 50
                    unitNumber: 2
                }
                Effects.EffectSlot {
                    Layout.fillWidth: true
                    effectNumber: 3
                    expanded: false
                    height: 50
                    unitNumber: 2
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: Theme.darkGray
                radius: 5
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    height: 28
                    spacing: 6

                    Text {
                        color: Theme.white
                        font.bold: true
                        font.pixelSize: 13
                        text: "PAD FX • DECK 2"
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Skin.ControlKnob {
                        Layout.alignment: Qt.AlignVCenter
                        arcStart: Skin.Knob.ArcStart.Minimum
                        color: Theme.effectUnitColor
                        group: root.deck2Unit
                        height: 30
                        key: "mix"
                        width: 30
                    }

                    Skin.ControlButton {
                        activeColor: Theme.effectUnitColor
                        group: root.deck2Unit
                        height: 26
                        key: "enabled"
                        text: "ON"
                        toggleable: true
                        width: 42
                    }
                }

                Effects.EffectSlot {
                    Layout.fillWidth: true
                    effectNumber: 1
                    expanded: false
                    height: 50
                    unitNumber: 3
                }
                Effects.EffectSlot {
                    Layout.fillWidth: true
                    effectNumber: 2
                    expanded: false
                    height: 50
                    unitNumber: 3
                }
                Effects.EffectSlot {
                    Layout.fillWidth: true
                    effectNumber: 3
                    expanded: false
                    height: 50
                    unitNumber: 3
                }
            }
        }
    }
}