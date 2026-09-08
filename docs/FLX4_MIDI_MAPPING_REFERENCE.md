# Pioneer DDJ-FLX4 — MIDI Mapping Reference for the Android Mixxx fork

> **Purpose:** persistent project reference for future FLX4 mapping work. This document is a design/reference artifact, not executable code. It must be consulted before changing `res/controllers/Pioneer-DDJ-FLX4.midi.xml`, `Pioneer-DDJ-FLX4-script.js`, or FLX4-specific controller behavior.
>
> **Known-good Android MIDI baseline:** commit `ff3be2101cb0b1308be68936e027c5138baf25ee` (`android midi: use UsbDeviceConnection for MIDI transport`). At that point DDJ-FLX4 MIDI input was verified on Android and the built-in FLX4 audio interface was verified by the user. Do not regress this transport while changing mappings.

## 1. Source hierarchy / confidence

Use sources in this order:

1. **AlphaTheta/Pioneer official DDJ-FLX4 MIDI Message List** — authoritative for physical MIDI messages: channel, NOTE/CC, data number, input/output behavior.
2. **AlphaTheta/Pioneer official hardware diagrams** for rekordbox Mac/Windows and rekordbox iOS/Android — authoritative for intended controller workflow and Shift functions in rekordbox.
3. **Official/first-party application hardware guides** (Serato, etc.) — useful for understanding how the same hardware is interpreted by other applications.
4. **Current Mixxx upstream FLX4 mapping** — authoritative for how Mixxx currently exposes the controls and scripts, but not necessarily ideal for our Android UX.
5. Community mappings (djay, other Mixxx mappings) — useful for alternative interaction ideas, never a replacement for the official MIDI table.

### Important distinction

The **physical controller protocol** and the **application mapping** are different layers. A MIDI message does not intrinsically mean "load track" or "play". The FLX4 sends a message; the application decides what that message means. Therefore our goal is to make the Mixxx mapping express the FLX4 workflow without hard-coding controller behavior into Android UI code unless there is no viable mapping/control-object route.

---

## 2. Physical layout and global mental model

The FLX4 is organized into five practical areas:

- **Deck 1 / left:** transport, jog, loops, sync/tempo, pads.
- **Beat FX / right-center:** FX channel selector, FX selector, beat division, FX depth and on/off.
- **Mixer / center:** master, channel trim/EQ/filter, channel cue/faders, crossfader, headphone controls, Smart CFX/Smart Fader.
- **Deck 2 / right:** same transport/jog/loop/sync/tempo/pads as Deck 1.
- **Browser / top center:** Browse encoder, Load 1, Load 2. The current rekordbox diagrams also distinguish Browse, Load and View/back-related actions depending on software/version.

The left and right deck controls are intentionally symmetrical. A robust Mixxx mapping should therefore use the same logical mapping model for both decks, differing only by channel/deck number.

---

## 3. Browser / Library controls

### BROWSE encoder

**Physical operations**
- Rotate: navigate/scroll the library. In rekordbox, rotation scrolls the track list/tree view; on waveform/library-focused contexts it can also serve application-specific browsing behavior.
- Press: move focus between the library tree and track list in rekordbox.
- Shift + rotate: application-dependent alternate function. In the official rekordbox mapping this is associated with fast library scrolling in mobile/Serato-style workflows and waveform zoom in the desktop rekordbox diagram; Mixxx currently uses it for waveform zoom.
- Shift + press: move focus in the opposite direction in Mixxx/upstream-style mappings.

**Current Mixxx reference**
- `status 0xB6`, `midino 0x40`: `MoveVertical` in `[Library]` using `SelectKnob`.
- `status 0x96`, `midino 0x41`: `MoveFocusForward`.
- `status 0x96`, `midino 0x42`: `MoveFocusBackward`.
- Shift + rotate currently maps to `PioneerDDJFLX4.waveformZoom`.

**Design requirement for our Android fork**
- The Browse encoder should be the primary physical navigation device for Library.
- Rotation must reliably move the selected row/scroll position.
- Press should be treated as a deliberate Library-focus action. If we implement the user's requested "press opens Library" behavior, it should be an application-level mapping/command (or a ControlObject exposed to mapping), not a special-case FLX4 USB handler.
- When the Library is already visible, the same press should not unexpectedly destroy context; focus toggling is preferred over a destructive navigation action.

### LOAD 1 / LOAD 2

- LOAD 1: load the selected library track to Deck 1.
- LOAD 2: load the selected library track to Deck 2.
- In rekordbox, double-pressing Load can perform Instant Doubles.
- Shift behavior is software-specific. Examples in first-party documentation include moving to related tracks or sorting/browse actions.

