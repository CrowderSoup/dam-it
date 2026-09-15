# Act I Lodge and Resident Implementation Matrix

Status: **Issue #20 implementation contract shipped; #21 integration pending**
Milestone: **1 — Act I narrative vertical slice**  
Issues: [#17](https://github.com/CrowderSoup/dam-it/issues/17),
[#20](https://github.com/CrowderSoup/dam-it/issues/20), and
[#21](https://github.com/CrowderSoup/dam-it/issues/21)

This matrix turns issue #20's Lodge, resident, and first-Bramble requirements
into a sequence that can be implemented without making Lodge construction the
cause of unrelated ecological events. It follows the approved story outline:
Moss is already at Willowbend, Eddy responds to restored flow, and Marnie and
Bramble appear during the chapter-ending sequence.

The document is deliberately an implementation plan, not new story canon.
Dialogue wording and the exact beat sheet remain owned by issue #17; the
chapter-ending presentation remains owned by issue #21.

## Current baseline and constraints

- `GameState.lodge_stage` already persists stages 0–3, and `Lodge` already
  draws a site marker, foundation, walls, and roof.
- The #17 narrative spine shipped named interactions by temporarily putting
  collision and dialogue on every `Critter`. The first #20 slice replaces that
  bridge with a composed `Resident` actor while returning garden wildlife to a
  lightweight visual-only `Critter`.
- Before #20 implementation, `Raccoon` was an anonymous repeating timer event
  started as soon as the dam completed. `BrambleEncounter` now owns the fixed
  authored introduction and its restoration boundaries; the recurring timer
  remains unavailable until that encounter sets `bramble_intro_complete`.
- Story flags, objective state, current dialogue, and choice acknowledgement
  already persist inside the version-2 `story` payload. Resident visibility
  should be derived from those facts on load rather than adding another copy
  of the same progression state.
- A routine is a short, visible use of habitat: moving between two or three
  authored points, pausing at an activity, or traversing the overflow. Idle
  bobbing in one place alone is not a resident routine.
- Act I must not require an optional pouch upgrade, recurring scavenger event,
  or ambient conversation to advance.

## Stage and event matrix

The first six columns specify authored intent. The final four specify the
runtime contract and its verification boundary.

| State / transition | Lodge payoff | Resident arrival | Visible routine | Dialogue trigger | Relationship change | Capability unlock | Bramble gate | Saved source of truth | Required tests |
|---|---|---|---|---|---|---|---|---|---|
| Opening; Lodge unavailable | None; the dry site can be inspected only if the #17 beat sheet needs it | Moss is present from a new game at the last shallow pool | Moss alternates between the shallow pool edge and a nearby observation point | Player interaction starts `moss_intro`; it must not auto-repeat after `met_moss` | Moss is skeptical and expects Reed to leave | Moss's closing line starts the first gathering objective | Random scavenging disabled | `met_moss` and objective/dialogue state in the story payload | Moss is visible before Lodge reveal; interaction starts once; loading during the dialogue restores it; no raccoon timer or spawn is possible |
| Dam complete; Lodge stage 0 site revealed | The build marker becomes available, but stage 0 grants no amenity | Eddy becomes eligible because pond/flow habitat exists, not because the Lodge site appears | Moss moves to restored pond cover; Eddy initially inspects the dam's constrained flow path | Dam reaction is a mandatory, brief transformation conversation; Eddy's first conversation begins by player interaction after the payoff | Moss acknowledges the pond but remains cautious; Eddy raises the above/below-flow concern | Existing pond plants and Lodge construction become available | Still disabled | Existing dam state plus `dam_reaction_complete`; Eddy visibility derives from the agreed #17 flow-arrival flag | Dam completion reveals site and correct residents once; save/load restores the pond routines without replaying the reaction; random Bramble remains impossible |
| Stage 0 → 1; foundation / dry platform | A usable dry platform is the first practical proof of Reed staying | No new resident is caused by this stage | Moss includes the Lodge platform in the pond-edge route and pauses there briefly | A short Moss Lodge line becomes available after the build; it is player-initiated after build feedback finishes | Moss shifts from testing Reed's promise to treating Reed as a neighbor | **Rest** becomes available at the platform; keep the cozy full refill unless playtesting calls for a partial-rest distinction | Still disabled | `lodge_stage == 1`; one-time relationship acknowledgement is a story flag, while routine location is derived | Stage spends once, unlocks rest, selects the stage-one Moss line, and restores the same options/routine from a stage-one save |
| Stage 1 → 2; enclosed walls / dry storage | The Lodge visibly gains protected storage | No new resident is caused by this stage | Moss uses the platform less often and returns to pond cover; eligible Eddy continues using the water route independently | A short Lodge-storage follow-up is available from the relevant resident chosen by #17; no mandatory interruption | Moss now expects Reed to remain; Eddy's trust still depends on the flow solution, not this wall | **Shipped:** Reinforced Pouch becomes purchasable as one optional 10→15 capacity upgrade; the prototype's three escalating tiers migrate to this single state | Still disabled | `lodge_stage == 2`, single pouch-upgrade state, and one-time dialogue flag | Automated in `smoke_test`: stage-two gate, one-time purchase, capacity, and v2→v3 migration; story remains independent |
| Stage 2 → 3; finished roof / warm center | The finished Lodge becomes a community gathering place, distinct from the dam payoff | No resident teleports in solely because the roof is built | Moss can pause at the Lodge and pond; Eddy remains on the overflow route when his flow gate is satisfied | **Shipped:** Marnie's request ends with Moss explicitly calling Willowbend Reed's home; reuse that acknowledgement rather than duplicate it | Moss treats Reed's home as part of Willowbend and Reed as a friend who is staying | **Shipped:** stage three can expose celebration eligibility through `Main.is_act_one_ending_eligible()` but never completes the chapter | Bramble remains disabled until the authored #21 sequence invokes the #20 encounter | `lodge_stage == 3`, completed `check_eddy_route`, `pond_restored`, and `willowbend_narrative_spine_complete` | Automated in `narrative_test` and `story_boundary_test`: every story/UI prerequisite, one eligibility transition, and started/completed idempotency gates |
| Chapter-ending sequence; owned jointly with #21 | Lodge gathering visually pays off all three stages | Marnie arrives from upstream in response to strange Aspen Meadow water; Bramble appears only in the authored encounter | **Shipped #20 handoff:** Bramble follows a deterministic enter/material/two-leg escape path through authored anchors | #21 starts the celebration and supplies the blocking reaction dialogue around #20's phase API | Bramble's visible material bundle and charred debris establish shelter-building need without excusing the harm | Upstream route is revealed by the explicit chapter-complete event, not by Lodge stage | **Shipped:** the flag precedes the fixed clamped loss, active resource targets are reserved, zero stock proceeds, and recurring scavenging waits for completion | `bramble_intro_started`, `bramble_material_taken`, `bramble_intro_complete`, and #21's separate `act_one_complete` campaign flag | Automated in `bramble_encounter_test`: fixed path, protected/zero loss, all stable restoration boundaries, and replay prevention; #21 presentation integration remains |
| Calm post-chapter / repeat play | Rest and the optional single pouch upgrade remain available | **Shipped:** Moss, Eddy, and Marnie remain present in their established habitats until Act II exists | **Shipped:** each resident resumes a short routine; Marnie waits near the upstream route rather than occupying the Lodge | **Shipped:** interactions choose concise post-chapter ambient lines and never restart required scenes | Willowbend reads as a community, while Bramble remains an unresolved neighbor rather than a defeated nuisance | Route hook remains visible; no further capability is required in Milestone 1 | Recurring scavenging may be enabled only if a separate playtest decision keeps it; the hard minimum is `bramble_intro_complete == true` | Story flags, `act_one_complete`, Lodge/pouch state; routine waypoint/animation phase is not saved | Automated in `resident_test`: settled Marnie, all post-chapter routes/dialogues, and deterministic restoration anchors |

## Chapter-ending eligibility contract

Lodge completion is necessary but insufficient. Issue #21 may begin the final
60–90 second sequence only when all of these are true:

1. `GameState.lodge_stage == GameState.LODGE_MAX_STAGE`.
2. The #17 dam-response and Eddy flow/movement objectives are complete.
3. The final required Moss Lodge acknowledgement is complete.
4. No dialogue or other blocking presentation is active.
5. `act_one_complete`, `bramble_intro_started`, and
   `bramble_intro_complete` are false.

The #17 lane should expose the first three narrative facts as stable story
flags or objective ids. The #20 lane must consume them; it must not infer them
from resident visibility or node position. Issue #21 owns setting
`act_one_complete` after the authored sequence and route reveal complete.

The #17 narrative landed before this matrix could freeze its proposed flag
names. Existing objective ids are already save-schema commitments, so #20 uses
this compatibility map rather than silently renaming player progress:

| Kind | Identifier | Producer | Consumer |
|---|---|---|---|
| Existing flag | `met_moss` | `moss_intro` | Moss dialogue selection |
| Existing objective / flag | completed `witness_pond_return` / `pond_restored` | `pond_returns` | Full reaction / pond state; Eddy visibility itself derives from the completed dam |
| Existing objective | completed `check_eddy_route` | `eddy_flow_check` | Eddy's post-restoration routine and ending eligibility |
| Existing objective | completed `talk_moss_home` | `moss_lodge_foundation` | Moss's foundation acknowledgement |
| Existing flag | `willowbend_narrative_spine_complete` | Marnie's request closes with Moss accepting Willowbend as Reed's home | Ending eligibility and post-chapter Moss line |
| Flag | `bramble_intro_started` | #20 encounter orchestrator | Prevent duplicate scheduling and choose restoration state |
| Flag | `bramble_material_taken` | #20 encounter orchestrator | Make the recoverable loss idempotent across save/load |
| Flag | `bramble_intro_complete` | #20 encounter completion | Permit post-introduction behavior; prevent authored replay |
| Campaign flag | `act_one_complete` | #21 ending sequence | Restore the upstream route and calm post-chapter state |

The proposed Bramble and campaign ids remain unchanged. Renaming any identifier
after saves are produced silently drops unknown flags by design, so future
slices must continue consuming this mapping or ship an explicit migration.

## Resident scene contract

Keep `Critter` as the lightweight visual used by decorative wildlife and
garden reveals. Named residents need a separate interactive wrapper, with a
`Critter` visual as a child until bespoke animation is justified. This avoids
turning every butterfly or rabbit decoration into a story actor.

The smallest useful resident component needs:

- a stable resident id and speaker id;
- a story-derived availability predicate;
- ordered dialogue candidates, each with a story condition and priority;
- the shared `get_interaction() -> InteractionOption` contract, returning a
  `Talk` action only when the actor is available and no dialogue is active;
- two or three authored routine points and an activity/pause duration;
- a deterministic `restore_from_story_state()` that selects visibility,
  routine set, and dialogue without playing arrival effects; and
- no independent save payload for position, current waypoint, bob phase, or
  dialogue selection.

Arrival presentation belongs to the event that changes the story flag. On
load, the resident appears directly at the first point of the derived routine.
That prevents a saved resident from replaying a pop-in, running an arrival
twice, or restoring in the middle of a wall.

For Act I:

- **Moss:** opening shallow-pool route; restored pond route after the dam;
  Lodge-inclusive route after stage one; post-chapter gathering/pond route.
- **Eddy:** hidden until the pond exists; constrained inspection route until
  the flow objective completes; overflow/pool route afterward. Eddy never
  waits for a Lodge stage.
- **Marnie:** hidden until the chapter-ending arrival beat; upstream-route
  waiting routine afterward. Marnie never appears at Lodge stage two.
- **Bramble:** controlled by the encounter orchestrator, not the resident
  routine component during the introduction. The authored path and side
  effect must finish or safely converge before any ambient behavior is
  considered.

## Bramble authored-introduction contract

The first appearance is a story event, not a roll of the random timer:

1. Do not create or start `_raccoon_timer` until at least
   `bramble_intro_complete` is true. Dam completion alone is never enough.
2. Spawn Bramble at one authored entry point and follow a fixed path to a
   visible material bundle, then upstream. Do not use the random spawn list.
3. Show immediate, recoverable harm. The default implementation should take a
   small fixed amount, clamped to available stock, and must reserve anything
   still required by the active main-story objective. Zero available material
   changes the reaction line but never blocks progression.
4. Set `bramble_material_taken` before applying the loss in the same
   synchronous handler. A restored save with that flag never charges again.
5. Complete the authored dialogue/path, then set `bramble_intro_complete`.
   On load after `bramble_intro_started` but before completion, reconstruct the
   next safe discrete beat rather than restoring tween time.
6. The visual context should make need plausible (selected construction
   material, charred debris, upstream escape) while Moss's reaction names the
   real community harm. Bramble does not receive full absolution or complete
   the Act III accountability arc in Willowbend.
7. Recurring scavenging is optional. If retained after playtesting, use the
   existing cozy constraints—small clamped loss, berry alternative, no major
   progress rollback—and start it only after the authored introduction.

## Smallest-first implementation sequence

Each step should land with its own focused tests. Steps 1–4 can complete the
smallest stage-one slice before Marnie, Bramble, or chapter-ending work begins.

1. **Accept the identifier handoff from #17.** Freeze the flags/objectives in
   the table above (or record the agreed mapping) before authoring conditions.
2. **Add the named-resident wrapper and Moss only.** Reuse the frog `Critter`
   visual, make `Talk` open #17's Moss dialogue, and derive Moss's opening
   versus restored routine from story/dam state.
3. **Give Lodge stage one its payoff.** Unlock rest at stage one, add the
   Lodge-inclusive Moss routine and stage-one dialogue condition, and cover
   fresh-build plus stage-one save restoration.
4. **Detach named residents from `Critter.required_stage`.** Add Eddy with
   water/story gates; remove the current stage-two duck and stage-three fish
   coupling. Leave garden butterfly/rabbit reveals unchanged.
5. **Implement the stage-two optional upgrade.** Collapse the three prototype
   pouch tiers to one Reinforced Pouch and expose it beginning at stage two;
   migrate/clamp old tier values deliberately before changing shipped saves.
6. **Implement stage-three eligibility, not the ending.** Add the final Moss
   acknowledgement and a pure eligibility query/signal for issue #21. Do not
   set `act_one_complete` here.
7. **Add Marnie's actor and authored arrival state.** Issue #21 controls the
   arrival presentation; the resident component controls the restored and
   post-arrival routine.
8. **Replace the first random raccoon event.** Add Bramble's deterministic
   encounter and its three idempotency flags, then gate any retained timer on
   `bramble_intro_complete`.
9. **Integrate with #21 and run save-boundary coverage.** Verify every matrix
   row, every authored Bramble boundary, and calm post-chapter restoration.
10. **Playtest recurring scavenging separately.** Keeping the timer is a
    product decision based on enjoyment, not a prerequisite for closing #20.

## File ownership and collision plan

The documentation pass intentionally changes no gameplay, story resources, or
tests. For later implementation, use these boundaries:

| Path / concern | Owner before integration | Collision rule |
|---|---|---|
| `data/story/act1/**` and Act I beat/dialogue/objective ids | #17 narrative lane | #20 consumes ids and does not edit wording or narrative resources |
| `scripts/story/**` and `scripts/autoload/act_one_controller.gd` | #17 if runtime support is truly required | Prefer existing flags/conditions; any new generic API lands with #17 before #20 rebases |
| Named resident wrapper scene/script | First lane that needs interactive Moss, preferably #17 as the minimal end-to-end narrative slice | #20 extends the agreed component for routines/Eddy/Marnie; it does not create a competing actor type |
| `scenes/world/lodge.gd` and Lodge tests | #20 | #17 triggers Lodge dialogue from story state but does not change Lodge costs/amenities |
| `scenes/world/raccoon.gd` and authored encounter helper | #20 | #17 owns Bramble/Moss wording only; #21 owns final-sequence presentation calls |
| `scenes/world/critter.gd` | #20 only if a reusable visual hook is needed | Preserve decorative garden behavior; prefer composition over making `Critter` interactive |
| `scenes/main/main.gd` and `main.tscn` | #17 until its narrative branch lands; #20 rebases and integrates afterward | Do not develop competing Main edits in parallel; isolate new logic in resident/encounter components and keep Main wiring thin |
| Chapter-completion flag, route reveal, camera/audio celebration | #21 | #20 exposes eligibility and resident/Bramble state but never completes the chapter |
| Story/dialogue tests | #17 | #20 adds Lodge/resident/Bramble state and integration cases after rebasing; #21 owns final sequence tests |

## Definition of done for issue #20

- Every Lodge transition produces the corresponding relationship, useful
  activity, or capability payoff in the matrix, beyond its drawing change.
- Moss, Eddy, and Marnie visibly use habitat appropriate to their authored
  arrival state and offer concise, state-appropriate interactions.
- Bramble's first appearance is deterministic, contextualized, accountable,
  recoverable, idempotent, and impossible before its authored gate.
- Loading at every stage/event boundary restores the correct stable state
  without replaying arrivals, dialogue effects, material loss, or chapter
  completion.
- Required progression never depends on the optional pouch purchase, ambient
  dialogue, exact routine position, or retained recurring scavenging.
