from pathlib import Path

js_path = Path("res/controllers/Pioneer-DDJ-FLX4-script.js")
xml_path = Path("res/controllers/Pioneer-DDJ-FLX4.midi.xml")
doc_path = Path("docs/FLX4_FX_ARCHITECTURE.md")

js = js_path.read_text()
xml = xml_path.read_text()
doc = doc_path.read_text()

old = '''PioneerDDJFLX4.smartCfxEnabled = false;\n\n// Jog wheel loop adjust'''
new = '''PioneerDDJFLX4.smartCfxEnabled = false;\n\n// Pad FX uses the dedicated EffectUnit 2/3 per deck. Mixxx exposes three\n// effect slots per EffectUnit, so the eight physical pads are treated as an\n// eight-effect trigger bank with a three-slot active pool. Pad FX1 addresses\n// effects 1-8; Pad FX2 addresses effects 9-16 (wrapping to the installed list).\nPioneerDDJFLX4.padFx = {\n    units: [\n        "[EffectRack1_EffectUnit2]",\n        "[EffectRack1_EffectUnit3]"\n    ],\n    active: [[], []],\n    slots: [[], []],\n};\n\n// Jog wheel loop adjust'''
if old not in js:
    raise SystemExit("JS insertion anchor not found")
js = js.replace(old, new, 1)

old = '''    engine.setValue("[EffectRack1_EffectUnit1]", "show_focus", 1);\n\n    engine.makeConnection'''
new = '''    engine.setValue("[EffectRack1_EffectUnit1]", "show_focus", 1);\n    PioneerDDJFLX4.initializePadFx();\n\n    engine.makeConnection'''
if old not in js:
    raise SystemExit("JS init anchor not found")
js = js.replace(old, new, 1)

