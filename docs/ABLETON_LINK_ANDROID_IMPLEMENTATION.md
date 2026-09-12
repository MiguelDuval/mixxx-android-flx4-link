# Ableton Link Android implementation

The Android UI exposes the existing native Mixxx Ableton Link session through the `[AbletonLink]` control group.

Controls used by the mobile UI:

- `[AbletonLink]`, `sync_enabled`: toggles the native Link session.
- `[AbletonLink]`, `num_peers`: reports the current number of Link peers.

The Android `main.qml` contains a high-z touch overlay for the Link control. It uses `MouseArea.onPressed` with `preventStealing: true`, matching the Android touch-handling strategy already used for the mobile BeatGrid overlay.

The native Link implementation lives in `src/engine/sync/abletonlink.cpp` / `.h` and is instantiated by `EngineSync`. CMake already fetches Ableton Link 3.0.6 and links it into `mixxx-lib` for Android.
