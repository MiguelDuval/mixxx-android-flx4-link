pragma ComponentBehavior: Bound

import "../Waveforms" as Waveforms

// Toolbar-local adapter for the real deck-scoped BeatgridControls component.
// Keeping this adapter in the Toolbar directory makes the type visible to
// Toolbar.qml without introducing another global/control-state implementation.
Waveforms.BeatgridControls {
    id: root
}