**Current Mixxx reference**
- `status 0x96`, `midino 0x46`: `[Channel1] LoadSelectedTrack`.
- `status 0x96`, `midino 0x47`: `[Channel2] LoadSelectedTrack`.

---

## 4. Deck transport controls (both decks)

### SHIFT

The physical Shift button is a modifier, not a normal transport command.

- Deck 1 Shift: MIDI note `0x3F` on MIDI channel 1.
- Deck 2 Shift: MIDI note `0x3F` on MIDI channel 2.
- In Mixxx the mapping script tracks the Shift state and uses it to reinterpret other controls.

**Rule:** do not model Shift as a collection of unrelated duplicate commands. Treat it as a modifier state shared by all controls that explicitly document a Shift alternative.

### PLAY / PAUSE

Primary:
- Toggle play/pause on the deck.

Shift:
- In Mixxx/reference mappings: reverse playback roll/censor while held.
- Other software may use stutter/reverse or another secondary transport behavior.

MIDI reference used by Mixxx:
- `0x90/0x91`, note `0x0B` — Play/Pause.
- `0x90/0x91`, note `0x0E` — Shift alternate/reverse roll.

### CUE

Primary:
- Set/call temporary cue and back-cue behavior.

Shift:
- Jump to track start in the Mixxx/upstream mapping.
- In Serato documentation, Shift+CUE can load the previous track; this is a software-specific example and must not be assumed for Mixxx.

MIDI reference used by Mixxx:
- `0x90/0x91`, note `0x0C` — CUE.
- `0x90/0x91`, note `0x48` — Shift alternate/start-stop command.

---

## 5. Jog wheels — critical mapping area

Each deck has three logically distinct jog inputs:

### Jog platter rotation

- Vinyl mode: scratch.
- Non-vinyl mode: pitch bend.
- Shift + platter rotation: fast search / high-speed pitch-bend-style navigation in the standard Mixxx mapping.

Mixxx reference:
- channel 1: `0xB0`, CC `0x22` = platter turn / Vinyl path.
- channel 1: `0xB0`, CC `0x23` = platter turn / non-Vinyl path.
- channel 1: `0xB0`, CC `0x29` = Shift search.
- channel 2 uses the same CC numbers on `0xB1`.

### Jog touch

- Touch: enables scratching/pitch-bend mode while the platter is touched.
- Release: disables that temporary touch mode.
- Shift touch has an alternate high-speed search/pitch-bend behavior in the Mixxx mapping.

Mixxx reference:
- normal touch: note `0x36` on the deck MIDI channel.
- Shift touch: note `0x67`.

### Jog side

- Side/rim rotation is the pitch-bend input in the upstream Mixxx mapping.
- channel 1: `0xB0`, CC `0x21`.
- channel 2: `0xB1`, CC `0x21`.

### Important planned UX use

The user has requested **jog press for Library navigation**. This must be distinguished from **jog touch**: the touch sensor is already used for scratching and is not the same physical event as pressing the Browse encoder. The FLX4 jog platter itself is not the Browse button. Do not accidentally remap the touch sensor into Library open behavior.

---

## 6. TEMPO fader

The tempo slider is a 14-bit-style MSB/LSB control in the MIDI protocol.

Mixxx reference:
- channel 1: CC `0x00` (MSB) + CC `0x20` (LSB).
- channel 2: same pair on MIDI channel 2.

Primary:
- tempo/pitch control.

Shift:
- The official hardware documentation shows software-specific alternate behavior (for example, ignoring tempo/pitch adjustment in Serato). Do not invent an Android Mixxx Shift function without a concrete UX requirement.

---

## 7. BEAT SYNC / TEMPO RANGE

Each deck has a Beat Sync button.

Primary:
- Beat Sync to the master deck.

Long press:
- Set the deck as master in the Mixxx/reference workflow.

Shift + press:
- Cycle tempo range.

Official MIDI values used by the current Mixxx mapping:
- Note `0x58` = Sync press.
- Note `0x5C` = Sync long press.
- Note `0x60` = Shift tempo-range action.

**Design note:** long-press timing is a mapping concern. Keep its threshold and state handling in the controller script/control layer rather than Android UI.

---

## 8. Loop controls (both decks)

### IN

- Press: set loop-in point.
- While loop is active: adjust loop-in point with jog in rekordbox-style workflow.

### OUT

- Press: set loop-out point and begin loop playback.
- While loop is active: adjust loop-out point with jog in rekordbox-style workflow.
- Shift behavior varies by software; Serato uses Shift+OUT to toggle Vinyl mode.

