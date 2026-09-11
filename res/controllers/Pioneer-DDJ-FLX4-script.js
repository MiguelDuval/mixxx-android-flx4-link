// Pioneer-DDJ-FLX4-script.js
// ****************************************************************************
// * Mixxx mapping script file for the Pioneer DDJ-FLX4.
// * Mostly adapted from the DDJ-400 mapping script
// * Authors: Warker, nschloe, dj3730, jusko, Robert904
// ****************************************************************************
//
//  Implemented (as per manufacturer's manual):
//      * Mixer Section (Faders, EQ, Filter, Gain, Cue)
//      * Browsing and loading + Waveform zoom (shift)
//      * Jogwheels, Scratching, Bending, Loop adjust
//      * Cycle Temporange
//      * Beat Sync
//      * Hot Cue Mode
//      * Beat Loop Mode
//      * Beat Jump Mode
//      * Sampler Mode
//      * Keyshift mode
//
//  Custom (Mixxx specific mappings):
//      * BeatFX: Assigned Effect Unit 1
//                v FX_SELECT Load next effect.
//                SHIFT + v FX_SELECT Load previous effect.
//                < LEFT Cycle effect focus leftward
//                > RIGHT Cycle effect focus rightward
//                ON/OFF toggles focused effect slot
//                SHIFT + ON/OFF disables all three effect slots.
//
//      * 32 beat jump forward & back (Shift + </> CUE/LOOP CALL arrows)
//      * Toggle quantize (Shift + channel cue)
//      * Stems selection using PADs (using controller's Keyboard mode)
//
//  Not implemented (after discussion and trial attempts):
//      * Loop Section:
//        * -4BEAT auto loop (hacky---prefer a clean way to set a 4 beat loop
//                            from a previous position on long press)
//
//        * CUE/LOOP CALL - memory & delete (complex and not useful. Hot cues are sufficient)
//
//      * Secondary pad modes (trial attempts complex and too experimental)
//        * Keyboard mode
//
//  Implemented in this Android port:
//      * Smart CFX button -> both channel QuickEffectRacks enabled state
//        (the existing CFX knobs continue to drive QuickEffectRack.super1)
//
//  Not implemented yet (but might be in the future):
//      * Smart fader

var PioneerDDJFLX4 = {};

PioneerDDJFLX4.lights = {
    smartCfx: {
        status: 0x96,
        data1: 0x00,
    },
    beatFx: {
        status: 0x94,
        data1: 0x47,
    },
    shiftBeatFx: {
        status: 0x94,
        data1: 0x43,
    },
    deck1: {
        vuMeter: {
            status: 0xB0,
            data1: 0x02,
        },
        playPause: {
            status: 0x90,
            data1: 0x0B,
        },
        shiftPlayPause: {
            status: 0x90,
            data1: 0x47,
        },
        cue: {
            status: 0x90,
            data1: 0x0C,
        },
        shiftCue: {
            status: 0x90,
            data1: 0x48,
        },
        hotcueMode: {
            status: 0x90,
            data1: 0x1B,
        },
        keyboardMode: {
            status: 0x90,
            data1: 0x69,
        },
        padFX1Mode: {
            status: 0x90,
            data1: 0x1E,
        },
        padFX2Mode: {
            status: 0x90,
            data1: 0x6B,
        },
        beatJumpMode: {
            status: 0x90,
            data1: 0x20,
        },
        beatLoopMode: {
            status: 0x90,
            data1: 0x6D,
        },
        samplerMode: {
            status: 0x90,
            data1: 0x22,
        },
        keyShiftMode: {
            status: 0x90,
            data1: 0x6F,
        },
    },
    deck2: {
        vuMeter: {
            status: 0xB0,
            data1: 0x02,
        },
        playPause: {
            status: 0x91,
            data1: 0x0B,
        },
        shiftPlayPause: {
            status: 0x91,
            data1: 0x47,
        },
        cue: {
            status: 0x91,
            data1: 0x0C,
        },
        shiftCue: {
            status: 0x91,
            data1: 0x48,
        },
        hotcueMode: {
            status: 0x91,
            data1: 0x1B,
        },
        keyboardMode: {
            status: 0x91,
            data1: 0x69,
        },
        padFX1Mode: {
            status: 0x91,
            data1: 0x1E,
        },
        padFX2Mode: {
            status: 0x91,
            data1: 0x6B,
        },
        beatJumpMode: {
            status: 0x91,
            data1: 0x20,
        },
        beatLoopMode: {
            status: 0x91,
            data1: 0x6D,
        },
        samplerMode: {
            status: 0x91,
            data1: 0x22,
        },
        keyShiftMode: {
            status: 0x91,
            data1: 0x6F,
        },
    },
};

// Store timer IDs
PioneerDDJFLX4.timers = {};

// Keep alive timer
PioneerDDJFLX4.sendKeepAlive = function() {
    midi.sendSysexMsg([0xF0, 0x00, 0x40, 0x05, 0x00, 0x00, 0x04, 0x05, 0x00, 0x50, 0x02, 0xf7], 12); // This was reverse engineered with Wireshark
};

// Jog wheel constants
PioneerDDJFLX4.vinylMode = true;
PioneerDDJFLX4.alpha = 1.0/8;
PioneerDDJFLX4.beta = PioneerDDJFLX4.alpha/32;

// Multiplier for fast seek through track using SHIFT+JOGWHEEL
PioneerDDJFLX4.fastSeekScale = 150;
PioneerDDJFLX4.bendScale = 0.8;

PioneerDDJFLX4.tempoRanges = [0.06, 0.10, 0.16, 0.25];

PioneerDDJFLX4.shiftButtonDown = [false, false];

// Smart CFX is a global hardware mode; both deck QuickEffectRacks follow it.
PioneerDDJFLX4.smartCfxEnabled = false;
PioneerDDJFLX4.smartCfxFilterPreset = [-1, -1];

// Pad FX uses the dedicated EffectUnit 2/3 per deck. Mixxx exposes three
// effect slots per EffectUnit, so the eight physical pads are treated as an
// eight-effect trigger bank with a three-slot active pool. Pad FX1 addresses
// effects 1-8; Pad FX2 addresses effects 9-16 (wrapping to the installed list).
PioneerDDJFLX4.padFx = {
    units: [
        "[EffectRack1_EffectUnit2]",
        "[EffectRack1_EffectUnit3]"
    ],
    slots: [[], []],
    sequence: [0, 0],
};

// Jog wheel loop adjust
PioneerDDJFLX4.loopAdjustIn = [false, false];
PioneerDDJFLX4.loopAdjustOut = [false, false];
PioneerDDJFLX4.loopAdjustMultiply = 50;

// Beatjump pad (beatjump_size values)
PioneerDDJFLX4.beatjumpSizeForPad = {
    0x20: -1, // PAD 1
    0x21: 1,  // PAD 2
    0x22: -2, // PAD 3
    0x23: 2,  // PAD 4
    0x24: -4, // PAD 5
    0x25: 4,  // PAD 6
    0x26: -8, // PAD 7
    0x27: 8   // PAD 8
};

