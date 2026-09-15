# Act I chapter-ending storyboard

Status: **Implementation contract for issue #21**

The eligibility query and change signal described below are implemented on
`Main`; issue #21 can consume them without duplicating the prerequisite logic.

This storyboard covers the final 60–90 seconds after Reed answers Marnie's
upstream request. It turns the already-authored Willowbend narrative ending
into an unmistakable chapter-complete sequence without making Lodge completion
or dam completion finish the chapter by themselves.

Resident routines and Bramble's deterministic enter/take/flee behavior are
owned by issue #20. The reusable audio state owner is issue #9. This sequence
coordinates those systems, owns the camera/route/banner presentation, and is
the only producer of the saved `act_one_complete` campaign flag.

## Eligibility contract

Evaluate eligibility after objective/dialogue changes and after save
restoration. Start only when every condition is true:

1. `GameState.lodge_stage == GameState.LODGE_MAX_STAGE`.
2. `pond_restored` is true.
3. `check_eddy_route` is complete.
4. `willowbend_narrative_spine_complete` is true. This shipped #17 flag means
   Marnie's request has been answered; do not introduce a duplicate Marnie or
   Moss-acceptance flag.
5. No dialogue, journal, pause menu, or other blocking presentation is active.
6. `act_one_ending_started` and `act_one_complete` are false.

The sequence begins automatically after a short safe delay once eligibility
is reached. It must not begin on the same input press that closes Marnie's
dialogue. Cancel the delay if another overlay opens.

## Target timeline

Reading time varies, so timings describe non-dialogue motion and minimum holds.
The expected total is about 75 seconds, remaining within the issue's 60–90
second target for an ordinary reader.

| Time | Player control | Camera / world action | Dialogue / UI | Audio | Saved boundary |
| ---: | --- | --- | --- | --- | --- |
| 0–3s | Normal control, then gently disabled after the eligibility delay | Keep the gameplay camera on Reed; let the last Marnie line and HUD objective change settle | No new panel | Restored-pond ambience continues without restarting | Set `act_one_ending_started` before taking control |
| 3–13s | Disabled; tree remains unpaused | Blend from Reed to a Lodge/pond group frame. Moss uses the Lodge gathering point, Eddy continues through the overflow, and Marnie waits at the upstream edge | A small non-modal “Willowbend gathers” toast may appear; no blocking text | Crossfade in the celebration layer over restored ambience | Set `act_one_celebration_started` before the camera blend |
| 13–23s | Disabled | Show a muddy pulse and one or two charred branches entering from upstream. The dam holds; do not replay the dam-completion zoom/burst | No dialogue; the visual must read before anyone explains it | Brief muddy-water/branch texture, distinct from the dam sting | Set `act_one_muddy_pulse_seen` once the stable changed-water frame is visible |
| 23–45s | Disabled | Trigger #20's Bramble encounter: deterministic entry, visible approach to a small material bundle, one clamped committed take, then a pause when noticed | At most 3 authored panels: Moss names the harm, Bramble's need remains understandable but unresolved, Reed prevents the moment becoming a victory over a villain | Duck celebration layer under dialogue; never restart the loop | #20 owns `bramble_intro_started` and `bramble_material_taken` before applying loss |
| 45–57s | Disabled | Bramble follows the fixed upstream escape path. Camera follows far enough to reveal the route direction, while keeping Reed or another resident at the frame edge for continuity | No additional exposition | Short rustle/footfall cue; celebration layer yields to route-reveal transition | #20 sets `bramble_intro_complete` only after the path reaches its stable exit boundary |
| 57–68s | Disabled | Settle camera on the upstream route marker. Change it from an unreadable edge to a persistent, clearly traversable future-route landmark | Show “Act I complete — Willowbend” and “Aspen Meadow lies upstream.” The hook may say the route opens in Act II; it must not imply Act II is currently playable | Play the dedicated chapter-complete cue once, never the dam sting | Set `act_one_route_revealed`, then `act_one_complete`; immediately request a save |
| 68–75s | Restore after camera returns | Blend back to Reed, then restore ordinary camera follow. Residents resume post-chapter routines; the route marker remains visible | Banner fades; HUD returns to calm free-play state with no required objective | Enter calm post-chapter ambience idempotently | No new flag; derive the calm state from `act_one_complete` |

