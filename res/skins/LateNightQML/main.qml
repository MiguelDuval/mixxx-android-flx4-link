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

    Mixxx.ControlProxy {
        id: abletonLinkPeersControl
        group: "[AbletonLink]"
        key: "num_peers"
    }

    Mixxx.ControlProxy {
        id: showMaximizedLibraryControl
        group: "[Skin]"
        key: "show_maximized_library"
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

    // Reliable Android Ableton Link toggle.
    // This overlay deliberately sits above the existing toolbar button because
    // Android can let the waveform MouseArea steal a nested release/tap gesture.
    // It reads and writes the real native [AbletonLink] controls, so it is not
    // a second Link implementation and stays synchronized with the engine.
    Rectangle {
        id: abletonLinkOverlay

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 27
        color: LateNightTheme.toolbarRootBackgroundColor
        height: 34
        visible: Qt.platform.os === "android"
                && (!showMaximizedLibraryControl.initialized || showMaximizedLibraryControl.value <= 0.0)
        width: 74
        x: 190
        z: 10001

        Rectangle {
            anchors.fill: parent
            color: LateNightTheme.toolbarRootBackgroundColor
        }

        MouseArea {
            id: abletonLinkTouchArea

            anchors.fill: abletonLinkButton
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            hoverEnabled: false

            onPressed: {
                if (abletonLinkControl.initialized) {
                    abletonLinkControl.value = abletonLinkControl.value > 0.0 ? 0.0 : 1.0;
                }
            }
        }

        Rectangle {
            id: abletonLinkButton

            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 4
            color: abletonLinkControl.value > 0.0
                    ? LateNightTheme.toolbarButtonActiveBackgroundColor
                    : LateNightTheme.toolbarButtonInactiveBackgroundColor
            height: 26
            width: 70

            BorderImage {
                anchors.fill: parent
                border.bottom: 2
                border.left: 2
                border.right: 2
                border.top: 2
                horizontalTileMode: BorderImage.Stretch
                source: abletonLinkControl.value > 0.0
                        ? LateNightTheme.lateNightAsset("buttons", "btn_embedded_library_active.svg")
                        : LateNightTheme.lateNightAsset("buttons", "btn_embedded_library.svg")
                verticalTileMode: BorderImage.Stretch
            }

            Text {
                anchors.fill: parent
                color: abletonLinkControl.value > 0.0
                        ? LateNightTheme.toolbarButtonActiveTextColor
                        : LateNightTheme.toolbarButtonInactiveTextColor
                elide: Text.ElideRight
                font {
                    family: "Open Sans"
                    pixelSize: 11
                    styleName: "Bold"
                    weight: Font.Bold
                }
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
                text: "LINK" + (abletonLinkPeersControl.initialized
                        ? " " + Math.max(0, Math.round(abletonLinkPeersControl.value))
                        : "")
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // Dedicated BeatGrid test strip.
    // It lives outside the toolbar's width-constrained RowLayout so the two
    // controls remain visible even on narrow Android screens.
    Rectangle {
        id: bitgridBar

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 27
        color: LateNightTheme.toolbarRootBackgroundColor
        height: 34
        width: 190
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
