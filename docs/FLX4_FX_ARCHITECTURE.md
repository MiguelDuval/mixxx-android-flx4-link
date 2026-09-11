# DDJ-FLX4 FX architecture baseline

This document records the intended FX architecture for the Android FLX4 port.

## Working baseline

The current verified BitGrid state is the implementation baseline. FX work must preserve existing BeatGrid/BitGrid behavior.

## FX topology

- Smart CFX: per-deck QuickEffectRack (`[QuickEffectRack1_[Channel1]]` / `[QuickEffectRack1_[Channel2]]`), driven by each deck's CFX knob and an explicit Smart CFX mode.
- Beat FX: EffectUnit 1 (`[EffectRack1_EffectUnit1]`). Preserve the existing FLX4 mapping behavior: effect selection, focus, beat selection, level/depth, meta via shift, and on/off.
- Pad FX Deck 1: reserved EffectUnit 2.
- Pad FX Deck 2: reserved EffectUnit 3.

## Design rule

The physical controller is the source of interaction. Mixxx ControlObjects are the source of truth. Android UI mirrors the engine/controller state rather than maintaining a parallel FX state machine.

## Implementation order

1. Freeze and verify baseline.
2. Audit and harden Beat FX without changing its behavior.
3. Implement Smart CFX on QuickEffectRack per deck.
4. Implement Pad FX 1/2 using dedicated effect units.
5. Add bidirectional LED/state feedback.
6. Integrate Android FX UI with the same ControlObjects.
7. Build and test after each isolated stage.
