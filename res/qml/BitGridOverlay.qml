import Mixxx 1.0 as Mixxx
import QtQuick 2.12

Item {
    id: root

    width: 220
    height: 44

    Mixxx.ControlProxy {
        id: bitgrid1Action
        group: "[Channel1]"
        key: "beats_translate_curpos"
    }

    Mixxx.ControlProxy {
        id: bitgrid2Action
        group: "[Channel2]"
        key: "beats_translate_curpos"
    }

    Mixxx.ControlProxy {
        id: bitgrid1Phase
        group: "[Channel1]"
        key: "beat_distance"
    }

    Mixxx.ControlProxy {
        id: bitgrid2Phase
        group: "[Channel2]"
        key: "beat_distance"
    }

    function phaseText(proxy) {
        if (!proxy.initialized) {
            return "OFFLINE";
        }
        return (Math.abs(proxy.value) * 100).toFixed(1) + "% phase";
    }

    Row {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Rectangle {
            color: bitgrid1MouseArea.pressed ? "#00a8cc" : "#3a3a3a"
            height: parent.height - 8
            radius: 3
            width: 102

            Column {
                anchors.centerIn: parent
                spacing: 1

                Text {
                    color: "white"
                    font.bold: true
                    font.family: "Open Sans"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    text: "BITGRID 1"
                    width: 102
                }
                Text {
                    color: "#b8eaff"
                    font.family: "Open Sans"
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    text: root.phaseText(bitgrid1Phase)
                    width: 102
                }
            }

            MouseArea {
                id: bitgrid1MouseArea
                anchors.fill: parent
                onClicked: {
                    console.log("[BitGrid] BITGRID 1 clicked; initialized=" + bitgrid1Action.initialized + ", phase=" + bitgrid1Phase.value);
                    if (bitgrid1Action.initialized) {
                        bitgrid1Action.trigger();
                    } else {
                        console.warn("[BitGrid] BITGRID 1 action is not initialized");
                    }
                }
            }
        }

        Rectangle {
            color: bitgrid2MouseArea.pressed ? "#00a8cc" : "#3a3a3a"
            height: parent.height - 8
            radius: 3
            width: 102

            Column {
                anchors.centerIn: parent
                spacing: 1

                Text {
                    color: "white"
                    font.bold: true
                    font.family: "Open Sans"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    text: "BITGRID 2"
                    width: 102
                }
                Text {
                    color: "#b8eaff"
                    font.family: "Open Sans"
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    text: root.phaseText(bitgrid2Phase)
                    width: 102
                }
            }

            MouseArea {
                id: bitgrid2MouseArea
                anchors.fill: parent
                onClicked: {
                    console.log("[BitGrid] BITGRID 2 clicked; initialized=" + bitgrid2Action.initialized + ", phase=" + bitgrid2Phase.value);
                    if (bitgrid2Action.initialized) {
                        bitgrid2Action.trigger();
                    } else {
                        console.warn("[BitGrid] BITGRID 2 action is not initialized");
                    }
                }
            }
        }
    }
}