// Stems (KEYBOARD) pads mode status for deck 1 and 2, without or with SHIFT pressed
PioneerDDJFLX4.stemsPadsModesStatus = {
    "[Channel1]": [0x97, 0x98],
    "[Channel2]": [0x99, 0x9a],
};

// Stems (KEYBOARD) pad 1 control (pad control = [this value] + [pad  number] - 1)
PioneerDDJFLX4.stemMutePadsFirstControl = 0x40;

// Stems (KEYBOARD) pad 5 control (pad control = [this value] + [pad  number] - 1)
PioneerDDJFLX4.stemFxPadsFirstControl = 0x44;

// Pitch shift (KEY SHIFT) pads mode status for deck 1 and 2, without or with SHIFT pressed
PioneerDDJFLX4.pitchPadsModesStatus = {
    "[Channel1]": [0x97, 0x98],
    "[Channel2]": [0x99, 0x9a],
};

// Pitch shift (KEY SHIFT) pad 1 control (pad control = [this value] + [pad  number] - 1)
PioneerDDJFLX4.pitchPadsFirstControl = 0x70;

PioneerDDJFLX4.quickJumpSize = 32;

// Used for tempo slider
PioneerDDJFLX4.highResMSB = {
    "[Channel1]": {},
    "[Channel2]": {}
};

PioneerDDJFLX4.trackLoadedLED = function(value, group, _control) {
    midi.sendShortMsg(
        0x9F,
        group.match(script.channelRegEx)[1] - 1,
        value > 0 ? 0x7F : 0x00
    );
};

PioneerDDJFLX4.toggleLight = function(midiIn, active) {
    midi.sendShortMsg(midiIn.status, midiIn.data1, active ? 0x7F : 0);
};

//
// Init
//

PioneerDDJFLX4.init = function() {
    engine.setValue("[EffectRack1_EffectUnit1]", "show_focus", 1);
    PioneerDDJFLX4.initializeSmartCfx();
    PioneerDDJFLX4.initializeBeatFx();
    PioneerDDJFLX4.initializePadFx();

    engine.makeConnection("[Channel1]", "vu_meter", PioneerDDJFLX4.vuMeterUpdate);
    engine.makeConnection("[Channel2]", "vu_meter", PioneerDDJFLX4.vuMeterUpdate);

    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.deck1.vuMeter, false);
    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.deck2.vuMeter, false);

    engine.softTakeover("[Channel1]", "rate", true);
    engine.softTakeover("[Channel2]", "rate", true);
    engine.softTakeover("[EffectRack1_EffectUnit1_Effect1]", "meta", true);
    engine.softTakeover("[EffectRack1_EffectUnit1_Effect2]", "meta", true);
    engine.softTakeover("[EffectRack1_EffectUnit1_Effect3]", "meta", true);
    engine.softTakeover("[EffectRack1_EffectUnit1]", "mix", true);

    const samplerCount = 16;
    if (engine.getValue("[App]", "num_samplers") < samplerCount) {
        engine.setValue("[App]", "num_samplers", samplerCount);
    }
    for (let i = 1; i <= samplerCount; ++i) {
        engine.makeConnection("[Sampler" + i + "]", "play", PioneerDDJFLX4.samplerPlayOutputCallbackFunction);
    }

    engine.makeConnection("[Channel1]", "track_loaded", PioneerDDJFLX4.trackLoadedLED);
    engine.makeConnection("[Channel2]", "track_loaded", PioneerDDJFLX4.trackLoadedLED);

    // play the "track loaded" animation on both decks at startup
    midi.sendShortMsg(0x9F, 0x00, 0x7F);
    midi.sendShortMsg(0x9F, 0x01, 0x7F);

    PioneerDDJFLX4.setLoopButtonLights(0x90, 0x7F);
    PioneerDDJFLX4.setLoopButtonLights(0x91, 0x7F);

    engine.makeConnection("[Channel1]", "loop_enabled", PioneerDDJFLX4.loopToggle);
    engine.makeConnection("[Channel2]", "loop_enabled", PioneerDDJFLX4.loopToggle);

    for (i = 1; i <= 3; i++) {
        engine.makeConnection("[EffectRack1_EffectUnit1_Effect" + i +"]", "enabled", PioneerDDJFLX4.toggleFxLight);
    }
    engine.makeConnection("[EffectRack1_EffectUnit1]", "focused_effect", PioneerDDJFLX4.toggleFxLight);

    // Smart CFX uses the existing per-deck QuickEffectRacks. Keep the hardware
    // button LED synchronized with the effective state of both channels.
    engine.makeConnection("[QuickEffectRack1_[Channel1]]", "enabled", PioneerDDJFLX4.updateSmartCfxLight);
    engine.makeConnection("[QuickEffectRack1_[Channel2]]", "enabled", PioneerDDJFLX4.updateSmartCfxLight);
    PioneerDDJFLX4.updateSmartCfxLight();

    // Register callbacks for each deck, when a file is loaded and the number of stems is available
    engine.makeConnection("[Channel1]", "stem_count", PioneerDDJFLX4.stemCountChanged);
    engine.makeConnection("[Channel2]", "stem_count", PioneerDDJFLX4.stemCountChanged);

    // Register callbacks for each stems of each decks, to change pad lights when muted/unmuted/FX
    for (let stem=1; stem<=4; stem++) {
        for (let deck=1; deck<=2; deck++) {
            engine.makeConnection(`[Channel${deck}_Stem${stem}]`, "mute", PioneerDDJFLX4.stemMuteChanged);
            engine.makeConnection(`[QuickEffectRack1_[Channel${deck}_Stem${stem}]]`, "enabled", PioneerDDJFLX4.stemFxChanged);
        }
    }

    // Register callbacks for each deck, when a file is loaded to reset pitch shift
    engine.makeConnection("[Channel1]", "track_loaded", PioneerDDJFLX4.pitchAdjusted);
    engine.makeConnection("[Channel2]", "track_loaded", PioneerDDJFLX4.pitchAdjusted);

    // Register callbacks for each deck, when the pitch shift is modified
    engine.makeConnection("[Channel1]", "pitch_adjust", PioneerDDJFLX4.pitchAdjusted);
    engine.makeConnection("[Channel2]", "pitch_adjust", PioneerDDJFLX4.pitchAdjusted);

    PioneerDDJFLX4.keepAliveTimer = engine.beginTimer(200, PioneerDDJFLX4.sendKeepAlive);

    // query the controller for current control positions on startup
    PioneerDDJFLX4.sendKeepAlive(); // the query seems to double as a keep alive message
};

//
// Waveform zoom
//

PioneerDDJFLX4.waveformZoom = function(midichan, control, value, status, group) {
    if (value === 0x7f) {
        script.triggerControl(group, "waveform_zoom_up", 100);
    } else {
        script.triggerControl(group, "waveform_zoom_down", 100);
    }
};

//
// Channel level lights
//

