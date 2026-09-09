import "../LateNightTheme"
import "../Deck"
import "../../../qml" as Shared
import Mixxx 1.0 as Mixxx
import QtQuick

Item {
    id: root

    property string deck1Group: "[Channel1]"
    property string deck2Group: "[Channel2]"
    property string deck3Group: "[Channel3]"
    property string deck4Group: "[Channel4]"
    property bool show4decks: false

    readonly property int beatgridToggleWidth: 26
    readonly property int beatgridToggleSpacing: 2
    readonly property int waveformWidth: Math.max(0, root.width - root.beatgridToggleWidth - root.beatgridToggleSpacing)

    // The legacy LateNight skin exposes one persistent [Skin] toggle for the
    // beatgrid controls section. Create that shared skin control once for the
    // whole waveform stack so every DeckWaveform observes the same state.
    Mixxx.SkinControlCreator {
        id: showBeatgridControlsCreator

        group: "[Skin]"
        key: "show_beatgrid_controls"
        defaultValue: 1.0
        persist: true
    }

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
        height: parent.height / (root.show4decks ? 4 : 2)
        width: root.waveformWidth
    }
    DeckWaveform {
        id: deck2waveform

        anchors.bottom: root.show4decks ? deck4waveform.top : parent.bottom
        group: root.deck2Group
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

                Shared.FadeBehavior on visible {
                    fadeTarget: deck4waveform
                }
            }
        }
    }

    LateNightControlButton {
        id: beatgridToggle

        anchors.right: parent.right
        anchors.top: parent.top
        width: root.beatgridToggleWidth
        height: 52
        backgroundSource: LateNightTheme.lateNightTopRegionButton("library_tall")
        iconSource: LateNightTheme.assetDeckBeatCurposLargeButton
        group: "[Skin]"
        key: "show_beatgrid_controls"
        toggleable: true
        activeBackgroundSuffix: "active"
        pressedBackgroundSuffix: "active"
        activeOpacity: 1.0
        inactiveOpacity: 0.82
        activeColor: LateNightTheme.deckDimButtonInactiveColor
        inactiveColor: LateNightTheme.deckDimButtonInactiveColor
    }
}
