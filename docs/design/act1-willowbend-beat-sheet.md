# Act I: Willowbend implementation beat sheet

Status: implemented narrative spine for issue #17. Resident schedules,
multi-stage habitat routines, Bramble's entrance, and the chapter-ending
celebration remain owned by issues #20 and #21.

| Order / conversation | Trigger and required world state | Participants | Purpose | Max panels | Objective / state effect |
| --- | --- | --- | --- | ---: | --- |
| 1. Willowbend arrival | Fresh or pre-story save; depleted creek and broken dam | Hazel (letter), Reed, Moss | Tie Reed to Hazel and the remembered Willowbend, establish the private-home goal, then challenge the assumption that the reach is empty | 4 | Start `meet_moss` |
| 2. Moss introduction | `meet_moss` active; Moss at the last shallow pool | Moss, Reed | Let Reed choose a tone; establish Moss's earned skepticism and the first small proof of commitment | 4, including choice acknowledgement | Complete `meet_moss`; set `met_moss`; start `gather_starter_wood` |
| 3. Supplies reminder | 6 wood gathered; `read_willowbend_water` active; gauge unread | Moss | Connect Hazel's gauge to the keystone gap without blocking the free observation action | 2 | No new state; contextual reminder only |
| 4. Pond returns | All 5 dam pieces built; `witness_pond_return` active; pond and Eddy visible | Moss, Reed, Eddy | Make restoration socially and ecologically legible; complicate “dam complete” with Eddy's route observation | 4 | Complete `witness_pond_return`; set `pond_restored`; start `check_eddy_route` |
| 5. Eddy flow check | `check_eddy_route` active; Eddy visible in restored pond | Eddy, Reed | Confirm that observing the current produced a porous route that serves both pond and fish | 3 | Complete `check_eddy_route`; start `build_lodge_foundation` |
| 6. Lodge foundation | Lodge stage 1; `talk_moss_home` active | Moss, Reed | Move Moss from skepticism toward belonging when Reed names the other residents as neighbors | 3 | Complete `talk_moss_home`; start `finish_willowbend_lodge` |
| 7. Lodge walls | Lodge stage 2; `finish_willowbend_lodge` active; beat not previously seen | Moss, Reed | Briefly reconnect home-building to checking the living water; keep Moss's change tied to visible results | 2 | Set `moss_saw_lodge_walls`; clear one-time availability flag |
| 8. Upstream call | Lodge stage 3; `answer_marnie` active; Marnie visible | Marnie, Moss, Reed | Present Aspen Meadow's need while having Reed explicitly carry Eddy's “look first” lesson forward | 5 | Complete `answer_marnie`; set `aspen_meadow_requested` and `willowbend_narrative_spine_complete` |

Non-conversation objectives connect those scenes: gather 6 wood, read the
river gauge, repair 5 dam pieces, and build Lodge stages 1–3. Their counts are
shown in the HUD/journal where a target exists.

## Runtime boundaries

- Conversations are data resources under `data/story/act1/`; world scripts
  report only their existing water, dam, and Lodge signals.
- Moss, Eddy, and Marnie are static interaction anchors. Their movement,
  schedules, changing ambient barks, and stage-specific behaviors are #20.
- Completing this spine does not set a chapter-complete flag, lock controls,
  launch a celebration, or transition regions. Those are #21's ending flow.
- Dam and Lodge objective progress is set from absolute world totals so save
  restoration and repeated signals cannot double-count work.

## Save/load checkpoints

The existing controller payload is sufficient for every authored boundary:
mid-dialogue, active objective, counted dam/Lodge progress, and completion
flags. Main registers all content before loading, restores the world, then
reconciles active objectives against final world totals. Older saves with no
story progress enter through the arrival beat instead of silently skipping it.

## Regression contract

`tests/narrative_test.tscn` drives the complete sequence through resident
interactions and gameplay signals. Existing story, dialogue UI, journal, and
mechanics suites remain required so authored integration cannot weaken the
underlying systems.
