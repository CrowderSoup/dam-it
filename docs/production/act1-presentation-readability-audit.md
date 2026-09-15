# Act I Presentation and Readability Audit

Status: **Integrated Milestone 1 pass**
Issue: [#9](https://github.com/CrowderSoup/dam-it/issues/9)  
Target: 640x360 Godot viewport scaled into a desktop Web browser

This audit now covers the integrated Act I layouts after narrative, resident,
and chapter-ending work stabilized. It uses the current Willowbend scene, the
640x360 browser captures reviewed in issue #32, final authored copy, and the
approved [visual direction](../design/visual-direction.md) as its baseline.

The implementation paired with this audit replaces Reed's whole-body bob and
mirrored two-direction drawing with four readable cardinal poses and a layered
procedural walk cycle. It also establishes durable procedural ambience without
coupling it to resident or ending choreography. The integrated pass raises
small interface copy, strengthens translucent HUD contrast, and validates the
finished chapter-ending layout.

## Findings and priority

| Priority | Finding | Current action | Completion evidence |
|---|---|---|---|
| P0 | Browser font fallback did not contain the journal's checkmark and bullet glyphs. | Resolved by PR #33 with ASCII status markers. Keep player-facing control/status copy within the shipped font's verified glyph set. | Journal and HUD tests assert the Web-safe strings. |
| P0 | Long action reasons and the native-style Controls dialog could derive sizes wider than the base viewport. | Resolved by PR #33 with bounded wrapping panels/dialog copy. Preserve those bounds when narrative text is added. | Headless layout assertions cover the longest current action reason and Controls dialog. |
| P1 | Reed only faced sideways and moved as a single bobbing cutout, so up/down travel and footfall were hard to read. | This slice adds front, back, left, and right silhouettes selected by the dominant movement axis, with alternating feet, body lift, and tail motion. | `player_visual_test.gd` covers all directions, diagonal selection, independent layers, and idle reset. |
| P1 | Finished objective, prompt, journal, and dialogue copy was bounded, but several labels were only 11-14 px at the 640x360 target. | Raise persistent HUD copy to 13 px, journal copy to 15 px, dialogue to 16 px, and choices to 14 px; retain wrapping and safe rectangles. | UI tests cover the longest prompt, journal content, three-choice dialogue, and chapter banner. |
| P1 | The game has procedural effects but no ambient or musical state model. Wiring cues directly to current demo events would make dialogue/save transitions fragile. | Resolved for title, dry Willowbend, restored pond, chapter ending, calm play, save restoration, and dialogue ducking by `Ambience`. | Ambience and chapter-ending tests verify idempotence and live-versus-restored behavior. |
| P2 | Resident motion must read as habitat use, not static rewards. | Resolved through habitat-specific routes and post-chapter dialogue from #20. | Resident tests verify all three routine/restoration states. |
| P2 | Dam completion and chapter completion need distinct framing. | Resolved: the dam uses a local water fade/punch/sting; the ending uses a gathering, muddy pulse, camera journey, permanent route, full-width banner, and separate cue. | Automated state coverage is complete; recognition remains a #15 human-playtest question. |

## Implemented movement contract

Reed keeps eight-way physical movement while the drawing resolves to four
poses:

- horizontal-dominant input selects left or right;
- vertical-dominant input selects front/down or back/up;
- the last facing remains visible while idle;
- the visual node itself is never mirrored, so its state and child transforms
  remain stable;
- feet move in opposition while the body lifts and tail sways independently;
- low-energy eyes remain readable in every pose; and
- animation changes drawing only, never collision, camera, movement speed, or
  energy drain.

This is intentionally a compact procedural equivalent of a walk cycle, not a
new sprite pipeline. It validates the approved cutout approach before the
project commits to external character assets.

## Implemented audio state contract

Music and ambience should be driven by durable presentation state, not by
replaying one-shot story signals. The minimum states are:

| State | Entry source | Sound intent | Restore behavior |
|---|---|---|---|
| Title | Title scene active | Sparse creek/wind bed and a short identity cue | Begin once per title visit. |
| Dry Willowbend exploration | Act I active, dam incomplete | Thin water, exposed-bank insects, restrained exploration loop | Resume the loop after load; dialogue ducks it but does not restart it. |
| Restored pond exploration | Dam complete, Act I incomplete | Fuller water, frogs/birds, warmer variation of exploration | Derive from saved dam state and crossfade from dry ambience. |
| Transformation | Live dam-completion transition | One-shot payoff over the crossfade | Never replay merely because a completed save loaded. |
| Chapter ending | #21 sequence active | Distinct community/theme cue, not the dam sting again | Restore the stable sequence boundary selected by #21. |
| Calm post-chapter | `act_one_complete` | Settled restored ambience with no forced celebration replay | Derive from the saved campaign flag. |

Implementation rules:

1. Keep procedural interaction effects in `Sfx`; introduce a separate music /
   ambience owner so pausing dialogue does not destroy playback state.
2. Expose an idempotent `set_state()` operation. Calling it repeatedly with
   the same state must not restart a loop.
3. Use short crossfades between exploration states and duck, rather than stop,
   under dialogue.
4. Trigger transformation and ending stings only from live transition events;
   save loading selects the resulting stable ambience directly.
5. Keep the chapter-ending cue and camera timing owned by #21 even if the
   reusable audio state owner lands earlier.

`Ambience` now implements this contract with two crossfading procedural loop
players. `TitleScreen` selects the title bed; `Main` asks it to derive dry or
restored Willowbend only after save data and dam slots are fully restored.
Dialogue signals change the active loop's target volume without stopping it.
The `CHAPTER_ENDING` state and `set_chapter_ending_active()` API are reserved
for #21, and intentionally retain the restored pond bed until that issue adds
its authored cue and timing. `CALM_POST_CHAPTER` already derives from the
future durable `act_one_complete` flag without replaying a celebration.

## Remaining human validation gate

The source-level and automated presentation checks are complete. Issue #15's
release-candidate playtest still needs to:

- verify focus visibility and navigation with keyboard and a physical gamepad;
- check every overlay against the 640x360 safe rectangle and browser aspect
  ratios wider and narrower than 16:9;
- spot-check normal and low-energy movement in all four directions;
- verify ambience survives pause, dialogue, and save/load without restarting;
- confirm first-time players distinguish dam completion from chapter ending;
  and
- record the results through `playtest-method.md` as part of issue #15.
