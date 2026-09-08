import ".." as Skin
import Mixxx 1.0 as Mixxx
import Qt5Compat.GraphicalEffects
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts
import QtQuick.Shapes
import "../Theme"

ColumnLayout {
    required property var currentTrack
    required property string group

    Mixxx.ControlProxy {
        id: keylockCO
        group: root.group
        key: "keylock"
    }
    Mixxx.ControlProxy {
        id: keyCO
        group: root.group
        key: "key"
    }
    Mixxx.ControlProxy {
        id: keyNotationCO
        group: "[Library]"
        key: "key_notation"
    }
    Mixxx.ControlProxy {
        id: bpmCO
        group: root.group
        key: "bpm"
    }
    Text {
        Layout.fillWidth: true
        Layout.preferredHeight: 26
        color: Theme.white
        font.bold: true
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        text: {
            if (!trackLoadedControl.value || bpmCO.value <= 0)
                return "-";
            return (Math.round(bpmCO.value * 100) / 100).toFixed(2);
        }
        verticalAlignment: Text.AlignVCenter
    }
    RowLayout {
        Layout.fillWidth: true
        height: 26
        Skin.ControlButton {
            id: pitchDownButton
            activeColor: Theme.deckActiveColor
            group: root.group
            implicitHeight: 26
            implicitWidth: 20
            key: "pitch_down"
            contentItem: Item {
                anchors.fill: parent
                Shape {
                    anchors.centerIn: parent
                    antialiasing: true
                    height: 10
                    layer.enabled: true
                    layer.samples: 4
                    width: 12
                    ShapePath {
                        fillColor: '#626262'
                        startX: 0
                        startY: 5
                        strokeColor: 'transparent'
                        PathLine { x: 12; y: 0 }
                        PathLine { x: 12; y: 10 }
                        PathLine { x: 0; y: 5 }
                    }
                }
            }
        }
        Skin.Button {
            id: pitchKey
            readonly property variant colorsMap: ["#b960a2", "#9fc516", "#527fc0", "#f28b2e", "#5bc1cf", "#e84c4d", "#73b629", "#8269ab", "#fdd615", "#3cc0f0", "#4cb686", "#4cb686", "#f5a158", "#7bcdd9", "#ed7171", "#8fc555", "#9b86be", "#fcdf45", "#63cdf4", "#f1845f", "#70c4a0", "#c680b6", "#b2d145", "#7499cd"]
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            implicitHeight: 26
            contentItem: Text {
                id: item
                readonly property string displayKeyText: Mixxx.KeyUtils.keyToString(keyCO.value, keyNotationCO.value)
                readonly property int openKeyNumber: Mixxx.KeyUtils.keyToOpenKeyNumber(keyCO.value)
                readonly property bool validKey: trackLoadedControl.value && Mixxx.KeyUtils.keyIsValid(keyCO.value) && displayKeyText.length > 0
                color: {
                    if (!validKey || openKeyNumber < 1 || openKeyNumber > pitchKey.colorsMap.length)
                        return keylockCO.value ? Theme.white : Theme.midGray3;
                    return pitchKey.colorsMap[openKeyNumber - 1];
                }
                font.bold: true
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                text: validKey ? displayKeyText : "-"
                verticalAlignment: Text.AlignVCenter
            }
        }
        Skin.ControlButton {
            id: pitchUpButton
            activeColor: Theme.deckActiveColor
            group: root.group
            implicitHeight: 26
            implicitWidth: 20
            key: "pitch_up"
            contentItem: Item {
                anchors.fill: parent
                Shape {
                    anchors.centerIn: parent
                    antialiasing: true
                    height: 10
                    layer.enabled: true
                    layer.samples: 4
                    width: 12
                    ShapePath {
                        capStyle: ShapePath.RoundCap
                        fillColor: '#626262'
                        fillRule: ShapePath.WindingFill
                        startX: 0
                        startY: 0
                        strokeColor: 'transparent'
                        PathLine { x: 12; y: 5 }
                        PathLine { x: 0; y: 10 }
                        PathLine { x: 0; y: 0 }
                    }
                }
            }
        }
    }
    Skin.ControlFader {
        id: rateSlider
        Layout.fillHeight: true
        Layout.fillWidth: true
        bar.color: Theme.bpmSliderBarColor
        bar.margin: 0
        bar.start: 0.5
        bg: Theme.imgBpmSliderBackground
        group: root.group
        key: "rate"
        visible: !root.minimized
        width: pitchKey.implicitWidth
        Skin.FadeBehavior on visible { fadeTarget: rateSlider }
    }
    Skin.SyncButton {
        id: syncButton
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        group: root.group
        height: 22
    }
    Skin.RangeButton {
        id: rangeButton
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        group: root.group
        height: 22
    }
}