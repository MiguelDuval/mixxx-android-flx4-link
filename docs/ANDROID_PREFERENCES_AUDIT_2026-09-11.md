# Android Preferences Audit — 2026-09-11

Baseline: `stable/android-working-2026-09-11-padfx`
Baseline commit: `186f95c95d88a6859f5059d723d33d104e88a41d`

## Executive conclusion

The Android APK is explicitly launched in QML mode (`QT_ANDROID_APPLICATION_ARGUMENTS "--qml --log-level debug --developer"`). The QML application still constructs the legacy C++ `DlgPreferences`, but the visible Android Settings entry point is `res/qml/Settings.qml`.

Therefore there are two settings systems in the Android build:

1. Legacy C++/Qt Widgets Preferences (`DlgPreferences` and `src/preferences/dialog/*`). This contains most of the desktop Mixxx preference pages, but is a desktop layout and is not the right primary Android UX.
2. QML Settings (`res/qml/Settings.qml` + `res/qml/Settings/*`). This is the actual mobile-facing settings UI. It is already responsive in places, but its category list is incomplete and several categories are explicit placeholders.

## Android entry path

`CMakeLists.txt` configures Android with Qt 6/QML and sets:

`QT_ANDROID_APPLICATION_ARGUMENTS "--qml --log-level debug --developer"`

`src/qml/qmlapplication.cpp` creates the legacy `DlgPreferences` before the QML UI is shown because some initialization is required (notably effects initialization), then exposes it through `QmlDlgPreferencesProxy`.

`res/qml/MainWindow.qml` uses `Skin.Settings` as the normal Settings button. A long press on that button calls `Mixxx.PreferencesDialog.show()`, which opens the legacy C++ Preferences dialog.

## Legacy C++ Preferences inventory

The C++ dialog registers these pages on the current code path:

- Sound Hardware
- Library
- Controllers
- Vinyl Control — conditional on `__VINYLCONTROL__`
- Interface — omitted when QML mode is active (`CmdlineArgs::Instance().isQml()`)
- Waveforms — only if `WaveformWidgetFactory::isCreated()`
- Colors
- Decks
- Mixer
- Effects
- Auto DJ
- Live Broadcasting — conditional on `__BROADCAST__`
- Recording
- Beat Detection
- Key Detection
- Normalization
- Modplug Decoder — conditional on `__MODPLUG__`

Each ordinary page is wrapped into a `QScrollArea` before being inserted into the desktop-style `QStackedWidget`.

## Actual QML Android Settings inventory

`res/qml/Settings.qml` currently instantiates:

- SoundHardware
- Library
- Controller
- Interface
- MixerEffect
- AutoDJ
- Broadcast
- Recording
- Analyzer
- StatsPerformance

This is the important mobile inventory because `MainWindow.qml` opens `Skin.Settings` directly.

## QML category status

### Implemented / substantial

**SoundHardware** — substantial implementation. Includes engine, delays and stats tabs, reads/writes `SoundManager`, audio API, sample rate, buffer size, keylock engine, routing, inputs/outputs and delay settings.

**Library** — substantial implementation. Includes library sources, scanning, integrations, metadata/search settings and other library behavior. Uses `ScrollView` and responsive grid behavior (`columns: width > 800 ? 2 : 1`).

**Controller** — substantial implementation. Uses `Mixxx.ControllerManager`, controller cards, known/unknown devices and per-controller settings.

**Interface** — substantial implementation. Already contains theme/color, waveform and decks tabs. It maps many controls directly to `Mixxx.Config`. Some theme/skin controls are still TODO/commented and waveform loading/saving functions are currently empty.

### Explicit placeholders / not implemented

**MixerEffect** — placeholder only. It currently exposes one green square and no actual mixer/effect settings.

**AutoDJ** — placeholder only. It exposes one black square.

**Broadcast** — placeholder only. It exposes one yellow square.

**Analyzer** — placeholder only. It exposes one grey square.

`StatsPerformance` is registered but still needs dedicated inspection; it is not yet counted as complete.

## Important mismatch with desktop Mixxx

The QML Android Settings category set is not a one-to-one mapping of the desktop C++ Preferences pages. Important desktop areas such as Colors, a dedicated Decks page, Waveforms, Effects, Mixer, Key Detection and Normalization are not exposed as separate QML categories today. Some of these concepts are partially folded into Interface, but not all corresponding functionality is present.

Conversely, QML has Analyzer and Stats/Performance categories that do not appear as the same named standalone pages in the legacy desktop Preferences list.

## Layout diagnosis

`res/qml/Settings.qml` currently uses a horizontal desktop-like arrangement:

- fixed/preferred 280px category pane
- category list on the left
- title + optional tab bar + content on the right
- 20px outer padding
- popup constrained by `height: Math.min(840, parent.height)` and `width: Math.min(1400, parent.width)` in `MainWindow.qml`

This is serviceable on wide screens but not an appropriate primary phone layout. The correct Android direction is to retain the existing category components and their settings logic, but change the shell/navigation to a mobile list → full-screen page model. Individual category content should remain scrollable.

## Known feature-flag/runtime conditions

Legacy C++ Preferences has compile/runtime conditions for Vinyl Control, Broadcasting, Modplug, Waveform factory availability, and Interface/QML mode. These conditions explain why not every desktop page appears in the old dialog.

For the Android build specifically, the more important issue is that QML Settings bypasses most of those desktop pages entirely; the main work is therefore to expand the QML Settings surface rather than trying to force the desktop tree back onto the phone.

## Recommended implementation order

1. Keep baseline branch untouched.
2. Redesign only `res/qml/Settings.qml` shell for Android: portrait-first, full-screen category list, back navigation, safe scrolling, touch-friendly rows, optional landscape two-pane mode.
3. Preserve existing category business logic and `Mixxx.Config`/proxy bindings.
4. Replace placeholder categories one at a time, starting with Mixer & Effects because it directly affects the current app's DJ workflow.
5. Add missing functional categories from desktop Mixxx into QML where useful: Decks, Waveforms, Effects, Mixer, Colors/Theme, Beat/Key/Normalization as appropriate.
6. Inspect `StatsPerformance` before deciding whether it is useful on Android or should remain secondary.
7. Only after QML Settings is functionally complete should the legacy C++ Preferences dialog be treated as an advanced/developer fallback.

## External references checked

- Current upstream Mixxx `DlgPreferences` retains the desktop tree/splitter/stacked-page architecture.
- Upstream Android build instructions use the same Android/QML build path and APK target.
- DJ Sugar describes a fork with first-class Android support and mobile-optimized UX, reinforcing the direction of an Android-specific presentation layer rather than scaling the desktop Preferences dialog.
