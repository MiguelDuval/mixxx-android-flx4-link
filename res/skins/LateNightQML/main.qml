import Mixxx 1.0 as Mixxx
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "LateNightTheme"

ApplicationWindow {
    id: root

    property int displayedProgress: 0

    color: startupScreen.backgroundColor
    height: 1008
    menuBar: mainWindowLoader.item ? mainWindowLoader.item.menuBar : null
    minimumHeight: 668
    minimumWidth: 1280
    visible: true
    width: 1792

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
        id: abletonLinkControl
        group: "[AbletonLink]"
        key: "sync_enabled"
    }

    function updateVisibility() {
        if (!Mixxx.Core.ready) {
            return;
        }
        root.visibility = Mixxx.Config.configStartInFullscreenKey
                ? Window.FullScreen
                : Window.Windowed;
    }

    function updateProgress() {
        if (!Mixxx.Core.ready) {
            displayedProgress = Math.max(displayedProgress,
                                         Mixxx.Core.initializationProgress);
        } else if (mainWindowLoader.status === Loader.Ready) {
            displayedProgress = 100;
        } else {
            displayedProgress = Math.max(displayedProgress,
                                         65 + Math.round(mainWindowLoader.progress * 34));
        }
    }

    function handleMainWindowLoaderStatus() {
        root.updateProgress()
        if (mainWindowLoader.status === Loader.Error) {
            console.error("Failed to load the LateNightQML main window")
            Qt.quit()
        }
    }

    Connections {
        target: Mixxx.Core

        function onInitializationProgressChanged() {
            root.updateProgress();
        }
        function onReadyChanged() {
            root.updateProgress();
            root.updateVisibility();
        }
    }

    Loader {
        id: mainWindowLoader

        anchors.fill: parent
        active: Mixxx.Core.ready
        asynchronous: true

        onProgressChanged: root.updateProgress()
        onStatusChanged: root.handleMainWindowLoaderStatus()

        sourceComponent: Component {
            MainWindow {
                applicationWindow: root
                anchors.fill: parent
            }
        }
    }

    // Dedicated mobile control strip. The Android Link button is a direct
    // third child of this Row so its position is deterministic: BITGRID 1,
    // BITGRID 2, LINK. It does not depend on toolbar layout or ControlProxy
    // initialization just to become visible.
    Rectangle {
        id: bitgridBar

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 27
        color: LateNightTheme.toolbarRootBackgroundColor
        height: 34
        width: 283
        z: 10000

        Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            Rectangle {
                id: bitgrid1Button

                color: bitgrid1MouseArea.pressed ? LateNightTheme.toolbarButtonActiveBackgroundColor : LateNightTheme.toolbarButtonInactiveBackgroundColor
                height: parent.height
                radius: 2
                width: 89

                Text {
                    anchors.fill: parent
                    color: LateNightTheme.toolbarButtonInactiveTextColor
                    font.family: "Open Sans"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "BITGRID 1"
                }

                MouseArea {
                    id: bitgrid1MouseArea
                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    onClicked: bitgrid1Action.trigger()
                }
            }

            Rectangle {
                id: bitgrid2Button

                color: bitgrid2MouseArea.pressed ? LateNightTheme.toolbarButtonActiveBackgroundColor : LateNightTheme.toolbarButtonInactiveBackgroundColor
                height: parent.height
                radius: 2
                width: 89

                Text {
                    anchors.fill: parent
                    color: LateNightTheme.toolbarButtonInactiveTextColor
                    font.family: "Open Sans"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "BITGRID 2"
                }

                MouseArea {
                    id: bitgrid2MouseArea
                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    onClicked: bitgrid2Action.trigger()
                }
            }

            Rectangle {
                id: abletonLinkButton

                color: abletonLinkMouseArea.pressed
                        ? LateNightTheme.toolbarButtonActiveBackgroundColor
                        : LateNightTheme.toolbarButtonInactiveBackgroundColor
                height: parent.height
                radius: 2
                width: 89

                BorderImage {
                    anchors.fill: parent
                    border.bottom: 2
                    border.left: 2
                    border.right: 2
                    border.top: 2
                    horizontalTileMode: BorderImage.Stretch
                    source: LateNightTheme.lateNightAsset("buttons", "btn_embedded_library.svg")
                    verticalTileMode: BorderImage.Stretch
                }

                Text {
                    anchors.fill: parent
                    color: abletonLinkControl.value > 0.0
                            ? LateNightTheme.toolbarButtonActiveTextColor
                            : LateNightTheme.toolbarButtonInactiveTextColor
                    font.family: "Open Sans"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "LINK"
                }

                MouseArea {
                    id: abletonLinkMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.ArrowCursor
                    preventStealing: true
                    onPressed: {
                        abletonLinkControl.value = abletonLinkControl.value > 0.0 ? 0.0 : 1.0;
                    }
                }
            }
        }
    }

    StartupScreen {
        id: startupScreen

        anchors.fill: parent
        opacity: mainWindowLoader.status === Loader.Ready ? 0 : 1
        progress: root.displayedProgress
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }

    Component.onCompleted: {
        updateProgress();
        updateVisibility();
    }
}