PioneerDDJFLX4.vuMeterUpdate = function(value, group) {
    const newVal = value * 127;

    switch (group) {
    case "[Channel1]":
        midi.sendShortMsg(0xB0, 0x02, newVal);
        break;

    case "[Channel2]":
        midi.sendShortMsg(0xB1, 0x02, newVal);
        break;
    }
};

//
// Effects
//

PioneerDDJFLX4.getBeatFxUnit = function() {
    return "[EffectRack1_EffectUnit1]";
};

PioneerDDJFLX4.ensureBeatFxFocus = function() {
    const unit = PioneerDDJFLX4.getBeatFxUnit();
    let focusedEffect = Math.floor(engine.getValue(unit, "focused_effect"));

    if (focusedEffect < 1) {
        focusedEffect = 1;
        engine.setValue(unit, "focused_effect", focusedEffect);
    }

    return focusedEffect;
};

PioneerDDJFLX4.focusedFxGroup = function() {
    return PioneerDDJFLX4.getBeatFxUnit() + "_Effect" + PioneerDDJFLX4.ensureBeatFxFocus();
};

PioneerDDJFLX4.ensureFocusedBeatFxLoaded = function() {
    const group = PioneerDDJFLX4.focusedFxGroup();
    if (engine.getValue(group, "loaded_effect") <= 0) {
        engine.setValue(group, "next_effect", 1);
    }
    return group;
};

PioneerDDJFLX4.initializeBeatFx = function() {
    const unit = PioneerDDJFLX4.getBeatFxUnit();
    PioneerDDJFLX4.ensureBeatFxFocus();
    PioneerDDJFLX4.ensureFocusedBeatFxLoaded();

    for (let i = 1; i <= 3; i++) {
        const group = `${unit}_Effect${i}`;
        engine.softTakeover(group, "meta", true);
    }
    engine.softTakeover(unit, "mix", true);
};

PioneerDDJFLX4.toggleFxLight = function(_value, _group, _control) {
    const enabled = engine.getValue(PioneerDDJFLX4.focusedFxGroup(), "enabled") > 0;

    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.beatFx, enabled);
    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.shiftBeatFx, enabled);
};

PioneerDDJFLX4.beatFxLevelDepthRotate = function(_channel, _control, value) {
    const normalized = Math.max(0, Math.min(1, value / 0x7F));
    const focusedGroup = PioneerDDJFLX4.ensureFocusedBeatFxLoaded();
    const unit = PioneerDDJFLX4.getBeatFxUnit();

    if (PioneerDDJFLX4.shiftButtonDown[0] || PioneerDDJFLX4.shiftButtonDown[1]) {
        engine.softTakeoverIgnoreNextValue(unit, "mix");
        engine.setValue(focusedGroup, "meta", normalized);
    } else {
        engine.softTakeoverIgnoreNextValue(focusedGroup, "meta");
        engine.setValue(unit, "mix", normalized);
    }
};

PioneerDDJFLX4.changeFocusedEffectBy = function(numberOfSteps) {
    const unit = PioneerDDJFLX4.getBeatFxUnit();
    let focusedEffect = PioneerDDJFLX4.ensureBeatFxFocus() - 1;
    const numberOfEffectSlots = Math.max(1, Math.floor(engine.getValue(unit, "num_effectslots")) || 3);

    focusedEffect = (((focusedEffect + numberOfSteps) % numberOfEffectSlots) + numberOfEffectSlots) % numberOfEffectSlots;
    focusedEffect += 1;

    engine.setValue(unit, "focused_effect", focusedEffect);
    PioneerDDJFLX4.ensureFocusedBeatFxLoaded();
};

PioneerDDJFLX4.beatFxSelectPressed = function(_channel, _control, value) {
    if (value === 0) { return; }

    PioneerDDJFLX4.ensureFocusedBeatFxLoaded();
    engine.setValue(PioneerDDJFLX4.focusedFxGroup(), "next_effect", 1);
};

PioneerDDJFLX4.beatFxSelectShiftPressed = function(_channel, _control, value) {
    if (value === 0) { return; }

    PioneerDDJFLX4.ensureFocusedBeatFxLoaded();
    engine.setValue(PioneerDDJFLX4.focusedFxGroup(), "prev_effect", 1);
};

PioneerDDJFLX4.beatFxLeftPressed = function(_channel, _control, value) {
    if (value === 0) { return; }

    PioneerDDJFLX4.changeFocusedEffectBy(-1);
};

PioneerDDJFLX4.beatFxRightPressed = function(_channel, _control, value) {
    if (value === 0) { return; }

    PioneerDDJFLX4.changeFocusedEffectBy(1);
};

PioneerDDJFLX4.beatFxOnOffPressed = function(_channel, _control, value) {
    if (value === 0) { return; }

    const group = PioneerDDJFLX4.ensureFocusedBeatFxLoaded();
    const unit = PioneerDDJFLX4.getBeatFxUnit();
    const currentlyEnabled = engine.getValue(group, "enabled") > 0;

    engine.setValue(group, "enabled", currentlyEnabled ? 0 : 1);

    if (!currentlyEnabled && engine.getValue(unit, "mix") <= 0) {
        engine.setValue(unit, "mix", 1);
        engine.softTakeoverIgnoreNextValue(unit, "mix");
    }
};

PioneerDDJFLX4.beatFxOnOffShiftPressed = function(_channel, _control, value) {
    if (value === 0) { return; }

    const unit = PioneerDDJFLX4.getBeatFxUnit();

    for (let i = 1; i <= 3; i++) {
        engine.setValue(`${unit}_Effect${i}`, "enabled", 0);
    }
    engine.setValue(unit, "mix", 0);
    engine.softTakeoverIgnoreNextValue(unit, "mix");

    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.beatFx, false);
    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.shiftBeatFx, false);
};

PioneerDDJFLX4.beatFxChannel1 = function(_channel, _control, value, _status, group) {
    engine.setValue(group, "group_[Channel1]_enable", value === 0x7f ? 1 : 0);
};

PioneerDDJFLX4.beatFxChannel2 = function(_channel, _control, value, _status, group) {
    engine.setValue(group, "group_[Channel2]_enable", value === 0x7f ? 1 : 0);
};

//
// Smart CFX
//
// Quick Effects expose their current chain preset through loaded_chain_preset.
// We keep the normal filter preset as the OFF state and cycle real Quick Effect
// chain presets while SMART CFX is active.

PioneerDDJFLX4.initializeSmartCfx = function() {
    for (let deck = 0; deck < 2; deck++) {
        const group = `[QuickEffectRack1_[Channel${deck + 1}]]`;
        let preset = Math.floor(engine.getValue(group, "loaded_chain_preset"));

        if (preset <= 0) {
            engine.setValue(group, "next_chain_preset", 1);
            preset = Math.floor(engine.getValue(group, "loaded_chain_preset"));
        }

        PioneerDDJFLX4.smartCfxFilterPreset[deck] = preset;
        engine.setValue(group, "enabled", 1);
        engine.setValue(group, "super1", 0.5);
    }

    PioneerDDJFLX4.smartCfxEnabled = false;
    PioneerDDJFLX4.updateSmartCfxLight();
};

