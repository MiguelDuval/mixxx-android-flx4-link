from pathlib import Path

js_path = Path("res/controllers/Pioneer-DDJ-FLX4-script.js")
js = js_path.read_text()

old = '''PioneerDDJFLX4.smartCfxEnabled = false;\n\n// Pad FX uses the dedicated EffectUnit 2/3 per deck.'''
new = '''PioneerDDJFLX4.smartCfxEnabled = false;\nPioneerDDJFLX4.smartCfxFilterPreset = [-1, -1];\n\n// Pad FX uses the dedicated EffectUnit 2/3 per deck.'''
if old not in js:
    raise SystemExit("Smart CFX state anchor not found")
js = js.replace(old, new, 1)

old = '''    engine.setValue("[EffectRack1_EffectUnit1]", "show_focus", 1);\n    PioneerDDJFLX4.initializePadFx();'''
new = '''    engine.setValue("[EffectRack1_EffectUnit1]", "show_focus", 1);\n    PioneerDDJFLX4.initializeSmartCfx();\n    PioneerDDJFLX4.initializeBeatFx();\n    PioneerDDJFLX4.initializePadFx();'''
if old not in js:
    raise SystemExit("Init anchor not found")
js = js.replace(old, new, 1)

start = js.index('PioneerDDJFLX4.toggleFxLight = function')
end = js.index('//\n// Loop IN/OUT ADJUST', start)
new_block = r'''PioneerDDJFLX4.getBeatFxUnit = function() {
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

'''
js = js[:start] + new_block + js[end:]
js_path.write_text(js)
print("FX Stage A+B JS patch applied")
