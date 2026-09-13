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
4. The river winds across the map (not a straight line), and wading
   through it slows you down until the dam is finished. Walk to one of the
   5 dam slots sitting along the river's crossing point (also highlights
   in range) and press interact to place a dam piece (costs 2 wood +
   1 stone).
5. Once all 5 slots are filled: the slowdown goes away (dam's done, cross
   freely), a real pond-shaped body of water grows in behind the dam
   (fading in, not just a rectangle getting taller), there's a completion
   sound plus a particle burst at every slot - and the **Lodge** appears
   for the first time, south of the new pond.
6. Walk up to the Lodge and interact repeatedly to build it up through
   three stages - foundation, walls, roof - each costing more wood + stone
   than the last. A critter moves in at each milestone: a frog at the
   foundation, a duck once the walls are up, and a fish in the pond once
   the roof's on.
7. Once the Lodge is complete, two **garden spots** appear near it - a
   flower bed and a bench, 3 wood + 2 stone each, one-time purchases with
   no further stages. Building one reveals its own critter (a butterfly
   for the flower bed, a rabbit for the bench), giving leftover resources
   somewhere to go once the Lodge itself is finished.
8. Progress **saves automatically** (periodically, when the dam is
   completed, and when you close the window) and reloads next time you
   start the game - close it and come back later, your pond is still
   there. `R` any time to reset everything (dam + Lodge + garden spots +
   critters) and start over from scratch, deleting the save.

## "Storms & Scavengers": ongoing upkeep after the dam is done

Once the dam is complete, two low-stakes challenges kick in - no combat,
no permanent loss, nothing that can fail the game, just reasons to keep
gathering wood and stone:

- **Storms.** Every 90-150 seconds, a storm weakens one random built dam
  piece into a leak (a crack + drip - the pond itself stays full, but that
  piece slows you again if you wade near it). Repair it the same way you
  built it - interact, same 2 wood + 1 stone cost.
- **The raccoon.** Every 60-120 seconds, a raccoon shows up near your
  resources and lingers for ~18 seconds. Walk up and interact to shoo it
  off for free. Ignore it and it swipes a little wood/stone (clamped at
  zero - it can never take more than you have) and scurries off.

Both start only once the dam is first completed - a fresh game never has
to deal with either. Both are also announced: a HUD toast names what just
happened, and a small arrow appears at the edge of the screen pointing
toward the leak/raccoon whenever it's off-screen (fading once you're close
enough or it's dealt with) - so neither one relies on you noticing it by
chance.

## Project layout

```
scenes/
  main/     - the playable level (main.tscn): the winding river/pond
              polygons, the "pond fades in" completion script, and the
              storm and raccoon-spawner timers (see main.gd)
  player/   - the beaver: movement, facing/bob animation, interact
  world/    - tree, rock, dam slot (build + repair-a-leak), dam piece,
              lodge, garden spot (flower bed/bench), raccoon (scavenger),
              critter (frog/duck/fish/butterfly/rabbit), and purely-visual
              decorations (bushes)
  ui/       - title screen and HUD: icon-based counts along the bottom,
              a toast banner for announcements, and edge_indicator.gd
              (the off-screen threat arrows)
scripts/
  autoload/ - GameState (progress/signals for both the dam and the Lodge),
              InputSetup (key/gamepad bindings, registered in code instead
              of hand-edited project.godot resource literals), Sfx
              (procedurally generated sound effects - no audio assets), Fx
              (one-shot particle bursts), SaveManager (reads/writes
              user://savegame.json; Main owns the actual save data via
              get_save_data()/apply_save_data())
```

All art in this demo is hand-drawn vector shapes in `_draw()` (no image
files), styled as flat "cutout" shapes: a shared `Palette`
(`scripts/util/palette.gd`) keeps colors consistent across every object,
and `DrawUtil` (`scripts/util/draw_util.gd`) provides the shadow/outline/
shading helpers that give them a cohesive look. The river uses an actual
shader (`shaders/water.gdshader`) for an animated gradient + sparkle. All
sound is still procedurally synthesized — no audio assets either. Swap any
of this for real assets whenever you're ready; the interaction/collision
code doesn't care about the visuals or how the sounds are generated.

## Known simplifications / next steps

- Art is still hand-drawn vector shapes, not sprites/animation - no walk
  cycle, no per-frame animation, just the existing facing/bob/shake juice.
- The river only slows you down (wading), it never blocks movement, so
  there's no risk of getting stuck on either bank.
- No export presets for other platforms yet.
- Gamepad movement is 4-directional (bound to the left stick as digital
  push, not full analog), matching the existing discrete movement model.
- Once both garden spots are built, ongoing play is just fending off
  storms/the raccoon - there's no further one-time content to unlock. Room
  for a second, bigger dam/pond expansion, more garden spots/critters, or
  seasonal events, but none of that exists yet.
- The edge-arrow indicators point at only one storm leak and one raccoon
  at a time (whichever leak is nearest the player); if multiple pieces
  happen to be leaking at once, only the nearest gets an arrow.
- The river/pond shape is one fixed, hand-authored layout (a winding
  polygon + an organic pond blob at the dam site) - not randomized or
  regenerated per game. Every new game and every reset looks the same.
- One save slot, no save UI - it's an implicit "your one pond" save, not a
  menu with multiple slots. Felled trees/mined rocks, and the countdown to
  the next storm/raccoon, don't persist across a save (they just reset);
  only *current* leaks and built state are saved. This only matters if you
  quit within seconds of one of those events.

## Development notes

There's a headless regression test at `tests/smoke_test.gd` (no real
framework like GUT/GoDotTest set up - just plain `assert()`s against the
actual game objects). Run it after making logic changes:

```
godot --headless --path . tests/smoke_test.tscn
```

It instantiates `main.tscn`, drives the real Tree/Rock/DamSlot/GameState
objects directly (chop, mine, build, complete, reset, save, load), and
prints `ALL SMOKE TESTS PASSED` on success or hits a `SCRIPT ERROR:
Assertion failed` at the first broken behavior. Extend this file as new
mechanics are added, rather than writing one-off scratch tests each time.

The test deletes any real save file up front (`SaveManager.delete_save()`)
so a leftover save from manual testing can't silently invalidate its
assertions - keep that call if you add more tests that touch GameState via
a fresh `main.tscn` instance. The save file itself lives at
`user://savegame.json`, which Godot maps to
`~/.local/share/godot/app_userdata/Dam it!/savegame.json` on Linux.