PioneerDDJFLX4.setQuickEffectPreset = function(group, targetPreset) {
    let current = Math.floor(engine.getValue(group, "loaded_chain_preset"));
    const count = Math.floor(engine.getValue(group, "num_chain_presets"));

    if (count <= 1 || targetPreset < 0) {
        return;
    }

    if (current < 0) {
        current = 0;
    }

    targetPreset = targetPreset % count;
    let guard = count + 1;

    while (current !== targetPreset && guard-- > 0) {
        const distance = (targetPreset - current + count) % count;
        const forward = distance <= count / 2;
        engine.setValue(group, forward ? "next_chain_preset" : "prev_chain_preset", 1);
        current = Math.floor(engine.getValue(group, "loaded_chain_preset"));
    }
};

PioneerDDJFLX4.cycleSmartCfxPreset = function() {
    for (let deck = 0; deck < 2; deck++) {
        const group = `[QuickEffectRack1_[Channel${deck + 1}]]`;
        const count = Math.floor(engine.getValue(group, "num_chain_presets"));
        const current = Math.floor(engine.getValue(group, "loaded_chain_preset"));
        if (count > 1 && current >= 0) {
            const next = (current + 1) % count;
            const target = next === 0 ? 1 : next;
            PioneerDDJFLX4.setQuickEffectPreset(group, target);
        }
        engine.setValue(group, "enabled", 1);
        engine.setValue(group, "super1", 0.5);
    }
};

PioneerDDJFLX4.restoreSmartCfxFilter = function() {
    for (let deck = 0; deck < 2; deck++) {
        const group = `[QuickEffectRack1_[Channel${deck + 1}]]`;
        PioneerDDJFLX4.setQuickEffectPreset(group, PioneerDDJFLX4.smartCfxFilterPreset[deck]);
        engine.setValue(group, "enabled", 1);
    }
};

PioneerDDJFLX4.updateSmartCfxLight = function() {
    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.smartCfx, PioneerDDJFLX4.smartCfxEnabled);
};

PioneerDDJFLX4.smartCfxPressed = function(_channel, _control, value) {
    if (value === 0) {
        return;
    }

    const shifted = PioneerDDJFLX4.shiftButtonDown[0] || PioneerDDJFLX4.shiftButtonDown[1];

    if (shifted) {
        if (!PioneerDDJFLX4.smartCfxEnabled) {
            PioneerDDJFLX4.smartCfxEnabled = true;
        }
        PioneerDDJFLX4.cycleSmartCfxPreset();
    } else if (PioneerDDJFLX4.smartCfxEnabled) {
        PioneerDDJFLX4.smartCfxEnabled = false;
        PioneerDDJFLX4.restoreSmartCfxFilter();
    } else {
        PioneerDDJFLX4.smartCfxEnabled = true;
        PioneerDDJFLX4.cycleSmartCfxPreset();
    }

    PioneerDDJFLX4.updateSmartCfxLight();
};

//
// Loop IN/OUT ADJUST
//

PioneerDDJFLX4.toggleLoopAdjustIn = function(channel, _control, value, _status, group) {
    if (value === 0 || engine.getValue(group, "loop_enabled" === 0)) {
        return;
    }
    PioneerDDJFLX4.loopAdjustIn[channel] = !PioneerDDJFLX4.loopAdjustIn[channel];
    PioneerDDJFLX4.loopAdjustOut[channel] = false;
};

PioneerDDJFLX4.toggleLoopAdjustOut = function(channel, _control, value, _status, group) {
    if (value === 0 || engine.getValue(group, "loop_enabled" === 0)) {
        return;
    }
    PioneerDDJFLX4.loopAdjustOut[channel] = !PioneerDDJFLX4.loopAdjustOut[channel];
    PioneerDDJFLX4.loopAdjustIn[channel] = false;
};

// Two signals are sent here so that the light stays lit/unlit in its shift state too
PioneerDDJFLX4.setReloopLight = function(status, value) {
    midi.sendShortMsg(status, 0x4D, value);
    midi.sendShortMsg(status, 0x50, value);
};


PioneerDDJFLX4.setLoopButtonLights = function(status, value) {
    [0x10, 0x11, 0x4E, 0x4C].forEach(function(control) {
        midi.sendShortMsg(status, control, value);
    });
};

PioneerDDJFLX4.startLoopLightsBlink = function(channel, control, status, group) {
    let blink = 0x7F;

    PioneerDDJFLX4.stopLoopLightsBlink(group, control, status);

    PioneerDDJFLX4.timers[group][control] = engine.beginTimer(500, () => {
        blink = 0x7F - blink;

        // When adjusting the loop out position, turn the loop in light off
        if (PioneerDDJFLX4.loopAdjustOut[channel]) {
            midi.sendShortMsg(status, 0x10, 0x00);
            midi.sendShortMsg(status, 0x4C, 0x00);
        } else {
            midi.sendShortMsg(status, 0x10, blink);
            midi.sendShortMsg(status, 0x4C, blink);
        }

        // When adjusting the loop in position, turn the loop out light off
        if (PioneerDDJFLX4.loopAdjustIn[channel]) {
            midi.sendShortMsg(status, 0x11, 0x00);
            midi.sendShortMsg(status, 0x4E, 0x00);
        } else {
            midi.sendShortMsg(status, 0x11, blink);
            midi.sendShortMsg(status, 0x4E, blink);
        }
    });

};

PioneerDDJFLX4.stopLoopLightsBlink = function(group, control, status) {
    PioneerDDJFLX4.timers[group] = PioneerDDJFLX4.timers[group] || {};

    if (PioneerDDJFLX4.timers[group][control] !== undefined) {
        engine.stopTimer(PioneerDDJFLX4.timers[group][control]);
    }
    PioneerDDJFLX4.timers[group][control] = undefined;
    PioneerDDJFLX4.setLoopButtonLights(status, 0x7F);
};

PioneerDDJFLX4.loopToggle = function(value, group, control) {
    const status = group === "[Channel1]" ? 0x90 : 0x91,
        channel = group === "[Channel1]" ? 0 : 1;

    PioneerDDJFLX4.setReloopLight(status, value ? 0x7F : 0x00);

    if (value) {
        PioneerDDJFLX4.startLoopLightsBlink(channel, control, status, group);
    } else {
        PioneerDDJFLX4.stopLoopLightsBlink(group, control, status);
        PioneerDDJFLX4.loopAdjustIn[channel] = false;
        PioneerDDJFLX4.loopAdjustOut[channel] = false;
    }
};

//
// CUE/LOOP CALL
//

PioneerDDJFLX4.cueLoopCallLeft = function(_channel, _control, value, _status, group) {
    if (value) {
        engine.setValue(group, "loop_scale", 0.5);
    }
};

PioneerDDJFLX4.cueLoopCallRight = function(_channel, _control, value, _status, group) {
    if (value) {
        engine.setValue(group, "loop_scale", 2.0);
    }
};