old = '''PioneerDDJFLX4.padModeKeyPressed = function(_channel, _control, value, _status, _group) {\n    const deck = (_status === 0x90 ? PioneerDDJFLX4.lights.deck1 : PioneerDDJFLX4.lights.deck2);\n\n    if (_control === 0x1B) {\n        PioneerDDJFLX4.toggleLight(deck.hotcueMode, true);\n    } else if (_control === 0x69) {\n        PioneerDDJFLX4.toggleLight(deck.keyboardMode, true);\n    } else if (_control === 0x1E) {\n        PioneerDDJFLX4.toggleLight(deck.padFX1Mode, true);\n    } else if (_control === 0x6B) {\n        PioneerDDJFLX4.toggleLight(deck.padFX2Mode, true);\n    } else if (_control === 0x20) {\n        PioneerDDJFLX4.toggleLight(deck.beatJumpMode, true);\n    } else if (_control === 0x6D) {\n        PioneerDDJFLX4.toggleLight(deck.beatLoopMode, true);\n    } else if (_control === 0x22) {\n        PioneerDDJFLX4.toggleLight(deck.samplerMode, true);\n    } else if (_control === 0x6F) {\n        PioneerDDJFLX4.toggleLight(deck.keyShiftMode, true);\n    }\n};'''
new = '''PioneerDDJFLX4.setPadModeLight = function(deck, modeControl) {\n    const modes = [\n        deck.hotcueMode,\n        deck.keyboardMode,\n        deck.padFX1Mode,\n        deck.padFX2Mode,\n        deck.beatJumpMode,\n        deck.beatLoopMode,\n        deck.samplerMode,\n        deck.keyShiftMode,\n    ];\n\n    modes.forEach(function(light) {\n        PioneerDDJFLX4.toggleLight(light, false);\n    });\n\n    switch (modeControl) {\n    case 0x1B: PioneerDDJFLX4.toggleLight(deck.hotcueMode, true); break;\n    case 0x69: PioneerDDJFLX4.toggleLight(deck.keyboardMode, true); break;\n    case 0x1E: PioneerDDJFLX4.toggleLight(deck.padFX1Mode, true); break;\n    case 0x6B: PioneerDDJFLX4.toggleLight(deck.padFX2Mode, true); break;\n    case 0x20: PioneerDDJFLX4.toggleLight(deck.beatJumpMode, true); break;\n    case 0x6D: PioneerDDJFLX4.toggleLight(deck.beatLoopMode, true); break;\n    case 0x22: PioneerDDJFLX4.toggleLight(deck.samplerMode, true); break;\n    case 0x6F: PioneerDDJFLX4.toggleLight(deck.keyShiftMode, true); break;\n    }\n};\n\nPioneerDDJFLX4.padModeKeyPressed = function(_channel, _control, value, _status, _group) {\n    if (value === 0) {\n        return;\n    }\n\n    const deck = (_status === 0x90 ? PioneerDDJFLX4.lights.deck1 : PioneerDDJFLX4.lights.deck2);\n    PioneerDDJFLX4.setPadModeLight(deck, _control);\n};\n\nPioneerDDJFLX4.initializePadFx = function() {\n    for (let deckIndex = 0; deckIndex < 2; deckIndex++) {\n        const unit = PioneerDDJFLX4.padFx.units[deckIndex];\n        const channel = `[Channel${deckIndex + 1}]`;\n        const otherChannel = `[Channel${deckIndex === 0 ? 2 : 1}]`;\n\n        engine.setValue(unit, "show_focus", 1);\n        engine.setValue(unit, "group_" + channel + "_enable", 1);\n        engine.setValue(unit, "group_" + otherChannel + "_enable", 0);\n        engine.setParameter(unit, "mix", 0);\n\n        for (let slot = 1; slot <= 3; slot++) {\n            engine.setValue(`${unit}_Effect${slot}`, "enabled", 0);\n        }\n    }\n};\n\nPioneerDDJFLX4.padFxPadStatus = function(deckIndex, mode, pad) {\n    return `${mode}:${pad}:${deckIndex}`;\n};\n\nPioneerDDJFLX4.padFxLight = function(deckIndex, pad, active) {\n    const statusPair = deckIndex === 0 ? [0x97, 0x98] : [0x99, 0x9A];\n    statusPair.forEach(function(status) {\n        midi.sendShortMsg(status, 0x10 + pad, active ? 0x7F : 0x00);\n    });\n};\n\nPioneerDDJFLX4.findPadFxSlot = function(deckIndex, key) {\n    return PioneerDDJFLX4.padFx.slots[deckIndex].findIndex(function(slot) {\n        return slot && slot.key === key;\n    });\n};\n\nPioneerDDJFLX4.findFreePadFxSlot = function(deckIndex) {\n    const slots = PioneerDDJFLX4.padFx.slots[deckIndex];\n    for (let slot = 0; slot < 3; slot++) {\n        if (!slots[slot]) {\n            return slot;\n        }\n    }\n    return -1;\n};\n\nPioneerDDJFLX4.releasePadFxSlot = function(deckIndex, slotIndex) {\n    const slotState = PioneerDDJFLX4.padFx.slots[deckIndex][slotIndex];\n    if (!slotState) {\n        return;\n    }\n\n    const unit = PioneerDDJFLX4.padFx.units[deckIndex];\n    engine.setValue(`${unit}_Effect${slotIndex + 1}`, "enabled", 0);\n    PioneerDDJFLX4.padFxLight(deckIndex, slotState.pad, false);\n    PioneerDDJFLX4.padFx.slots[deckIndex][slotIndex] = null;\n\n    const stillActive = PioneerDDJFLX4.padFx.slots[deckIndex].some(Boolean);\n    if (!stillActive) {\n        engine.setParameter(unit, "mix", 0);\n    }\n};\n\nPioneerDDJFLX4.loadPadFxEffect = function(deckIndex, slotIndex, targetEffect) {\n    const unit = PioneerDDJFLX4.padFx.units[deckIndex];\n    const slotGroup = `${unit}_Effect${slotIndex + 1}`;\n    const available = Math.floor(engine.getValue("[Master]", "num_effectsavailable"));\n\n    if (available <= 1) {\n        return false;\n    }\n\n    const usableEffects = available - 1; // index 0 is the empty/pass-through entry\n    const target = (targetEffect % usableEffects) + 1;\n    let current = Math.floor(engine.getValue(slotGroup, "loaded_effect"));\n\n    if (current < 0 || current >= available) {\n        current = 0;\n    }\n\n    let steps = (target - current + available) % available;\n    while (steps-- > 0) {\n        engine.setValue(slotGroup, "next_effect", 1);\n    }\n\n    engine.setValue(slotGroup, "enabled", 1);\n    engine.setParameter(unit, "mix", 1);\n    return true;\n};\n\nPioneerDDJFLX4.padFxPadPressed = function(_channel, control, value, status, group) {\n    const deckIndex = group === "[Channel1]" ? 0 : 1;\n    const mode = (status === 0x97 || status === 0x99) ? 0 : 1;\n    const pad = control - 0x10;\n\n    if (pad < 0 || pad > 7) {\n        return;\n    }\n\n    const key = PioneerDDJFLX4.padFxPadStatus(deckIndex, mode, pad);\n    const existingSlot = PioneerDDJFLX4.findPadFxSlot(deckIndex, key);\n\n    if (value === 0x00) {\n        if (existingSlot >= 0) {\n            PioneerDDJFLX4.releasePadFxSlot(deckIndex, existingSlot);\n        }\n        return;\n    }\n\n    if (existingSlot >= 0) {\n        return;\n    }\n\n    let slotIndex = PioneerDDJFLX4.findFreePadFxSlot(deckIndex);\n\n    if (slotIndex < 0) {\n        // The physical controller offers eight triggers, while Mixxx supplies\n        // three effect slots. Recycle the oldest active slot rather than\n        // silently doing nothing when a fourth pad is pressed.\n        slotIndex = 0;\n        PioneerDDJFLX4.releasePadFxSlot(deckIndex, slotIndex);\n    }\n\n    const effectBankOffset = mode * 8;\n    if (!PioneerDDJFLX4.loadPadFxEffect(deckIndex, slotIndex, effectBankOffset + pad)) {\n        return;\n    }\n\n    PioneerDDJFLX4.padFx.slots[deckIndex][slotIndex] = {\n        key: key,\n        pad: pad,\n        mode: mode,\n    };\n    PioneerDDJFLX4.padFxLight(deckIndex, pad, true);\n};'''
if old not in js:
    raise SystemExit("padMode block not found")
