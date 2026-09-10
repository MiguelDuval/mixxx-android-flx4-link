import QtQuick
import Mixxx 1.0 as Mixxx
import "../LateNightTheme"

// Independent BeatGrid button that directly calls real beatgrid functionality
// This bypasses the UI visibility toggle and directly triggers beatgrid operations
LateNightControlButton {
    id: root

    required property string group

    // Configuration
    property string beatgridAction: "beats_translate_curpos"  // Default: move beatgrid to current position
    property string displayText: "Grid"
    property int buttonWidth: 68
    property int buttonHeight: 26

    Layout.preferredWidth: buttonWidth
    Layout.preferredHeight: buttonHeight
    backgroundSource: LateNightTheme.lateNightSubRegionButton("medium")
    iconSource: LateNightTheme.assetDeckBeatgridButton
    group: root.group
    key: root.beatgridAction
    toggleable: false  // Not a toggle - it's an action button

    // Visual feedback
    activeBackgroundSuffix: "active"
    pressedBackgroundSuffix: "active"
    activeOpacity: 1.0
    inactiveOpacity: 0.82
    activeColor: LateNightTheme.activePlayCueColor

    // Custom handler that directly triggers the beatgrid action
    // and provides diagnostic feedback
    onClicked: {
        console.log("[IndependentBeatGrid] Button pressed for group:", root.group, "action:", root.beatgridAction)
        
        // Create a temporary ControlProxy to trigger the action
        var control = Qt.createQmlObject('import Mixxx 1.0 as Mixxx; Mixxx.ControlProxy { group: "' + root.group + '"; key: "' + root.beatgridAction + '" }', root);
        if (control) {
            control.value = 1.0
            control.value = 0.0
            console.log("[IndependentBeatGrid] Action triggered:", root.beatgridAction, "for group:", root.group)
        } else {
            console.log("[IndependentBeatGrid] ERROR: Failed to create ControlProxy")
        }
    }

    // Visual feedback for pressed state
    pressedState: root.pressed
    activeState: false  // Not a toggle, so no persistent active state
}