//
// BEAT SYNC
//
// Note that the controller sends different signals for a short press and a long
// press of the same button.
//

PioneerDDJFLX4.syncPressed = function(channel, control, value, status, group) {
    if (engine.getValue(group, "sync_enabled") && value > 0) {
        engine.setValue(group, "sync_enabled", 0);
    } else {
        engine.setValue(group, "beatsync", value);
    }
};

PioneerDDJFLX4.syncLongPressed = function(channel, control, value, status, group) {
    if (value) {
        engine.setValue(group, "sync_enabled", 1);
    }
};

PioneerDDJFLX4.cycleTempoRange = function(_channel, _control, value, _status, group) {
    if (value === 0) { return; } // ignore release

    const currRange = engine.getValue(group, "rateRange");
    let idx = 0;

    for (let i = 0; i < this.tempoRanges.length; i++) {
        if (currRange === this.tempoRanges[i]) {
            // idx get the index of the value in tempoRanges following the currently configured one
            // or cycle back to 0 if the current is the last value of the list.
            idx = (i + 1) % this.tempoRanges.length;
            break;
        }
    }
    engine.setValue(group, "rateRange", this.tempoRanges[idx]);
};

//
// Jog wheels
//

PioneerDDJFLX4.jogTurn = function(channel, _control, value, _status, group) {
    const deckNum = channel + 1;
    // wheel center at 64; <64 rew >64 fwd
    let newVal = value - 64;

    // loop_in / out adjust
    const loopEnabled = engine.getValue(group, "loop_enabled");
    if (loopEnabled > 0) {
        if (PioneerDDJFLX4.loopAdjustIn[channel]) {
            newVal = newVal * PioneerDDJFLX4.loopAdjustMultiply + engine.getValue(group, "loop_start_position");
            engine.setValue(group, "loop_start_position", newVal);
            return;
        }
        if (PioneerDDJFLX4.loopAdjustOut[channel]) {
            newVal = newVal * PioneerDDJFLX4.loopAdjustMultiply + engine.getValue(group, "loop_end_position");
            engine.setValue(group, "loop_end_position", newVal);
            return;
        }
    }

    if (engine.isScratching(deckNum)) {
        engine.scratchTick(deckNum, newVal);
    } else { // fallback
        engine.setValue(group, "jog", newVal * this.bendScale);
    }
};


PioneerDDJFLX4.jogSearch = function(_channel, _control, value, _status, group) {
    const newVal = (value - 64) * PioneerDDJFLX4.fastSeekScale;
    engine.setValue(group, "jog", newVal);
};

PioneerDDJFLX4.jogTouch = function(channel, _control, value) {
    const deckNum = channel + 1;

    // skip while adjusting the loop points
    if (PioneerDDJFLX4.loopAdjustIn[channel] || PioneerDDJFLX4.loopAdjustOut[channel]) {
        return;
    }

    if (value !== 0 && this.vinylMode) {
        engine.scratchEnable(deckNum, 720, 33+1/3, this.alpha, this.beta);
    } else {
        engine.scratchDisable(deckNum);
    }
};

//
// Shift button
//

PioneerDDJFLX4.shiftPressed = function(channel, _control, value, _status, _group) {
    PioneerDDJFLX4.shiftButtonDown[channel] = value === 0x7F;
};


//
// Tempo sliders
//
// The tempo option in Mixxx's deck preferences determine whether down/up
// increases/decreases the rate. Therefore it must be inverted here so that the
// UI and the control sliders always move in the same direction.
//

PioneerDDJFLX4.tempoSliderMSB = function(channel, control, value, status, group) {
    PioneerDDJFLX4.highResMSB[group].tempoSlider = value;
};

PioneerDDJFLX4.tempoSliderLSB = function(channel, control, value, status, group) {
    const fullValue = (PioneerDDJFLX4.highResMSB[group].tempoSlider << 7) + value;

    engine.setValue(
        group,
        "rate",
        1 - (fullValue / 0x2000)
    );
};

//
// Beat Jump mode
//
// Note that when we increase/decrease the sizes on the pad buttons, we use the
// value of the first pad (0x21) as an upper/lower limit beyond which we don't
// allow further increasing/decreasing of all the values.
//

PioneerDDJFLX4.beatjumpPadPressed = function(_channel, control, value, _status, group) {
    if (value === 0) {
        return;
    }
    engine.setValue(group, "beatjump_size", Math.abs(PioneerDDJFLX4.beatjumpSizeForPad[control]));
    engine.setValue(group, "beatjump", PioneerDDJFLX4.beatjumpSizeForPad[control]);
};

PioneerDDJFLX4.increaseBeatjumpSizes = function(_channel, control, value, _status, group) {
    if (value === 0 || PioneerDDJFLX4.beatjumpSizeForPad[0x21] * 16 > 16) {
        return;
    }
    Object.keys(PioneerDDJFLX4.beatjumpSizeForPad).forEach(function(pad) {
        PioneerDDJFLX4.beatjumpSizeForPad[pad] = PioneerDDJFLX4.beatjumpSizeForPad[pad] * 16;
    });
    engine.setValue(group, "beatjump_size", PioneerDDJFLX4.beatjumpSizeForPad[0x21]);
};

PioneerDDJFLX4.decreaseBeatjumpSizes = function(_channel, control, value, _status, group) {
    if (value === 0 || PioneerDDJFLX4.beatjumpSizeForPad[0x21] / 16 < 1/16) {
        return;
    }
    Object.keys(PioneerDDJFLX4.beatjumpSizeForPad).forEach(function(pad) {
        PioneerDDJFLX4.beatjumpSizeForPad[pad] = PioneerDDJFLX4.beatjumpSizeForPad[pad] / 16;
    });
    engine.setValue(group, "beatjump_size", PioneerDDJFLX4.beatjumpSizeForPad[0x21]);
};

//
// Sampler mode
//

PioneerDDJFLX4.samplerPlayOutputCallbackFunction = function(value, group, _control) {
    if (value === 1) {
        const curPad = group.match(script.samplerRegEx)[1];
        let deckIndex = 0;
        let padIndex = 0;

        if (curPad >=1 && curPad <= 4) {
            deckIndex = 0;
            padIndex = curPad - 1;
        } else if (curPad >=5 && curPad <= 8) {
            deckIndex = 2;
            padIndex = curPad - 5;
        } else if (curPad >=9 && curPad <= 12) {
            deckIndex = 0;
            padIndex = curPad - 5;
        } else if (curPad >=13 && curPad <= 16) {
            deckIndex = 2;
            padIndex = curPad - 9;
        }

        PioneerDDJFLX4.startSamplerBlink(
            0x97 + deckIndex,
            0x30 + padIndex,
            group);
    }
};

