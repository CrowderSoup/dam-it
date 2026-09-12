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

- `WASD` or arrow keys — move
- `E` or `Space` — context-sensitive interact: chop a nearby tree, or build
  a dam piece at a nearby empty slot if you have enough wood

## Current demo loop

1. Walk up to a tree and press interact repeatedly to chop it down (3 hits,
   1 wood each). Felled trees respawn after 8 seconds.
2. Walk to one of the 5 empty dam slots along the river and press interact
   to place a dam piece (costs 3 wood).
3. Once all 5 slots are filled, the river visibly rises and deepens behind
   your finished dam.

## Project layout

```
scenes/
  main/     - the playable level (main.tscn) and its small "pond rises" script
  player/   - the beaver: movement + interact
  world/    - tree, dam slot, and dam piece
  ui/       - HUD (wood count, dam progress)
scripts/
  autoload/ - GameState (progress/signals) and InputSetup (key bindings,
              registered in code instead of hand-edited project.godot resource
              literals)
```

All art in this demo is placeholder vector shapes drawn in `_draw()` —
no image assets yet. Swap these out for real sprites whenever you're ready;
the interaction/collision code doesn't care about the visuals.

## Known simplifications / next steps

- No real art, animation, or audio yet.
- The river is decorative, not a movement obstacle — building the dam is a
  visual/narrative payoff rather than something that changes traversal.
- No save/load, no title screen, no export presets for other platforms.
- Input is currently keyboard-only (no gamepad support).