## Camera and input contract

- The ending controller disables Player movement/interact directly; it does
  not pause the SceneTree during camera or world motion.
- Dialogue may use the existing pause-owning DialogueBox only when all camera
  tweens are stationary. The ending controller itself must process while
  paused so it can reconcile dialogue completion safely.
- Camera targets are authored scene markers rather than hard-coded offsets:
  `EndingGroupFrame`, `EndingBrambleExit`, and `UpstreamRouteFrame`.
- Keep speakers and important movement in the upper two thirds of the 640×360
  viewport so the dialogue panel never covers them.
- The zoom may tighten modestly for the gathering, but the route reveal must
  be wider than the dam-completion framing and must not expose outside the
  world bounds.
- Pause, journal, restart, and ordinary interaction are disabled while the
  ending owns control. Window-close saving remains active.
- Always release the camera and input lock on completion and on every safe
  recovery path; calm post-chapter play is mandatory.

## Save and resume state machine

Never save tween time, actor interpolation, camera coordinates, or audio
playback position. Restore the next stable phase from flags:

| Restored facts | Recovery behavior |
| --- | --- |
| Eligible, `act_one_ending_started == false` | Restore ordinary play, then schedule the safe eligibility delay |
| Ending started, muddy pulse not seen | Place residents at gathering anchors, restore the wide celebration frame, and replay only the non-destructive gathering/muddy-pulse presentation |
| Muddy pulse seen, Bramble intro not started | Restore changed-water visuals and begin Bramble's authored entry |
| `bramble_intro_started`, material not taken | #20 reconstructs Bramble at the pre-take anchor and continues |
| Material taken, Bramble intro incomplete | Never charge again; reconstruct Bramble at the post-take/flee anchor and continue |
| Bramble intro complete, route not revealed | Place Bramble off-map and begin the route camera reveal |
| Route revealed, Act I incomplete | Restore the route marker and show the completion banner/cue, then commit completion |
| `act_one_complete == true` | Skip the entire sequence, restore route/residents/camera directly, select calm ambience, and leave control enabled |

Flags are written before their corresponding irreversible side effect. The
completion save is requested only after the route's stable visual state exists,
so a loaded completed save can never show a closed route.

## Audiovisual distinction

Dam completion remains a local construction payoff: water fade, slot bursts,
brief camera punch, and its existing sting. Chapter completion instead uses a
resident gathering, an upstream disturbance, a directional camera journey,
the persistent route landmark, a full-width chapter banner, and its own theme
cue. A player should be able to identify which event occurred with audio muted
or with the screen briefly obscured.

Issue #9's audio owner should expose ending-transition and calm-post-chapter
states, but #21 triggers the one-shot completion cue only when
`act_one_complete` changes live from false to true. Loading a completed save
selects calm ambience directly.

## Integration and regression checklist

- Exhaustively test eligibility with each prerequisite missing in turn.
- Trigger the sequence once and assert subsequent objective/signal emissions
  cannot trigger it again.
- Load at every row in the recovery table, including both sides of Bramble's
  material commit.
- Verify a zero-resource Bramble encounter still advances and never produces
  negative inventory.
- Verify completed saves restore a visible route, calm residents, normal
  camera/input, no banner replay, and no completion cue replay.
- Compare dam completion and chapter completion screenshots at 640×360.
- Complete the sequence using keyboard and physical gamepad before #21 closes.
- Record first-time-player recognition of the ending through the #15 playtest
  method.

## Definition of implementation-ready

Issue #21 can move from storyboard to code when #20 exposes an idempotent
Bramble encounter start/completion API and stable gathering/exit anchors. The
ending controller may then be implemented without editing resident movement or
duplicating Bramble's inventory logic.