PioneerDDJFLX4.setPadModeLight = function(deck, modeControl) {
    const modes = [
        deck.hotcueMode,
        deck.keyboardMode,
        deck.padFX1Mode,
        deck.padFX2Mode,
        deck.beatJumpMode,
        deck.beatLoopMode,
        deck.samplerMode,
        deck.keyShiftMode,
    ];

    modes.forEach(function(light) {
        PioneerDDJFLX4.toggleLight(light, false);
    });

    switch (modeControl) {
    case 0x1B: PioneerDDJFLX4.toggleLight(deck.hotcueMode, true); break;
    case 0x69: PioneerDDJFLX4.toggleLight(deck.keyboardMode, true); break;
    case 0x1E: PioneerDDJFLX4.toggleLight(deck.padFX1Mode, true); break;
    case 0x6B: PioneerDDJFLX4.toggleLight(deck.padFX2Mode, true); break;
    case 0x20: PioneerDDJFLX4.toggleLight(deck.beatJumpMode, true); break;
    case 0x6D: PioneerDDJFLX4.toggleLight(deck.beatLoopMode, true); break;
    case 0x22: PioneerDDJFLX4.toggleLight(deck.samplerMode, true); break;
    case 0x6F: PioneerDDJFLX4.toggleLight(deck.keyShiftMode, true); break;
    }
};

PioneerDDJFLX4.padModeKeyPressed = function(_channel, _control, value, _status, _group) {
    if (value === 0) {
        return;
    }

    const deck = (_status === 0x90 ? PioneerDDJFLX4.lights.deck1 : PioneerDDJFLX4.lights.deck2);
    PioneerDDJFLX4.setPadModeLight(deck, _control);
};

PioneerDDJFLX4.initializePadFx = function() {
    for (let deckIndex = 0; deckIndex < 2; deckIndex++) {
        const unit = PioneerDDJFLX4.padFx.units[deckIndex];
        const channel = `[Channel${deckIndex + 1}]`;
        const otherChannel = `[Channel${deckIndex === 0 ? 2 : 1}]`;

        engine.setValue(unit, "show_focus", 1);
        engine.setValue(unit, "group_" + channel + "_enable", 1);
        engine.setValue(unit, "group_" + otherChannel + "_enable", 0);
        engine.setParameter(unit, "mix", 0);

        for (let slot = 1; slot <= 3; slot++) {
            engine.setValue(`${unit}_Effect${slot}`, "enabled", 0);
        }
    }
};

PioneerDDJFLX4.padFxPadStatus = function(deckIndex, mode, pad) {
    return `${mode}:${pad}:${deckIndex}`;
};

PioneerDDJFLX4.padFxLight = function(deckIndex, pad, active) {
    const statusPair = deckIndex === 0 ? [0x97, 0x98] : [0x99, 0x9A];
    statusPair.forEach(function(status) {
        midi.sendShortMsg(status, 0x10 + pad, active ? 0x7F : 0x00);
    });
};

PioneerDDJFLX4.findPadFxSlot = function(deckIndex, key) {
    return PioneerDDJFLX4.padFx.slots[deckIndex].findIndex(function(slot) {
        return slot && slot.key === key;
    });
};

PioneerDDJFLX4.findFreePadFxSlot = function(deckIndex) {
    const slots = PioneerDDJFLX4.padFx.slots[deckIndex];
    for (let slot = 0; slot < 3; slot++) {
        if (!slots[slot]) {
            return slot;
        }
    }
    return -1;
};

PioneerDDJFLX4.findOldestPadFxSlot = function(deckIndex) {
    const slots = PioneerDDJFLX4.padFx.slots[deckIndex];
    let oldestIndex = -1;
    let oldestSequence = Number.POSITIVE_INFINITY;

    slots.forEach(function(slot, index) {
        if (slot && slot.sequence < oldestSequence) {
            oldestSequence = slot.sequence;
            oldestIndex = index;
        }
    });

    return oldestIndex;
};

PioneerDDJFLX4.releasePadFxSlot = function(deckIndex, slotIndex) {
    const slotState = PioneerDDJFLX4.padFx.slots[deckIndex][slotIndex];
    if (!slotState) {
        return;
    }

    const unit = PioneerDDJFLX4.padFx.units[deckIndex];
    engine.setValue(`${unit}_Effect${slotIndex + 1}`, "enabled", 0);
    PioneerDDJFLX4.padFxLight(deckIndex, slotState.pad, false);
    PioneerDDJFLX4.padFx.slots[deckIndex][slotIndex] = null;

    const stillActive = PioneerDDJFLX4.padFx.slots[deckIndex].some(Boolean);
    if (!stillActive) {
        engine.setParameter(unit, "mix", 0);
    }
};

PioneerDDJFLX4.loadPadFxEffect = function(deckIndex, slotIndex, targetEffect) {
    const unit = PioneerDDJFLX4.padFx.units[deckIndex];
    const slotGroup = `${unit}_Effect${slotIndex + 1}`;
    const available = Math.floor(engine.getValue("[Master]", "num_effectsavailable"));

    if (available <= 1) {
        return false;
    }

    const usableEffects = available - 1; // index 0 is the empty/pass-through entry
    const target = (targetEffect % usableEffects) + 1;
    let current = Math.floor(engine.getValue(slotGroup, "loaded_effect"));

    if (current < 0 || current >= available) {
        current = 0;
    }

    let steps = (target - current + available) % available;
    while (steps-- > 0) {
        engine.setValue(slotGroup, "next_effect", 1);
    }

    engine.setValue(slotGroup, "enabled", 1);
    engine.setParameter(unit, "mix", 1);
    return true;
};

PioneerDDJFLX4.padFxPadPressed = function(_channel, control, value, status, group) {
    const deckIndex = group === "[Channel1]" ? 0 : 1;
    const mode = (status === 0x97 || status === 0x99) ? 0 : 1;
    const pad = control - 0x10;

    if (pad < 0 || pad > 7) {
        return;
    }

    const key = PioneerDDJFLX4.padFxPadStatus(deckIndex, mode, pad);
    const existingSlot = PioneerDDJFLX4.findPadFxSlot(deckIndex, key);

    if (value === 0x00) {
        if (existingSlot >= 0) {
            PioneerDDJFLX4.releasePadFxSlot(deckIndex, existingSlot);
        }
        return;
    }

    if (existingSlot >= 0) {
        return;
    }

    let slotIndex = PioneerDDJFLX4.findFreePadFxSlot(deckIndex);

    if (slotIndex < 0) {
        // The physical controller offers eight triggers, while Mixxx supplies
        // three effect slots. Recycle the least-recently pressed active slot
        // rather than silently doing nothing when a fourth pad is pressed.
        slotIndex = PioneerDDJFLX4.findOldestPadFxSlot(deckIndex);
        if (slotIndex >= 0) {
            PioneerDDJFLX4.releasePadFxSlot(deckIndex, slotIndex);
        }
    }

    const effectBankOffset = mode * 8;
    if (!PioneerDDJFLX4.loadPadFxEffect(deckIndex, slotIndex, effectBankOffset + pad)) {
        return;
    }

    PioneerDDJFLX4.padFx.sequence[deckIndex] += 1;
    PioneerDDJFLX4.padFx.slots[deckIndex][slotIndex] = {
        key: key,
        pad: pad,
        mode: mode,
        sequence: PioneerDDJFLX4.padFx.sequence[deckIndex],
    };
    PioneerDDJFLX4.padFxLight(deckIndex, pad, true);
};

