import "." as Skin
import Mixxx 1.0 as Mixxx
import QtQuick 2.12
import "Theme"

Item {
    id: root

    anchors.fill: parent
    z: 100001
    visible: Qt.platform.os === "android" && Mixxx.Core.ready

    Mixxx.ControlProxy {
        id: linkEnabled
        group: "[AbletonLink]"
        key: "sync_enabled"
    }

    Mixxx.ControlProxy {
        id: linkPeers
        group: "[AbletonLink]"
        key: "num_peers"
    }

    Mixxx.ControlProxy {
        id: linkSync
        group: "[AbletonLink]"
        key: "sync_decks"
    }

    Skin.Button {
        id: linkButton

        x: 364
        y: 5
        width: 52
        height: 26
        text: "Link"
        highlight: linkEnabled.initialized && linkEnabled.value > 0.5
        activeColor: Theme.white

        onPressed: {
            if (linkEnabled.initialized) {
                linkEnabled.value = linkEnabled.value > 0.5 ? 0.0 : 1.0;
            }
        }
    }

    Text {
        x: 418
        y: 5
        width: 42
        height: 26
        color: Theme.lightGray3
        font.family: Theme.fontFamily
        font.pixelSize: 9
        font.bold: true
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        text: linkPeers.initialized ? "P" + Math.max(0, Math.round(linkPeers.value)) : ""
    }

    Skin.Button {
        id: linkSyncButton

        x: 462
        y: 5
        width: 58
        height: 26
        text: "Sync"
        activeColor: Theme.white
        enabled: linkEnabled.initialized && linkEnabled.value > 0.5
        highlight: linkSync.initialized && linkSync.value > 0.5

        onPressed: {
            if (linkSync.initialized && enabled) {
                linkSync.value = linkSync.value > 0.5 ? 0.0 : 1.0;
            }
        }
    }
}