### 4 BEAT / EXIT

- Press: start 4-beat/Auto Beat Loop.
- Press while loop is active: exit/cancel loop.
- Shift + press: Active Loop on/off in rekordbox; Mixxx should use the closest native loop/active-loop control available.

### CUE/LOOP CALL down/up

- Primary: select/recall cue or loop slots.
- During loop playback: down halves the loop; up doubles the loop in rekordbox.
- Shift functions vary by software and can include fast track navigation/search.

### 1/2X and 2X

- 1/2X: halve the active loop length / previous loop slot depending on software.
- 2X: double the active loop length / next loop slot depending on software.

**Current upstream Mixxx concept:** the FLX4 mapping uses the loop-size controls and script functions rather than treating them as generic MIDI buttons.

---

## 9. Performance Pad mode buttons

The FLX4 has four mode buttons per deck and eight performance pads per deck.

### Mode buttons

The standard pad-mode set documented for the FLX4 includes:

1. **HOT CUE**
2. **PAD FX1**
3. **BEAT JUMP**
4. **SAMPLER**
5. **KEYBOARD** (Shift-side / software-dependent alternate of Hot Cue)
6. **PAD FX2** (Shift-side alternate)
7. **BEAT LOOP** (Shift-side alternate)
8. **KEY SHIFT** (Shift-side alternate)

The important point is that these are **mode selectors**, not eight independent pad banks. The same eight pads change meaning according to the current mode.

### HOT CUE mode

- Pads trigger/set Hot Cues.
- In rekordbox documentation, up to eight Hot Cues can be set/used directly from the eight pads on this controller.
- Pad deletion is typically a Shift or software-specific action.

### PAD FX modes

- Pads trigger beat-synchronized effects.
- Pad FX1 and Pad FX2 represent two effect banks/modes.

### BEAT JUMP mode

- Pads jump playback position by fixed beat distances/directions determined by the application.

### SAMPLER mode

- Pads trigger sampler slots.
- Shift can be used for alternate/stop functions depending on the software.

### BEAT LOOP mode

- Pads create/select loop lengths.

### KEYBOARD / KEY SHIFT

- Provides musical pitch/key-oriented pad interaction in rekordbox-style workflows.
- Do not assume Mixxx has a one-to-one native equivalent; map only after checking available ControlObjects.

### Slicer note

Slicer is not one of the default FLX4 mode buttons in the stock pad layout. It can be assigned through application MIDI mapping in software that supports it (community examples exist for rekordbox). Therefore Slicer should be treated as an optional remapping/profile feature, not a stock FLX4 physical mode.

---

## 10. Beat FX section

The Beat FX section is one of the most important regions for our future FX work.

### FX CH SELECT

Three-position selector:
- 1 = apply/control Beat FX for channel 1.
- 2 = channel 2.
- 1&2 = both channels.

### FX SELECT

- Press: cycle through Beat FX.
- Shift + press: reverse through Beat FX.

### BEAT down/up

- BEAT down: decrease beat division/time value.
- BEAT up: increase beat division/time value.
- Shift + down: BPM Auto mode.
- Shift + up: BPM Tap mode.

### LEVEL/DEPTH

- Adjust the Beat FX parameter / intensity/depth.
- In djay, the same physical knob is used for FX dry/wet; exact semantics are application-specific.

### BEAT FX ON/OFF

- Toggle Beat FX on/off.
- Shift function may be Release FX or another software-specific action.

**Official/relevant first-party workflow:** the controller exposes FX channel selection, FX selection, beat/time control, parameter/depth and on/off as separate physical controls, which is an excellent direct fit for Mixxx's effect architecture.

---

## 11. Mixer section

The central mixer section repeats channel controls for CH1 and CH2.

### MASTER LEVEL

- Master output volume.

### MASTER CUE

- Master-output monitoring in headphones on/off.

### TRIM

- Channel input/gain trim.

### EQ HI / MID / LOW

- Three-band channel EQ.
- These are high-value direct mappings in Mixxx because channel EQ controls already exist as ControlObjects.

### CFX

- Sound Color FX / filter/Smart CFX depending on software.
- In some software it is a filter control; in others it can be integrated with a Smart FX system.

### CHANNEL CUE buttons

- Monitor the selected channel in headphones.
- Some software assigns a Shift alternate such as Tap BPM.

### CHANNEL FADERS

- Channel volume.
- Shift can invoke channel-fader start in supported software.

### CROSSFADER

- Crossfade between channels 1 and 2.
- Shift can invoke crossfader start in supported software.

---

