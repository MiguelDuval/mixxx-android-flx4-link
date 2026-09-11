from pathlib import Path

SCRIPT = Path('res/controllers/Pioneer-DDJ-FLX4-script.js')
XML = Path('res/controllers/Pioneer-DDJ-FLX4.midi.xml')

script = SCRIPT.read_text(encoding='utf-8')
xml = XML.read_text(encoding='utf-8')

# 1) Record Smart CFX as implemented in the mapping header.
old = "//  Not implemented yet (but might be in the future):\n//      * Smart CFX\n//      * Smart fader"
new = "//  Implemented in this Android port:\n//      * Smart CFX button -> both channel QuickEffectRacks enabled state\n//        (the existing CFX knobs continue to drive QuickEffectRack.super1)\n//\n//  Not implemented yet (but might be in the future):\n//      * Smart fader"
assert old in script, 'header anchor not found'
script = script.replace(old, new, 1)

# 2) Add Smart CFX LED address.
old = "PioneerDDJFLX4.lights = {\n    beatFx: {"
new = "PioneerDDJFLX4.lights = {\n    smartCfx: {\n        status: 0x96,\n        data1: 0x00,\n    },\n    beatFx: {"
assert old in script, 'lights anchor not found'
script = script.replace(old, new, 1)

# 3) Add logical Smart CFX state.
old = "PioneerDDJFLX4.shiftButtonDown = [false, false];"
new = "PioneerDDJFLX4.shiftButtonDown = [false, false];\n\n// Smart CFX is a global hardware mode; both deck QuickEffectRacks follow it.\nPioneerDDJFLX4.smartCfxEnabled = false;"
assert old in script, 'state anchor not found'
script = script.replace(old, new, 1)

# 4) Register state synchronization and initialise the controller LED.
old = "    engine.makeConnection(\"[EffectRack1_EffectUnit1]\", \"focused_effect\", PioneerDDJFLX4.toggleFxLight);\n\n    // Register callbacks for each deck, when a file is loaded and the number of stems is available"
new = "    engine.makeConnection(\"[EffectRack1_EffectUnit1]\", \"focused_effect\", PioneerDDJFLX4.toggleFxLight);\n\n    // Smart CFX uses the existing per-deck QuickEffectRacks. Keep the hardware\n    // button LED synchronized with the effective state of both channels.\n    engine.makeConnection(\"[QuickEffectRack1_[Channel1]]\", \"enabled\", PioneerDDJFLX4.updateSmartCfxLight);\n    engine.makeConnection(\"[QuickEffectRack1_[Channel2]]\", \"enabled\", PioneerDDJFLX4.updateSmartCfxLight);\n    PioneerDDJFLX4.updateSmartCfxLight();\n\n    // Register callbacks for each deck, when a file is loaded and the number of stems is available"
assert old in script, 'init anchor not found'
script = script.replace(old, new, 1)

# 5) Add Smart CFX behavior immediately before the existing loop section.
anchor = "//\n// Loop IN/OUT ADJUST\n//"
assert anchor in script, 'effect insertion anchor not found'
block = '''//\n// Smart CFX\n//\n// Mixxx exposes each deck's Color FX as a QuickEffectRack. The physical FLX4\n// CFX knobs already control QuickEffectRack.super1; this button now provides\n// the corresponding hardware on/off state without introducing a parallel FX\n// engine. When disabled, the current QuickEffect effects remain configured but\n// are bypassed.\n\nPioneerDDJFLX4.updateSmartCfxLight = function() {\n    const deck1Enabled = engine.getValue(\"[QuickEffectRack1_[Channel1]]\", \"enabled\") > 0;\n    const deck2Enabled = engine.getValue(\"[QuickEffectRack1_[Channel2]]\", \"enabled\") > 0;\n    PioneerDDJFLX4.smartCfxEnabled = deck1Enabled || deck2Enabled;\n    PioneerDDJFLX4.toggleLight(PioneerDDJFLX4.lights.smartCfx, PioneerDDJFLX4.smartCfxEnabled);\n};\n\nPioneerDDJFLX4.smartCfxPressed = function(_channel, _control, value) {\n    if (value === 0) {\n        return;\n    }\n\n    const newState = !PioneerDDJFLX4.smartCfxEnabled;\n    engine.setValue(\"[QuickEffectRack1_[Channel1]]\", \"enabled\", newState);\n    engine.setValue(\"[QuickEffectRack1_[Channel2]]\", \"enabled\", newState);\n    PioneerDDJFLX4.updateSmartCfxLight();\n};\n\n'''
script = script.replace(anchor, block + anchor, 1)

SCRIPT.write_text(script, encoding='utf-8')

# 6) Bind the physical Smart CFX button (global mixer MIDI channel).
xml_anchor = "            <!-- BEAT FX SECTION START -->"
assert xml_anchor in xml, 'XML effect anchor not found'
xml_block = '''            <!-- SMART CFX SECTION START -->\n            <control>\n                <description>SMART CFX - press - toggle Smart CFX mode for both decks</description>\n                <group>[Master]</group>\n                <key>PioneerDDJFLX4.smartCfxPressed</key>\n                <status>0x96</status>\n                <midino>0x00</midino>\n                <options>\n                    <Script-Binding/>\n                </options>\n            </control>\n            <!-- SMART CFX SECTION END -->\n\n'''
xml = xml.replace(xml_anchor, xml_block + xml_anchor, 1)
XML.write_text(xml, encoding='utf-8')

print('Applied Smart CFX mapping patch successfully.')
