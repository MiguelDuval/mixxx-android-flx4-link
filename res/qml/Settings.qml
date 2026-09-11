import "." as Skin
import Mixxx 1.0 as Mixxx
import QtQuick 2.12
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import "Theme"
import "Settings" as Settings

Popup {
    id: root

    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"
    property bool mobilePageActive: false
    property var activeCategory: null
    property alias activeCategoryIndex: categoryList.currentIndex
    readonly property var manager: managerItem
    property alias sections: managerItem.data

    function updateActiveCategory() {
        root.activeCategory?.deactivated();
        root.activeCategory = managerItem.data[categoryList.currentIndex] ?? null;
        root.activeCategory?.activated();
    }

    function openCategory(index) {
        categoryList.currentIndex = index;
        if (root.isMobile) {
            root.mobilePageActive = true;
        }
    }

    function backToCategoryList() {
        root.mobilePageActive = false;
        searchSetting.active = false;
        searchInput.text = "";
        root.manager.search("");
    }

    horizontalPadding: root.isMobile ? 0 : 20
    verticalPadding: root.isMobile ? 0 : 20

    onOpened: {
        if (root.isMobile) {
            root.mobilePageActive = false;
        }
    }

    background: Rectangle {
        anchors.fill: parent
        color: Theme.darkGray2
        opacity: parent.radius < 0 ? Math.max(0.1, 1 + parent.radius / 8) : 1
        radius: root.isMobile ? 0 : 8
    }

    Item {
        id: contentRoot

        anchors.fill: parent

        Rectangle {
            id: navigationPanel

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.isMobile ? parent.width : 280
            visible: !root.isMobile || !root.mobilePageActive
            color: Theme.darkGray
            border.color: Theme.darkGray3
            border.width: root.isMobile ? 0 : 6
            z: 10

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.isMobile ? 0 : 6
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.isMobile ? 58 : 34
                    color: Theme.darkGray

                    Skin.Button {
                        anchors.fill: parent
                        activeColor: Theme.white
                        text: root.isMobile ? "←  Settings" : "← Back to Mixxx"
                        font.pixelSize: root.isMobile ? 18 : 14

                        onClicked: {
                            root.close();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    color: Theme.darkGray3
                    height: 1
                }

                Rectangle {
                    id: searchSetting

                    property bool active: false
                    property alias input: searchInput

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.isMobile ? 46 : 30
                    Layout.margins: root.isMobile ? 12 : 0
                    color: Theme.midGray
                    radius: 4

                    Text {
                        id: searchInputPlaceholder

                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.white
                        font.pixelSize: root.isMobile ? 15 : 12
                        text: "Search settings..."
                        visible: !parent.active
                    }
                    TextInput {
                        id: searchInput

                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        color: Theme.white
                        font.pixelSize: root.isMobile ? 15 : 12
                        visible: parent.active

                        onActiveFocusChanged: {
                            parent.active = activeFocus;
                        }
                        onTextEdited: {
                            root.manager.search(text);
                        }
                    }
                    TapHandler {
                        onTapped: {
                            parent.active = true;
                            searchInput.forceActiveFocus();
                        }
                    }
                }

                ListView {
                    id: categoryList

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.leftMargin: root.isMobile ? 12 : 0
                    Layout.rightMargin: root.isMobile ? 12 : 0
                    clip: true
                    currentIndex: 0
                    focus: true
                    model: sectionProperties
                    visible: !searchSetting.active
                    spacing: root.isMobile ? 4 : 0

                    delegate: Rectangle {
                        required property int index
                        required property var label

                        color: ListView.isCurrentItem ? Theme.darkGray3 : Theme.darkGray2
                        height: root.isMobile ? 56 : 38
                        radius: root.isMobile ? 5 : 0
                        width: ListView.view.width

                        Image {
                            id: handleImage

                            anchors.left: parent.left
                            anchors.leftMargin: root.isMobile ? 14 : 8
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectFit
                            height: root.isMobile ? 28 : 24
                            source: "images/gear.svg"
                            visible: false
                            width: root.isMobile ? 28 : 24
                        }
                        ColorOverlay {
                            anchors.fill: handleImage
                            antialiasing: true
                            color: parent.ListView.isCurrentItem ? Theme.accentColor : Theme.midGray
                            source: handleImage
                        }
                        Text {
                            anchors.left: handleImage.right
                            anchors.leftMargin: root.isMobile ? 14 : 8
                            anchors.right: parent.right
                            anchors.rightMargin: root.isMobile ? 34 : 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.white
                            elide: Text.ElideRight
                            font.bold: parent.ListView.isCurrentItem
                            font.pixelSize: root.isMobile ? 16 : 13
                            text: label
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: root.isMobile ? 14 : 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.midGray
                            font.pixelSize: root.isMobile ? 18 : 14
                            text: "›"
                            visible: root.isMobile
                        }
                        TapHandler {
                            onTapped: root.openCategory(index)
                        }
                    }
                }

                ListView {
                    id: settingResultList

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.leftMargin: root.isMobile ? 12 : 0
                    Layout.rightMargin: root.isMobile ? 12 : 0
                    clip: true
                    focus: true
                    model: root.manager.model
                    spacing: root.isMobile ? 4 : 0
                    visible: searchSetting.active

                    delegate: Rectangle {
                        required property var display
                        required property int index
                        required property var toolTip
                        required property var whatsThis

                        color: Theme.darkGray2
                        height: root.isMobile ? 64 : 40
                        radius: root.isMobile ? 5 : 0
                        width: ListView.view.width

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: root.isMobile ? 8 : 4

                            Text {
                                Layout.fillWidth: true
                                Layout.preferredHeight: implicitHeight
                                color: Theme.white
                                elide: Text.ElideRight
                                font.pixelSize: root.isMobile ? 14 : 12
                                text: searchSetting.input.text ? display.replace(searchSetting.input.text, `<b>${searchSetting.input.text}</b>`) : display
                                textFormat: Text.RichText
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredHeight: implicitHeight
                                color: Theme.midGray
                                elide: Text.ElideRight
                                font.pixelSize: root.isMobile ? 11 : 10
                                maximumLineCount: root.isMobile ? 2 : 1
                                text: searchSetting.input.text ? whatsThis.replace(searchSetting.input.text, `<b>${searchSetting.input.text}</b>`) : whatsThis
                                textFormat: Text.RichText
                            }
                        }
                        TapHandler {
                            onTapped: {
                                for (let setting of toolTip) {
                                    setting.activated();
                                }
                                if (root.isMobile) {
                                    root.mobilePageActive = true;
                                }
                                parent.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: pageHost

            anchors.left: root.isMobile ? parent.left : navigationPanel.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0
            visible: !root.isMobile || root.mobilePageActive
            z: root.isMobile ? 5 : 1

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.isMobile ? 58 : 42
                color: Theme.darkGray2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.isMobile ? 6 : 0
                    anchors.rightMargin: root.isMobile ? 12 : 0

                    Skin.Button {
                        Layout.preferredWidth: root.isMobile ? 64 : 0
                        Layout.preferredHeight: root.isMobile ? 46 : 34
                        activeColor: Theme.white
                        text: "←"
                        visible: root.isMobile
                        font.pixelSize: 24

                        onClicked: root.backToCategoryList()
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: Theme.white
                        elide: Text.ElideRight
                        font.pixelSize: root.isMobile ? 19 : 16
                        font.weight: Font.DemiBold
                        horizontalAlignment: root.isMobile ? Text.AlignLeft : Text.AlignHCenter
                        text: root.isMobile ? (root.activeCategory?.label ?? "Settings") : "Settings"
                    }
                    Item {
                        Layout.preferredWidth: root.isMobile ? 8 : 0
                    }
                }
            }

            Rectangle {
                id: tabBar

                readonly property int selectedIndex: root.activeCategory?.selectedIndex ?? 0
                readonly property var tabs: root.activeCategory?.tabs ?? []

                Layout.fillWidth: true
                Layout.preferredHeight: visible ? (root.isMobile ? 48 : 30) : 0
                color: Theme.darkGray3
                visible: tabs?.length > 0

                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: root.isMobile ? 4 : 0
                    anchors.rightMargin: root.isMobile ? 4 : 0
                    clip: true
                    contentWidth: tabRow.implicitWidth
                    flickableDirection: Flickable.HorizontalFlick

                    RowLayout {
                        id: tabRow

                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        spacing: root.isMobile ? 4 : 0

                        Repeater {
                            model: tabBar.tabs

                            Skin.Button {
                                required property int index
                                required property string modelData

                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: root.isMobile ? 42 : 22
                                Layout.preferredWidth: root.isMobile ? Math.max(104, implicitWidth + 28) : Math.max(90, parent.width / (tabBar.tabs.length + 2))
                                activeColor: Theme.white
                                checked: tabBar.selectedIndex == index
                                text: modelData
                                font.pixelSize: root.isMobile ? 13 : 12

                                onPressed: {
                                    if (root.activeCategory?.selectedIndex || root.activeCategory?.selectedIndex === 0) {
                                        root.activeCategory.selectedIndex = index;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Mixxx.SettingParameterManager {
                id: managerItem

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.leftMargin: root.isMobile ? 0 : 20

                Component.onCompleted: {
                    let activateBuilder = index => function () {
                            categoryList.currentIndex = index;
                        };
                    let visibleBuilder = index => function () {
                            return categoryList.currentIndex == index;
                        };
                    for (let index = 0; index < data.length; index++) {
                        let child = data[index];
                        if (!child.label)
                            continue;
                        sectionProperties.append({
                            label: child.label
                        });
                        child.visible = Qt.binding(visibleBuilder(index));
                        child.activated.connect(activateBuilder(index));
                        child.anchors.fill = this;
                    }
                    root.activeCategoryIndex = root.activeCategoryIndex;
                }

                Settings.SoundHardware {
                }
                Settings.Library {
                }
                Settings.Controller {
                }
                Settings.Interface {
                }
                Settings.MixerEffect {
                }
                Settings.AutoDJ {
                }
                Settings.Broadcast {
                }
                Settings.Recording {
                }
                Settings.Analyzer {
                }
                Settings.StatsPerformance {
                }
            }
        }
    }

    onActiveCategoryIndexChanged: updateActiveCategory()
    onSectionsChanged: updateActiveCategory()

    ListModel {
        id: sectionProperties
    }
}