PioneerDDJFLX4.samplerPadPressed = function(_channel, _control, value, _status, group) {
    if (engine.getValue(group, "track_loaded")) {
        engine.setValue(group, "cue_gotoandplay", value);
    } else {
        engine.setValue(group, "LoadSelectedTrack", value);
    }
};

PioneerDDJFLX4.samplerPadShiftPressed = function(_channel, _control, value, _status, group) {
    if (engine.getValue(group, "play")) {
        engine.setValue(group, "cue_gotoandstop", value);
    } else if (engine.getValue(group, "track_loaded")) {
        engine.setValue(group, "eject", value);
    }
};

PioneerDDJFLX4.startSamplerBlink = function(channel, control, group) {
    let val = 0x7f;

    PioneerDDJFLX4.stopSamplerBlink(channel, control);
    PioneerDDJFLX4.timers[channel][control] = engine.beginTimer(250, () => {
        val = 0x7f - val;

        // blink the appropriate pad
        midi.sendShortMsg(channel, control, val);
        // also blink the pad while SHIFT is pressed
        midi.sendShortMsg((channel+1), control, val);

        const isPlaying = engine.getValue(group, "play") === 1;

        if (!isPlaying) {
            // kill timer
            PioneerDDJFLX4.stopSamplerBlink(channel, control);
            // set the pad LED to ON
            midi.sendShortMsg(channel, control, 0x7f);
            // set the pad LED to ON while SHIFT is pressed
            midi.sendShortMsg((channel+1), control, 0x7f);
        }
    });
};

PioneerDDJFLX4.stopSamplerBlink = function(channel, control) {
    PioneerDDJFLX4.timers[channel] = PioneerDDJFLX4.timers[channel] || {};

    if (PioneerDDJFLX4.timers[channel][control] !== undefined) {
        engine.stopTimer(PioneerDDJFLX4.timers[channel][control]);
        PioneerDDJFLX4.timers[channel][control] = undefined;
    }
};


PioneerDDJFLX4.toggleQuantize = function(_channel, _control, value, _status, group) {
    if (value) {
        script.toggleControl(group, "quantize");
    }
};

PioneerDDJFLX4.quickJumpForward = function(_channel, _control, value, _status, group) {
    if (value) {
        engine.setValue(group, "beatjump", PioneerDDJFLX4.quickJumpSize);
    }
};

PioneerDDJFLX4.quickJumpBack = function(_channel, _control, value, _status, group) {
    if (value) {
        engine.setValue(group, "beatjump", -PioneerDDJFLX4.quickJumpSize);
    }
};

//
// Stems mode
//

PioneerDDJFLX4.stemMutePadPressed = function(_channel, control, value, _status, group) {
    if (value !== 0x7f) {
        return;
    }

    const stemCount = Math.min(engine.getValue(group, "stem_count"), 4);

    if (control - PioneerDDJFLX4.stemMutePadsFirstControl + 1 > stemCount) {
        return;
    }

    const stemGroup = `[${group.substring(1, group.length-1)}_Stem${control - PioneerDDJFLX4.stemMutePadsFirstControl + 1}]`;

    if (engine.getValue(stemGroup, "mute")) {
        engine.setValue(stemGroup, "mute", 0);
    } else {
        engine.setValue(stemGroup, "mute", 1);
    }
};

PioneerDDJFLX4.stemMutePadShiftPressed = function(_channel, control, value, _status, group) {
    if (value !== 0x7f) {
        return;
    }

    const stemCount = Math.min(engine.getValue(group, "stem_count"), 4);

    if (control - PioneerDDJFLX4.stemMutePadsFirstControl + 1 > stemCount) {
        return;
    }

    for (let stemIdx=1; stemIdx<=stemCount; stemIdx++) {
        const stemGroup = `[${group.substring(1, group.length-1)}_Stem${stemIdx}]`;

        if (stemIdx + PioneerDDJFLX4.stemMutePadsFirstControl - 1 === control) {
            engine.setValue(stemGroup, "mute", 0);
        } else {
            engine.setValue(stemGroup, "mute", 1);
        }
    }
};

PioneerDDJFLX4.stemFxPadPressed = function(_channel, control, value, _status, group) {
    if (value !== 0x7f) {
        return;
    }

    if (control - PioneerDDJFLX4.stemFxPadsFirstControl + 1 > 4) {
        return;
    }

    const stemGroup = `[QuickEffectRack1_[${group.substring(1, group.length-1)}_Stem${control - PioneerDDJFLX4.stemFxPadsFirstControl + 1}]]`;

    if (engine.getValue(stemGroup, "enabled")) {
        engine.setValue(stemGroup, "enabled", 0);
    } else {
        engine.setValue(stemGroup, "enabled", 1);
    }
};

PioneerDDJFLX4.stemFxPadShiftPressed = function(_channel, control, value, _status, group) {
    if (value !== 0x7f) {
        return;
    }

    if (control - PioneerDDJFLX4.stemFxPadsFirstControl + 1 > 4) {
        return;
    }

    const stemGroup = `[QuickEffectRack1_[${group.substring(1, group.length-1)}_Stem${control - PioneerDDJFLX4.stemFxPadsFirstControl + 1}]]`;

    engine.setValue(stemGroup, "next_chain_preset", 1);
};

PioneerDDJFLX4.stemCountChanged = function(_value, group, _control) {

    for (let stem=1; stem<=4; stem++) {
        // Stem mute pads
        PioneerDDJFLX4.stemMuteChanged(
            engine.getValue(`[${group.substring(1, group.length-1)}_Stem${stem}]`, "mute"),
            `[${group.substring(1, group.length-1)}_Stem${stem}]`,
            _control,
        );

        // Stem FX pads
        PioneerDDJFLX4.stemFxChanged(
            engine.getValue(`[QuickEffectRack1_[${group.substring(1, group.length-1)}_Stem${stem}]]`, "enabled"),
            `[QuickEffectRack1_[${group.substring(1, group.length-1)}_Stem${stem}]]`,
            _control,
        );
    }
};

PioneerDDJFLX4.stemMuteChanged = function(value, group, _control) {
    const channelStem = group.match(/\[Channel(\d+)_Stem(\d+)\]/);
    const deck = Number(channelStem[1]);
    const stem = Number(channelStem[2]);
    const channel = `[Channel${deck}]`;

    if (stem > 4) {
        return;
    }

    const stemCount = engine.getValue(channel, "stem_count");

    let code = 0x00;
    if (stem <= stemCount && value <= 0.5) {
        code = 0x7f;
    }

    for (let i=0; i<PioneerDDJFLX4.stemsPadsModesStatus[channel].length; i++) {
        midi.sendShortMsg(
            PioneerDDJFLX4.stemsPadsModesStatus[channel][i],
            PioneerDDJFLX4.stemMutePadsFirstControl + stem -1,
            code,
        );
    }
};

