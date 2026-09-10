pragma ComponentBehavior: Bound

import "../LateNightTheme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Compatibility popup type used by the latest BitGrid toolbar patch.
// This intentionally mirrors the existing inline ToolbarSettingsPopup API:
// anchorButton is owned by Toolbar.qml and positioning is performed there.
Popup {
    id: root

    property MouseArea anchorButton: null
    property int minimumWidth: 190

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    modal: false
    padding: 3
    width: Math.max(minimumWidth, contentColumn.implicitWidth + leftPadding + rightPadding)

    background: Rectangle {
        border.color: LateNightTheme.toolbarPopupBorderColor
        border.width: 1
        color: LateNightTheme.toolbarPopupBackgroundColor
        radius: 2
    }

    contentItem: ColumnLayout {
        id: contentColumn
        spacing: 0
    }
}
