# Dam it!

A cozy top-down builder game where you play as a beaver gathering wood and
building a dam across a river. Built with Godot 4 (GDScript), targeting
native Linux for now.

## Requirements

- Godot 4.7+ (installed on this machine via AUR `godot-bin`)
- Linux only for the moment — no export presets for other platforms yet.

## Running the demo

Open the project in the editor and press Play (F5):

```
godot --path . -e
```

...or run it directly without the editor:

```
godot --path .
```

## Controls

- `WASD` or arrow keys, or a gamepad's d-pad/left stick — move
- `E` / `Space` / gamepad A — context-sensitive interact: chop a nearby
  tree, or build a dam piece at a nearby empty slot if you have enough wood
- `R` / gamepad Start — reset progress and replay

## Current demo loop

1. A title screen greets you; press any key/click/gamepad button to start.
2. Walk up to a tree (it highlights when you're in range) and press
   interact repeatedly to chop it down (3 hits, 1 wood each, with a little
   shake, wood-chip burst, and sound per hit). Felled trees respawn after
   8 seconds.
3. Walk to one of the 5 empty dam slots along the river (also highlights in
   range) and press interact to place a dam piece (costs 3 wood).
4. Once all 5 slots are filled, the river visibly rises and deepens behind
   your finished dam, with a completion sound and message.
5. Press restart any time to reset progress and build it again.

## Project layout

```
scenes/
  main/     - the playable level (main.tscn) and its small "pond rises" script
  player/   - the beaver: movement, facing/bob animation, interact
  world/    - tree, dam slot, dam piece, and purely-visual decorations
              (rocks/bushes)
  ui/       - title screen and HUD (wood count, dam progress)
scripts/
  autoload/ - GameState (progress/signals), InputSetup (key/gamepad
              bindings, registered in code instead of hand-edited
              project.godot resource literals), Sfx (procedurally generated
              sound effects - no audio assets), Fx (one-shot particle
              bursts)
```

All art in this demo is placeholder vector shapes drawn in `_draw()`, and
all sound is procedurally synthesized — no image or audio assets yet. Swap
these out for real ones whenever you're ready; the interaction/collision
code doesn't care about the visuals or how the sounds are generated.

## Known simplifications / next steps

- No real art or animation yet (beyond the simple facing/bob/shake juice).
- The river is decorative, not a movement obstacle — building the dam is a
  visual/narrative payoff rather than something that changes traversal.
- No save/load, no export presets for other platforms.
- Gamepad movement is 4-directional (bound to the left stick as digital
  push, not full analog), matching the existing discrete movement model.

## Development notes

There's no in-tree automated test suite yet (Godot's GUT/GoDotTest aren't
set up). When making logic changes, a quick way to sanity-check without a
display is to temporarily drop a scene + script under `scripts/` that
instantiates `main.tscn`, exercises the objects directly (e.g.
`tree.chop()`, `dam_slot.build()`), asserts on `GameState`, then
`get_tree().quit()` — run it with:

```
godot --headless --path . scripts/your_test.tscn
```

Delete the scratch files when done, or turn them into a real test suite if
this project grows.