## 12. Smart CFX / Smart Fader / headphone / microphone controls

### SMART CFX

- Primary: enable/disable Smart CFX.
- Shift: choose Smart CFX preset in software that exposes presets.
- Other applications may implement it as a combination of filter + configured FX.

### SMART FADER

- Primary: enable/disable Smart Fader transition assistance.
- In applications such as Serato this can combine channel/crossfader movement with automatic FX/gain treatment.
- Mixxx does not necessarily have a one-control equivalent; do not fake one until the underlying workflow is defined.

### HEADPHONES MIX

- Balance between cue and master in headphone monitoring.

### HEADPHONES LEVEL

- Headphone output level.

### MIC LEVEL

- Microphone level.

### MIC ATT.

- Microphone attenuator; this is hardware-side and should not be treated as an ordinary Mixxx software mixer control.

### Android MONO/STEREO switch

- Selects MONO/STEREO for Android-device audio output in the official mobile hardware diagram.
- This is hardware/connection behavior, not a normal Mixxx MIDI mapping target.

---

## 13. rekordbox-specific behavior worth preserving conceptually

The official rekordbox hardware diagrams are particularly useful because they describe intended DJ workflow rather than raw MIDI.

Key concepts to preserve in our Mixxx implementation:

- Browse encoder = library navigation and focus management.
- Load 1/2 = load the selected track into the corresponding deck.
- Jog platter = scratch/pitch bend; Shift = fast search.
- IN/OUT + jog = precise loop-edge editing.
- CUE/LOOP CALL = cue/loop navigation and loop-size control during playback.
- Beat Sync = sync; long press = master deck; Shift = tempo range.
- Beat FX = channel selection + effect selection + beat subdivision + depth + on/off.
- Channel mixer = trim, EQ, CFX, channel cue and faders.

These are workflow semantics. The MIDI mapping file is responsible for connecting the FLX4 messages to Mixxx ControlObjects/scripts.

---

## 14. Cross-application comparison

### rekordbox for Mac/Windows

The controller is tightly integrated with rekordbox. The hardware diagram documents:
- Browse scroll/focus behavior.
- Load-to-deck behavior and Instant Doubles.
- Jog scratch/pitch bend/search.
- Manual/auto loop workflows.
- Hot Cue / Pad FX / Beat Jump / Sampler mode switching.
- Beat FX channel/effect/beat/depth/on-off control.
- Smart CFX and Smart Fader functionality.

### rekordbox for iOS/Android

The official mobile diagram keeps essentially the same physical philosophy. Beat FX remains channel-select/effect-select/beat/depth/on-off, and the mixer keeps master, cue, trim, EQ, CFX, channel cue, faders, crossfader, headphones and Smart controls. Therefore the FLX4 is not merely a "basic MIDI controller" in mobile rekordbox; the intended workflow is rich enough to use as the primary UI device.

### Serato DJ Lite / Pro

Serato's first-party guide confirms the same physical controls but maps several Shift functions differently. Examples:
- Browse press toggles between crate and track area.
- CUE + Shift loads previous track.
- Smart CFX / Smart Fader can drive preconfigured FX.
- Jog in vinyl mode can control waveform.

This confirms that application semantics should remain separate from the hardware MIDI layer.

### djay

The official Pioneer hardware diagram for djay shows the same Beat FX physical area, but the FX depth knob is used as dry/wet and Smart CFX/Smart Fader have preset-specific semantics. djay is therefore a useful example of how the FLX4 can expose richer FX workflows without changing the physical MIDI protocol.

### Traktor Play

Pioneer's hardware diagram for Traktor Play demonstrates yet another interpretation: some controls can act as Pattern Player, mixer FX, jog touch/vinyl, quantize, etc. This is useful evidence that the controller protocol is intentionally generic while applications assign semantics.

---

## 15. Current Mixxx mapping vs. project target

### Already present upstream / in our baseline

- Core deck transport and Shift state.
- Jog platter / side / touch handling.
- Tempo 14-bit handling.
- Sync, long-press master, tempo range.
- Browser rotate and focus commands.
- Load 1/2.
- Loop controls.
- Pad mode infrastructure and pad mappings.
- Mixer controls.
- Beat FX controls.

### Our Android project should improve or verify

1. **Library UX** — Browse encoder must be a first-class Android Library navigation device.
2. **Browse press behavior** — use native Library focus/open semantics rather than a hard-coded FLX4 special case when feasible.
3. **Jog robustness** — never confuse jog touch with Browse or Library actions.
4. **FX exposure** — inventory actual Mixxx effect ControlObjects and bind the physical Beat FX controls to those controls.
5. **LED/output feedback** — later verify whether Android transport can send output MIDI messages to mirror application state on FLX4 LEDs where the hardware accepts them.
6. **Mapping customization** — retain normal Mixxx mapping architecture so another MIDI controller is not broken by FLX4-specific Android UI changes.