PioneerDDJFLX4.stemFxChanged = function(value, group, _control) {
    const channelStem = group.match(/\[QuickEffectRack1_\[Channel(\d+)_Stem(\d+)\]\]/);
    const deck = Number(channelStem[1]);
    const stem = Number(channelStem[2]);
    const channel = `[Channel${deck}]`;

    if (stem > 4) {
        return;
    }

    for (let i=0; i<PioneerDDJFLX4.stemsPadsModesStatus[channel].length; i++) {
        midi.sendShortMsg(
            PioneerDDJFLX4.stemsPadsModesStatus[channel][i],
            PioneerDDJFLX4.stemFxPadsFirstControl + stem -1,
            value <= 0.5 ? 0x00 : 0x7f,
        );
    }
};

//
// Pitch Shift mode
//

PioneerDDJFLX4.pitchAdjusted = function(_value, group, _control) {
    const pitchAdjust = Math.round(engine.getValue(group, "pitch_adjust"));
    let lights = 0b00000000;

    if (pitchAdjust === 0) {
        lights = 0b10000001;
    } else if (pitchAdjust === 1) {
        lights = 0b01000000;
    } else if (pitchAdjust === 2) {
        lights = 0b00100000;
    } else if (pitchAdjust === 3) {
        lights = 0b00010000;
    } else if (pitchAdjust === 4) {
        lights = 0b10010000;
    } else if (pitchAdjust === 5) {
        lights = 0b01010000;
    } else if (pitchAdjust === 6) {
        lights = 0b00110000;
    } else if (pitchAdjust === 7) {
        lights = 0b10110000;
    } else if (pitchAdjust === 8) {
        lights = 0b01110000;
    } else if (pitchAdjust > 8) {
        lights = 0b11110000;
    } else if (pitchAdjust === -1) {
        lights = 0b00000010;
    } else if (pitchAdjust === -2) {
        lights = 0b00000100;
    } else if (pitchAdjust === -3) {
        lights = 0b00001000;
    } else if (pitchAdjust === -4) {
        lights = 0b00001001;
    } else if (pitchAdjust === -5) {
        lights = 0b00001010;
    } else if (pitchAdjust === -6) {
        lights = 0b00001100;
    } else if (pitchAdjust === -7) {
        lights = 0b00001101;
    } else if (pitchAdjust === -8) {
        lights = 0b00001110;
    } else if (pitchAdjust < -8) {
        lights = 0b00001111;
    } else {
        lights = 0b11111111;
    }

    for (let i=0; i<8; i++) {
        let code = 0x00;
        const pad = 0b10000000 >>> i;

        if (lights & pad) {
            code = 0x7f;
        } else {
            code = 0x00;
        }

        PioneerDDJFLX4.pitchPadsModesStatus[group].forEach(
            (padMode) => midi.sendShortMsg(
                padMode,
                PioneerDDJFLX4.pitchPadsFirstControl + i,
                code,
            )
        );
    }
};

PioneerDDJFLX4.pitchPadPressed = function(_channel, control, value, _status, group) {
    if (value !== 0x7f) {
        return;
    }

    const pad = control - this.pitchPadsFirstControl;
    let pitch = 0;

    if (pad === 0) {
        pitch = 0;
    } else if (pad === 1) {
        pitch = 1;
    } else if (pad === 2) {
        pitch = 2;
    } else if (pad === 3) {
        pitch = 3;
    } else if (pad === 4) {
        pitch = -3;
    } else if (pad === 5) {
        pitch = -2;
    } else if (pad === 6) {
        pitch = -1;
    } else if (pad === 7) {
        pitch = 0;
    }

    engine.setValue(group, "pitch_adjust", pitch);
};

PioneerDDJFLX4.pitchPadShiftPressed = function(_channel, control, value, _status, group) {
    if (value !== 0x7f) {
        return;
    }

    const pad = control - this.pitchPadsFirstControl;

    let currentPitch = engine.getValue(group, "pitch_adjust");

    if (pad === 0) {
        currentPitch += 1;
    } else if (pad === 1) {
        currentPitch += 2;
    } else if (pad === 2) {
        currentPitch += 3;
    } else if (pad === 3) {
        currentPitch += 4;
    } else if (pad === 4) {
        currentPitch += -4;
    } else if (pad === 5) {
        currentPitch += -3;
    } else if (pad === 6) {
        currentPitch += -2;
    } else if (pad === 7) {
        currentPitch += -1;
    }

    engine.setValue(group, "pitch_adjust", currentPitch);
};


//
// Shutdown
//

PioneerDDJFLX4.shutdown = function() {
    // reset vumeter
    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.deck1.vuMeter, false);
    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.deck2.vuMeter, false);

    // housekeeping
    // turn off all Sampler LEDs
    for (var i = 0; i <= 7; ++i) {
        midi.sendShortMsg(0x97, 0x30 + i, 0x00);    // Deck 1 pads
        midi.sendShortMsg(0x98, 0x30 + i, 0x00);    // Deck 1 pads with SHIFT
        midi.sendShortMsg(0x99, 0x30 + i, 0x00);    // Deck 2 pads
        midi.sendShortMsg(0x9A, 0x30 + i, 0x00);    // Deck 2 pads with SHIFT
    }
    // turn off all Hotcue LEDs
    for (i = 0; i <= 7; ++i) {
        midi.sendShortMsg(0x97, 0x00 + i, 0x00);    // Deck 1 pads
        midi.sendShortMsg(0x98, 0x00 + i, 0x00);    // Deck 1 pads with SHIFT
        midi.sendShortMsg(0x99, 0x00 + i, 0x00);    // Deck 2 pads
        midi.sendShortMsg(0x9A, 0x00 + i, 0x00);    // Deck 2 pads with SHIFT
    }

    // turn off loop in and out lights
    PioneerDDJFLX4.setLoopButtonLights(0x90, 0x00);
    PioneerDDJFLX4.setLoopButtonLights(0x91, 0x00);

    // turn off reloop lights
    PioneerDDJFLX4.setReloopLight(0x90, 0x00);
    PioneerDDJFLX4.setReloopLight(0x91, 0x00);

    // stop any flashing lights
    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.beatFx, false);
    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.shiftBeatFx, false);

    for (let deckIndex = 0; deckIndex < 2; deckIndex++) {
        for (let pad = 0; pad < 8; pad++) {
            PioneerDDJFLX4.padFxLight(deckIndex, pad, false);
        }
        PioneerDDJFLX4.padFx.slots[deckIndex].forEach(function(_slot, slotIndex) {
            const unit = PioneerDDJFLX4.padFx.units[deckIndex];
            engine.setValue(`${unit}_Effect${slotIndex + 1}`, "enabled", 0);
        });
        engine.setParameter(PioneerDDJFLX4.padFx.units[deckIndex], "mix", 0);
    }

    // stop the keepalive timer
    engine.stopTimer(PioneerDDJFLX4.keepAliveTimer);
};
