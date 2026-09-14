# First-dam economy retune (issue #19)

Short before/after reference for the resource-action budget, per the
issue's "record the current resource-action budget" first action. Costs are
the mandatory path to the Act I ending as currently implemented: the dam,
then the Lodge's three stages. The two garden spots are optional/cosmetic
and not counted in the mandatory totals below.

## Before

| Node | Yield/hit | Hits to deplete | Value per depletion | Respawn |
| --- | --- | --- | --- | --- |
| Tree (8 on map) | 1 wood | 3 | 3 wood | 8s |
| Rock (4 on map) | 1 stone | 2 | 2 stone | 10s |
| Berry bush (4 on map) | 2 berries (1 hit) | 1 | 2 berries | 12s |
| Pond plant | 30 energy (1 hit) | 1 | - | 14s |

| Build | Cost | Slots/stages |
| --- | --- | --- |
| Dam | 2 wood + 1 stone / slot | 5 identical slots |
| Lodge | 4+2, 5+3, 6+4 wood+stone | 3 stages |
| Garden spot (optional) | 3 wood + 2 stone | 2 spots |

Mandatory totals (dam + Lodge): **25 wood + 14 stone = 39 gather hits**,
plus travel between 8 trees / 4 rocks spread across a 1360x760 map. At 1
stone/hit from only 4 rocks (8 stone available before any respawn), the
14 stone needed forces at least one full rock-respawn wait even before the
optional gardens are considered. This is the repetition the current-demo
baseline's "Repetition precedes the main payoff" friction item and the
issue's "reduce repetitive harvesting" goal are both about - see
[current-demo-baseline.md](current-demo-baseline.md).

The five dam slots were also mechanically and visually identical - no
information to read, no choice to make, just five repeats of the same
build action.

## After

| Node | Yield/hit | Hits to deplete | Value per depletion | Respawn |
| --- | --- | --- | --- | --- |
| Tree (8 on map) | 2 wood | 3 | 6 wood | 6s |
| Rock (4 on map) | 2 stone | 2 | 4 stone | 7s |
| Berry bush (4 on map) | 3 berries (1 hit) | 1 | 3 berries | 9s |
| Pond plant | 30 energy (1 hit) | 1 | - | 11s |

Dam/Lodge/garden costs are unchanged - the fix targets hit *count*, not
the numbers a player has to hold in their head, so the costs stay the same
familiar 2/1, 4+2/5+3/6+4, 3/2 the objective text and HUD already reference.

Mandatory totals (dam + Lodge): still 25 wood + 14 stone, now **~20 gather
hits** (13 wood + 7 stone, rounding up partial hits) - about half the
previous count. The 4 rocks now yield 16 stone before any respawn, covering
the 14 stone needed for the mandatory path without forcing a wait; the 8
trees yield 48 wood, well over the 25 wood needed. Respawn waits on the
mandatory path are effectively eliminated; they still exist for anyone who
leans heavily on one or two nodes, or who also builds both optional garden
spots.

## Observation step: the keystone dam slot

One of the five dam slots (`DamSlot3`, the river's center gap - see
`is_keystone` in `scenes/world/dam_slot.gd` and `main.tscn`) now sits in the
river's strongest current and refuses to build - same cost, same prompt
pattern as an unaffordable action - until the player has read the water at
a new `RiverGauge` interactable nearby (`scenes/world/river_gauge.gd`). This
is the "beyond five identical slots" observation step the issue asks for:
reading the water is free, instant, and always available beforehand, so it
never blocks or fails - the player just needs to have looked before that one
slot will accept a piece. The other four slots are unaffected and build
exactly as before.

## What wasn't changed and why

- Dam/Lodge/garden wood+stone costs: unchanged, to keep the numbers players
  already see in the HUD/prompts meaningful and avoid re-balancing the
  Lodge/garden progression on top of the hit-count fix.
- Pouch capacity/upgrade costs: unrelated to the mandatory path's hit count
  (pouch upgrades are optional QoL after the Lodge is built).
- `PondPlant.ENERGY_RESTORE`: already generous relative to ambient drain;
  only its respawn timer was trimmed for consistency with the other nodes.