---

## 16. Recommended target mapping for this project

This is a **design proposal**, not yet implemented.

### Library

- BROWSE rotate → selected-track/tree navigation.
- BROWSE press → open/focus Library when the main DJ screen is active; when already in Library, toggle tree/list focus.
- SHIFT+BROWSE rotate → waveform zoom.
- LOAD 1/2 → load selected track to corresponding deck.

### Decks

- PLAY/PAUSE → play/pause.
- SHIFT+PLAY → temporary reverse/censor.
- CUE → cue/back cue.
- SHIFT+CUE → track start.
- Jog platter touch/turn → exact upstream jog semantics.
- SHIFT+jog → fast search.
- Tempo → precise tempo.
- Sync + long press → Sync/master workflow.

### Loops

- IN/OUT → manual loop points and edge editing.
- 4 BEAT/EXIT → 4-beat loop / exit.
- 1/2X / 2X → loop length.
- CUE/LOOP CALL → cue/loop navigation.

### Beat FX

- FX CH SELECT → FX routing/channel.
- FX SELECT → effect selection.
- BEAT down/up → beat division.
- LEVEL/DEPTH → effect parameter/depth.
- ON/OFF → effect enable.

### Mixer

- TRIM → pregain.
- HI/MID/LOW → EQ.
- CFX → filter/color FX.
- CUE → channel monitor.
- Channel faders → channel volume.
- Crossfader → crossfade.
- MASTER → master volume.
- Headphone mix/level → headphone controls.

---

## 17. Safety rules for future changes

1. **Do not modify Android USB MIDI transport while working on mapping.** The known-good transport commit is `ff3be2101cb0b1308be68936e027c5138baf25ee`.
2. **Prefer Mixxx ControlObjects and controller scripts over Android UI hard-coding.**
3. **One functional mapping change per commit/build/test cycle.**
4. **Never combine mapping, effects UI, settings UI and Ableton Link into one change.**
5. **When a test disproves a mapping idea, revert that mapping change rather than layering a second workaround.**
6. **Keep this document updated whenever an experimentally verified FLX4 behavior differs from the documented expectation.**
7. **Use exact MIDI identifiers from the official Pioneer MIDI Message List when adding new controls.**

---

## 18. Primary references

- Pioneer/AlphaTheta DDJ-FLX4 product software information: https://www.pioneerdj.com/en/support/software-information/controller/ddj-flx4/
- Pioneer DDJ-FLX4 official MIDI Message List (English): https://www.pioneerdj.com/-/media/pioneerdj/software-info/controller/ddj-flx4/ddj-flx4_midi_message_list_e1.pdf
- Pioneer DDJ-FLX4 official rekordbox Mac/Windows hardware diagram: https://www.pioneerdj.com/-/media/pioneerdj/software-info/controller/ddj-flx4/ddj-flx4_hardwarediagram_rekordbox_e1.pdf
- Pioneer DDJ-FLX4 official rekordbox iOS/Android hardware diagram: https://www.pioneerdj.com/-/media/pioneerdj/software-info/controller/ddj-flx4/ddj-flx4_hardwarediagram_rekordbox_ios_android_e2.pdf
- Serato DDJ-FLX4 Quickstart Guide: https://support.serato.com/hc/en-us/articles/10173686473231-Pioneer-DJ-DDJ-FLX4-Quickstart-Guide
- Mixxx upstream FLX4 controller mapping: https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-FLX4.midi.xml

---

## 19. Project-specific status ledger

| Area | Status | Notes |
|---|---|---|
| Android MIDI transport | **VERIFIED WORKING** | User-tested FLX4 MIDI input on `ff3be210...` |
| FLX4 audio interface | **VERIFIED WORKING** | User-tested on same baseline |
| Browse navigation | Existing upstream basis | Needs Android UX verification |
| Browse press opens/enters Library | **PLANNED** | Discussed; not implemented in this commit |
| Jog navigation in Library | **PLANNED** | Must not conflict with deck jog touch/turn |
| Beat FX physical mapping | Existing upstream basis | Needs effect inventory + test |
| Android Settings Back/Exit | **PLANNED** | Separate UI task |
| Expanded Android settings | **PLANNED** | Separate preferences/UI task |
| Ableton Link | **PLANNED** | Separate implementation task |

**This file is a reference database, not a request to implement all items above at once.**
