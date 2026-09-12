# Dam it!

A cozy top-down builder game where you play as a beaver gathering wood and
stone to build a dam across a river. Built with Godot 4 (GDScript),
targeting native Linux for now.

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
  tree, mine a nearby rock, or build a dam piece at a nearby empty slot if
  you have enough wood + stone
- `R` / gamepad Start — reset ALL progress (dam + Lodge) and start over

## Current demo loop: "Grow Your Pond"

Progress is persistent now (no more replay-by-restarting) - the dam is a
means to an end, not the whole game:

1. A title screen greets you; press any key/click/gamepad button to start.
2. Walk up to a tree (it highlights when you're in range) and press
   interact repeatedly to chop it down (3 hits, 1 wood each, with a little
   shake, wood-chip burst, and sound per hit). Felled trees respawn after
   8 seconds.
3. Walk up to a rock and interact to mine it (2 hits, 1 stone each). Mined
   rocks respawn after 10 seconds.
4. Walking through the river slows you down (wading) until the dam is
   finished. Walk to one of the 5 empty dam slots along the river (also
   highlights in range) and press interact to place a dam piece (costs
   2 wood + 1 stone).
5. Once all 5 slots are filled: the slowdown goes away (dam's done, cross
   freely), the river visibly rises and deepens behind it, there's a
   completion sound plus a particle burst at every slot - and the **Lodge**
   site south of the river unlocks (it shows a padlock until then).
6. Walk up to the Lodge and interact repeatedly to build it up through
   three stages - foundation, walls, roof - each costing more wood + stone
   than the last. A critter moves in at each milestone: a frog at the
   foundation, a duck once the walls are up, and a fish in the pond once
   the roof's on.
7. `R` any time to reset everything (dam + Lodge + critters) and start
   over from scratch.

## Project layout

```
scenes/
  main/     - the playable level (main.tscn) and its small "pond rises" script
  player/   - the beaver: movement, facing/bob animation, interact
  world/    - tree, rock, dam slot, dam piece, lodge, critter (frog/duck/
              fish), and purely-visual decorations (bushes)
  ui/       - title screen and HUD (wood/stone counts, dam + Lodge progress)
scripts/
  autoload/ - GameState (progress/signals for both the dam and the Lodge),
              InputSetup (key/gamepad bindings, registered in code instead
              of hand-edited project.godot resource literals), Sfx
              (procedurally generated sound effects - no audio assets), Fx
              (one-shot particle bursts)
```

All art in this demo is placeholder vector shapes drawn in `_draw()`, and
all sound is procedurally synthesized — no image or audio assets yet. Swap
these out for real ones whenever you're ready; the interaction/collision
code doesn't care about the visuals or how the sounds are generated.

## Known simplifications / next steps

- No real art or animation yet (beyond the simple facing/bob/shake juice).
- The river only slows you down (wading), it never blocks movement, so
  there's no risk of getting stuck on either bank.
- No save/load (progress lives only in the running GameState singleton -
  quitting the game loses it), no export presets for other platforms.
- Gamepad movement is 4-directional (bound to the left stick as digital
  push, not full analog), matching the existing discrete movement model.
- The Lodge tops out at 3 stages with no further content after that - the
  "grow your pond" idea has room for a second, bigger dam/pond expansion
  after the Lodge is finished, more critters, or seasonal events, but none
  of that exists yet.

## Development notes

There's a headless regression test at `tests/smoke_test.gd` (no real
framework like GUT/GoDotTest set up - just plain `assert()`s against the
actual game objects). Run it after making logic changes:

```
godot --headless --path . tests/smoke_test.tscn
```

It instantiates `main.tscn`, drives the real Tree/Rock/DamSlot/GameState
objects directly (chop, mine, build, complete, reset), and prints
`ALL SMOKE TESTS PASSED` on success or hits a `SCRIPT ERROR: Assertion
failed` at the first broken behavior. Extend this file as new mechanics are
added, rather than writing one-off scratch tests each time.
