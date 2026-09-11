from pathlib import Path
import subprocess

path = Path("res/controllers/Pioneer-DDJ-FLX4-script.js")
js = subprocess.check_output(["git", "show", "a73022000abbcfefed326f45bae794f3afa7f086:res/controllers/Pioneer-DDJ-FLX4-script.js"], text=True)
js = js.replace("PioneerDDJFLX4.smartCfxEnabled = false;", "PioneerDDJFLX4.smartCfxEnabled = false;\nPioneerDDJFLX4.smartCfxFilterPreset = [-1, -1];", 1)
js = js.replace("    PioneerDDJFLX4.initializePadFx();", "    PioneerDDJFLX4.initializeSmartCfx();\n    PioneerDDJFLX4.initializePadFx();", 1)
start = js.index("//\n// Smart CFX\n")
end = js.index("//\n// Loop IN/OUT ADJUST", start)
block = r'''//
// Smart CFX
// OFF = normal Color Filter. ON = Smart CFX. SHIFT + CFX cycles the preset.

PioneerDDJFLX4.initializeSmartCfx = function() {
    PioneerDDJFLX4.smartCfxEnabled = false;
    for (let deck = 0; deck < 2; deck++) {
        const group = `[QuickEffectRack1_[Channel${deck + 1}]]`;
        let preset = Math.floor(engine.getValue(group, "loaded_chain_preset"));
        if (preset <= 0) {
            engine.setValue(group, "next_chain_preset", 1);
            preset = Math.floor(engine.getValue(group, "loaded_chain_preset"));
        }
        PioneerDDJFLX4.smartCfxFilterPreset[deck] = preset;
        engine.setValue(group, "enabled", 1);
    }
    PioneerDDJFLX4.updateSmartCfxLight();
};

PioneerDDJFLX4.setQuickEffectPreset = function(group, targetPreset) {
    let current = Math.floor(engine.getValue(group, "loaded_chain_preset"));
    const count = Math.floor(engine.getValue(group, "num_chain_presets"));
    if (count <= 1 || targetPreset < 0) { return; }
    if (current < 0) { current = 0; }
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
        if (count > 1) {
            let next = current + 1;
            if (next <= 0 || next >= count) { next = 1; }
            PioneerDDJFLX4.setQuickEffectPreset(group, next);
        }
        engine.setValue(group, "enabled", 1);
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
    if (value === 0) { return; }
    const shifted = PioneerDDJFLX4.shiftButtonDown[0] || PioneerDDJFLX4.shiftButtonDown[1];
    if (shifted) {
        if (!PioneerDDJFLX4.smartCfxEnabled) { PioneerDDJFLX4.smartCfxEnabled = true; }
        PioneerDDJFLX4.cycleSmartCfxPreset();
    } else {
        PioneerDDJFLX4.smartCfxEnabled = !PioneerDDJFLX4.smartCfxEnabled;
        if (PioneerDDJFLX4.smartCfxEnabled) {
            PioneerDDJFLX4.cycleSmartCfxPreset();
        } else {
            PioneerDDJFLX4.restoreSmartCfxFilter();
        }
    }
    PioneerDDJFLX4.updateSmartCfxLight();
};

'''
js = js[:start] + block + js[end:]
path.write_text(js)
