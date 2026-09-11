from pathlib import Path

qml_path = Path("res/qml/MainWindow.qml")
qml = qml_path.read_text()
start = qml.find("                // Skin.EffectRow {")
if start < 0:
    raise SystemExit("EffectsRow start marker not found")
end = qml.find("                Loader {", start)
if end < 0:
    raise SystemExit("EffectsRow end marker not found")
new_effects = '''                Skin.EffectRow {\n                    id: effects\n\n                    anchors.left: parent.left\n                    anchors.right: parent.right\n                    anchors.top: root.show4decks ? deck4.bottom : deck2.bottom\n                    height: implicitHeight\n                    visible: root.showEffects && !root.maximizeLibrary\n                    z: 2\n\n                    Skin.FadeBehavior on visible {\n                        fadeTarget: effects\n                    }\n                }\n'''
qml = qml[:start] + new_effects + qml[end:]
old = '''                    anchors {\n                        bottom: parent.bottom\n                        top: mixer.bottom\n                    }'''
new = '''                    anchors {\n                        bottom: parent.bottom\n                        top: root.showEffects && !root.maximizeLibrary ? effects.bottom : mixer.bottom\n                    }'''
if old not in qml:
    raise SystemExit("Library anchor block not found")
qml = qml.replace(old, new, 1)
qml_path.write_text(qml)

js_path = Path("res/controllers/Pioneer-DDJ-FLX4-script.js")
js = js_path.read_text()
old = '''PioneerDDJFLX4.padFx = {\n    units: [\n        "[EffectRack1_EffectUnit2]",\n        "[EffectRack1_EffectUnit3]"\n    ],\n    slots: [[], []],\n    sequence: [0, 0],\n};'''
new = '''PioneerDDJFLX4.padFx = {\n    units: [\n        "[EffectRack1_EffectUnit2]",\n        "[EffectRack1_EffectUnit3]"\n    ],\n    slots: [[], []],\n    sequence: [0, 0],\n    mode: [0, 0],\n};'''
if old not in js:
    raise SystemExit("PadFx state block not found")
js = js.replace(old, new, 1)
old = '''PioneerDDJFLX4.padModeKeyPressed = function(_channel, _control, value, _status, _group) {\n    if (value === 0) {\n        return;\n    }\n\n    const deck = (_status === 0x90 ? PioneerDDJFLX4.lights.deck1 : PioneerDDJFLX4.lights.deck2);\n    PioneerDDJFLX4.setPadModeLight(deck, _control);\n};'''
new = '''PioneerDDJFLX4.clearPadFxDeck = function(deckIndex) {\n    const unit = PioneerDDJFLX4.padFx.units[deckIndex];\n    const slots = PioneerDDJFLX4.padFx.slots[deckIndex];\n    for (let slotIndex = 0; slotIndex < 3; slotIndex++) {\n        engine.setValue(`${unit}_Effect${slotIndex + 1}`, "enabled", 0);\n    }\n    engine.setParameter(unit, "mix", 0);\n    slots.forEach(function(slotState) {\n        if (slotState) {\n            PioneerDDJFLX4.padFxLight(deckIndex, slotState.pad, false);\n        }\n    });\n    PioneerDDJFLX4.padFx.slots[deckIndex] = [];\n};\n\nPioneerDDJFLX4.padModeKeyPressed = function(_channel, control, value, status, _group) {\n    if (value === 0) {\n        return;\n    }\n    const deckIndex = status === 0x90 ? 0 : 1;\n    const deck = deckIndex === 0 ? PioneerDDJFLX4.lights.deck1 : PioneerDDJFLX4.lights.deck2;\n    PioneerDDJFLX4.setPadModeLight(deck, control);\n    if (control === 0x1E) {\n        PioneerDDJFLX4.padFx.mode[deckIndex] = 0;\n        PioneerDDJFLX4.clearPadFxDeck(deckIndex);\n    } else if (control === 0x6B) {\n        PioneerDDJFLX4.padFx.mode[deckIndex] = 1;\n        PioneerDDJFLX4.clearPadFxDeck(deckIndex);\n    }\n};'''
if old not in js:
    raise SystemExit("PadMode callback not found")
js = js.replace(old, new, 1)
old = '''        engine.setParameter(unit, "mix", 0);\n\n        for (let slot = 1; slot <= 3; slot++) {'''
new = '''        PioneerDDJFLX4.padFx.mode[deckIndex] = 0;\n        engine.setParameter(unit, "mix", 0);\n\n        for (let slot = 1; slot <= 3; slot++) {'''
if old not in js:
    raise SystemExit("PadFx init anchor not found")
js = js.replace(old, new, 1)
old = '''PioneerDDJFLX4.padFxPadPressed = function(_channel, control, value, status, group) {\n    const deckIndex = group === "[Channel1]" ? 0 : 1;\n    const mode = (status === 0x97 || status === 0x99) ? 0 : 1;\n    const pad = control - 0x10;'''
new = '''PioneerDDJFLX4.padFxPadPressed = function(_channel, control, value, _status, group) {\n    const deckIndex = group === "[Channel1]" ? 0 : 1;\n    const mode = PioneerDDJFLX4.padFx.mode[deckIndex];\n    const pad = control - 0x10;'''
if old not in js:
    raise SystemExit("PadFx trigger header not found")
js = js.replace(old, new, 1)
js_path.write_text(js)
