# Act I Presentation and Readability Audit

Status: **Early Milestone 1 pass**  
Issue: [#9](https://github.com/CrowderSoup/dam-it/issues/9)  
Target: 640x360 Godot viewport scaled into a desktop Web browser

This audit captures the presentation work that can proceed before Act I's
narrative, resident, and chapter-ending layouts are stable. It uses the
current Willowbend scene, the browser captures reviewed in issue #32, and the
approved [visual direction](../design/visual-direction.md) as its baseline.

The implementation paired with this audit replaces Reed's whole-body bob and
mirrored two-direction drawing with four readable cardinal poses and a layered
procedural walk cycle. It also establishes durable procedural ambience without
coupling it to resident or ending choreography. Final UI and chapter-ending
polish remain gated on #20 and #21.

## Findings and priority

| Priority | Finding | Current action | Completion evidence |
|---|---|---|---|
| P0 | Browser font fallback did not contain the journal's checkmark and bullet glyphs. | Resolved by PR #33 with ASCII status markers. Keep player-facing control/status copy within the shipped font's verified glyph set. | Journal and HUD tests assert the Web-safe strings. |
| P0 | Long action reasons and the native-style Controls dialog could derive sizes wider than the base viewport. | Resolved by PR #33 with bounded wrapping panels/dialog copy. Preserve those bounds when narrative text is added. | Headless layout assertions cover the longest current action reason and Controls dialog. |
| P1 | Reed only faced sideways and moved as a single bobbing cutout, so up/down travel and footfall were hard to read. | This slice adds front, back, left, and right silhouettes selected by the dominant movement axis, with alternating feet, body lift, and tail motion. | `player_visual_test.gd` covers all directions, diagonal selection, independent layers, and idle reset. |
| P1 | The narrative dialogue and journal now exist, but chapter-ending copy and its densest layout do not, so a conclusive scale/contrast pass would still test placeholder density. | Defer final adjustment until #21 has representative longest strings. Add bounds/focus assertions with each content PR. | Required before #9 closes. |
| P1 | The game has procedural effects but no ambient or musical state model. Wiring cues directly to current demo events would make dialogue/save transitions fragile. | Resolved for title, dry Willowbend, restored pond, save restoration, and dialogue ducking by the `Ambience` autoload. #21 still owns the authored chapter-ending cue. | `ambience_test.gd` verifies idempotence and live-versus-restored behavior. |
| P2 | Resident motion is idle bobbing, not visible habitat use. | Owned by #20's resident routine work; #9 should polish poses only after those paths exist. | Verify Moss, Eddy, and Marnie at gameplay zoom. |
| P2 | Current transformation feedback is visually clear but dam completion and chapter completion do not yet have distinct framing. | Preserve the dam cue; reserve a separate audiovisual state and camera sequence for #21. | Side-by-side playtest recognition check. |

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

## Remaining validation gate

Do not close issue #9 with this early slice. After #17, #20, and #21 provide
representative content:

- capture title, exploration, dialogue with three choices, journal with the
  longest objective, every Lodge stage, transformation, and ending at the
  Web target size;
- verify focus visibility and navigation with keyboard and a physical gamepad;
- check every overlay against the 640x360 safe rectangle and browser aspect
  ratios wider and narrower than 16:9;
- compare normal and low-energy movement in all four directions;
- verify ambience survives pause, dialogue, and save/load without restarting;
- confirm first-time players distinguish dam completion from chapter ending;
  and
- record the results through `playtest-method.md` as part of issue #15.
