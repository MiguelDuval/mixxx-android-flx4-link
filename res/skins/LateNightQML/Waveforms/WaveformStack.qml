import "../LateNightTheme"
import "../Deck"
import "../../../qml" as Shared
import Mixxx 1.0 as Mixxx

Item {
    id: root

    property string deck1Group: "[Channel1]"
    property string deck2Group: "[Channel2]"
    property string deck3Group: "[Channel3]"
    property string deck4Group: "[Channel4]"
    property bool show4decks: false

    readonly property int beatgridToggleWidth: 26
    readonly property int beatgridToggleSpacing: 2
    readonly property int beatgridButtonsWidth: beatgridToggleWidth * 2 + beatgridToggleSpacing
    readonly property real waveformWidth: Math.max(0, root.width - root.beatgridButtonsWidth)

    Mixxx.ControlProxy {
        id: beatgridVisibilityProxy
        group: "[Skin]"
        key: "show_beatgrid_controls"
    }

    readonly property bool showBeatgridControls: beatgridVisibilityProxy.value > 0

    Loader {
        id: waveformContent

        anchors.fill: parent
        active: true

        sourceComponent: Component {
            Item {
                anchors.fill: parent

                Loader {
                    id: deck3waveform

                    readonly property string group: root.deck3Group

                    active: root.show4decks
                    anchors.top: parent.top
                    height: parent.height / 4
                    width: root.waveformWidth

                    sourceComponent: Component {
                        DeckWaveform {
                            group: deck3waveform.group
                            showBeatgridControls: root.showBeatgridControls

                            Shared.FadeBehavior on visible {
                                fadeTarget: deck3waveform
                            }
                        }
                    }
                }

                DeckWaveform {
                    id: deck1waveform

                    anchors.top: root.show4decks ? deck3waveform.bottom : parent.top
                    group: root.deck1Group
                    showBeatgridControls: root.showBeatgridControls
                    height: parent.height / (root.show4decks ? 4 : 2)
                    width: root.waveformWidth
                }

                DeckWaveform {
                    id: deck2waveform

                    anchors.bottom: root.show4decks ? deck4waveform.top : parent.bottom
                    group: root.deck2Group
                    showBeatgridControls: root.showBeatgridControls
                    height: parent.height / (root.show4decks ? 4 : 2)
                    width: root.waveformWidth
                }

                Loader {
                    id: deck4waveform

                    readonly property string group: root.deck4Group

                    active: root.show4decks
                    anchors.bottom: parent.bottom
                    height: parent.height / 4
                    width: root.waveformWidth

                    sourceComponent: Component {
                        DeckWaveform {
                            group: deck4waveform.group
                            showBeatgridControls: root.showBeatgridControls

                            Shared.FadeBehavior on visible {
                                fadeTarget: deck4waveform
                            }
                        }
                    }
                }

                // Existing LateNight artwork retained for visual comparison.
                LateNightIconButton {
                    id: beatgridToggle

                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: root.beatgridToggleWidth
                    height: 52
                    backgroundSource: LateNightTheme.lateNightTopRegionButton("library_tall")
                    iconSource: LateNightTheme.assetDeckBeatCurposLargeButton
                    activeState: root.showBeatgridControls
                    activeBackgroundSuffix: "active"
                    pressedBackgroundSuffix: "active"
                    activeOpacity: 1.0
                    contentOpacity: root.showBeatgridControls ? 1.0 : 0.82
                }
            }
        }
    }

    // Independent BeatGrid test control is intentionally outside the Loader.
    // It is a direct child of WaveformStack, so its geometry and z-order do not
    // depend on the dynamically created waveform component.
    LateNightIconButton {
        id: independentBeatgridToggle

        anchors.right: parent.right
        anchors.rightMargin: root.beatgridToggleWidth + root.beatgridToggleSpacing
        anchors.top: parent.top
        width: root.beatgridToggleWidth
        height: 52
        z: 10000
        visible: true
        backgroundSource: LateNightTheme.lateNightTopRegionButton("library_tall")
        iconSource: LateNightTheme.assetDeckBeatCurposLargeButton
        activeState: root.showBeatgridControls
        activeBackgroundSuffix: "active"
        pressedBackgroundSuffix: "active"
        activeOpacity: 1.0
        contentOpacity: root.showBeatgridControls ? 1.0 : 0.82

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            border.color: "#ffffff"
            border.width: 1
            opacity: 0.85
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            onClicked: {
                beatgridVisibilityProxy.value = beatgridVisibilityProxy.value > 0 ? 0 : 1
            }
        }
    }
}