js = js.replace(old, new, 1)

old = '''    // stop any flashing lights\n    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.beatFx, false);\n    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.shiftBeatFx, false);'''
new = '''    // stop any flashing lights\n    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.beatFx, false);\n    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.shiftBeatFx, false);\n\n    for (let deckIndex = 0; deckIndex < 2; deckIndex++) {\n        for (let pad = 0; pad < 8; pad++) {\n            PioneerDDJFLX4.padFxLight(deckIndex, pad, false);\n        }\n        PioneerDDJFLX4.padFx.slots[deckIndex].forEach(function(_slot, slotIndex) {\n            const unit = PioneerDDJFLX4.padFx.units[deckIndex];\n            engine.setValue(`${unit}_Effect${slotIndex + 1}`, "enabled", 0);\n        });\n        engine.setParameter(PioneerDDJFLX4.padFx.units[deckIndex], "mix", 0);\n    }'''
if old not in js:
    raise SystemExit("shutdown anchor not found")
js = js.replace(old, new, 1)

old = '''//      * Secondary pad modes (trial attempts complex and too experimental)\n//        * Keyboard mode\n//        * Pad FX1\n//        * Pad FX2'''
new = '''//      * Secondary pad modes (trial attempts complex and too experimental)\n//        * Keyboard mode'''
if old in js:
    js = js.replace(old, new, 1)

old = '''//  Not implemented yet (but might be in the future):\n//      * Smart fader'''
new = '''//  Not implemented yet (but might be in the future):\n//      * Smart fader'''
# no-op anchor retained intentionally

js_path.write_text(js)

# Add 32 Pad FX pad bindings if not already present.
marker = '''            <!-- PAD MODE SECTION END -->\n\n            <!-- HOT CUE MODE START -->'''
if marker not in xml:
    raise SystemExit("XML pad section marker not found")

if "PioneerDDJFLX4.padFxPadPressed" not in xml:
    blocks = []
    for deck_num, normal_status, shift_status in [(1, "0x97", "0x98"), (2, "0x99", "0x9A")]:
        channel = f"[Channel{deck_num}]"
        for pad in range(8):
            note = hex(0x10 + pad)
            for mode, status in [("PAD FX1", normal_status), ("PAD FX2", shift_status)]:
                blocks.append(f'''            <control>\n                <description>PAD {pad + 1} (DECK{deck_num}) {mode} - hold - trigger pad FX</description>\n                <group>{channel}</group>\n                <key>PioneerDDJFLX4.padFxPadPressed</key>\n                <status>{status}</status>\n                <midino>{note}</midino>\n                <options>\n                    <Script-Binding/>\n                </options>\n            </control>''')
    xml = xml.replace(marker, "            <!-- PAD FX PADS START -->\n" + "\n".join(blocks) + "\n            <!-- PAD FX PADS END -->\n\n" + marker, 1)

xml_path.write_text(xml)

doc_old = '''- Pad FX Deck 1: reserved EffectUnit 2.\n- Pad FX Deck 2: reserved EffectUnit 3.'''
doc_new = '''- Pad FX Deck 1: EffectUnit 2.\n- Pad FX Deck 2: EffectUnit 3.\n\n### Pad FX slot model\n\nThe DDJ-FLX4 exposes eight physical pads for each Pad FX mode, while Mixxx EffectUnits expose three effect slots. The Android mapping therefore uses an eight-effect logical trigger bank backed by a three-slot active pool. Pad FX1 selects effects 1-8 from the installed Mixxx effect list; Pad FX2 selects effects 9-16, wrapping when fewer effects are installed. Up to three pads can remain active simultaneously. A fourth press reuses the oldest slot rather than creating unsupported state.''' 
if doc_old in doc and "### Pad FX slot model" not in doc:
    doc = doc.replace(doc_old, doc_new, 1)
    doc_path.write_text(doc)
else:
    doc_path.write_text(doc)

print("Pad FX patch applied")
