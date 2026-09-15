# Act I regression and exit-criteria matrix

Status: living test plan for issue #15. Automated coverage reflects the current
Willowbend build; human exit-criteria rows remain pending until the integrated
Milestone 1 release candidate exists.

This matrix keeps the suite boundaries intentional. `smoke_test` owns gameplay
mechanics and the save-file envelope, `story_test` owns the story runtime,
`narrative_test` owns the authored happy path, and `story_boundary_test` owns
ordering plus Willowbend-specific restoration checkpoints. A case should move
to a different suite only when its production ownership changes.

## Automated coverage

| Area | Case | Expected result | Coverage | Status |
| --- | --- | --- | --- | --- |
| Dialogue | Load all shipped Willowbend definitions | Every speaker, condition, effect, choice, and objective reference validates | `narrative_test`, `story_test` | Automated |
| Dialogue | Play the eight authored conversations in story order | Each becomes available only at its intended beat and applies its effects once | `narrative_test` | Automated |
| Dialogue | Try Eddy, pond-return, or Marnie dialogue early | The condition blocks the conversation without changing story state | `story_boundary_test` | Automated |
| Dialogue | Save during the arrival and resume | The exact panel returns; advancing applies the next panel's effect once | `story_boundary_test` | Automated |
| Dialogue | Save on Moss's choice and after choosing | Choice input and the acknowledgement phase both resume without replaying effects | `story_test` | Automated |
| Dialogue UI | Advance, choose, pause-menu exclusion, keyboard/gamepad focus | The box pauses play, exposes one valid focus path, and restores normal UI modes on close | `dialogue_ui_test` | Automated |
| Objectives | Complete the Willowbend objective chain | All ten objectives activate and complete in order through resident and world interactions | `narrative_test` | Automated |
| Objectives | Emit premature dam/Lodge signals | Inactive later objectives remain inactive; signal arguments cannot manufacture progress | `story_boundary_test` | Automated |
| Objectives | Read water and gather wood before their prompts | The active earlier objective is unchanged; already-earned requirements reconcile once when reached | `story_boundary_test` | Automated |
| Objectives | Re-announce an absolute dam total | Repair progress remains the authoritative total instead of double-counting | `story_boundary_test` | Automated |
| Objectives | Resource, dam, Lodge, pouch, energy, garden, and challenge mechanics | Their existing behavior and save state remain intact independently of narrative coverage | `smoke_test` | Automated |
| Save boundary | `meet_moss` active | Completed prefix, current id/progress, and inactive suffix restore exactly | `story_boundary_test` | Automated |
| Save boundary | `gather_starter_wood` active at 3/6 | Same contract; partial resource progress restores | `story_boundary_test` | Automated |
| Save boundary | `read_willowbend_water` active | Same contract | `story_boundary_test` | Automated |
| Save boundary | `repair_willowbend_dam` active at 2/5 | Same contract; counted repair progress restores | `story_boundary_test` | Automated |
| Save boundary | `witness_pond_return` active | Same contract | `story_boundary_test` | Automated |
| Save boundary | `check_eddy_route` active | Same contract | `story_boundary_test` | Automated |
| Save boundary | `build_lodge_foundation` active | Same contract | `story_boundary_test` | Automated |
| Save boundary | `talk_moss_home` active | Same contract | `story_boundary_test` | Automated |
| Save boundary | `finish_willowbend_lodge` active at stage 2/3 | Same contract; counted Lodge progress restores | `story_boundary_test` | Automated |
| Save boundary | `answer_marnie` active | Same contract | `story_boundary_test` | Automated |
| Save boundary | Narrative spine completed | Final objective and existing completion/request flags restore without inventing chapter completion | `story_boundary_test` | Automated |
| Migration | Read a version-1 save | Existing fields survive and an empty version-2 story payload is added | `smoke_test` | Automated |
| Migration | Read a version-2 save with an old pouch tier | Any prior upgrade becomes the one Reinforced Pouch and resources clamp to its capacity | `smoke_test` | Automated |
| Migration | Read a future-version or unversioned save | The unsupported payload is rejected rather than guessed at | `smoke_test` | Automated |
| Migration | Read unknown/removed story ids | Known data survives; removed objective/dialogue ids are ignored safely | `story_test` | Automated |
| Migration | Read malformed/out-of-range scalar data | Values use safe defaults or clamp to supported limits | `smoke_test` | Automated |

## Pending integrated coverage

These cases must not be simulated with placeholder flags. Their production
state and presentation belong to the linked feature issues.

| Area | Case | Exit condition | Status / dependency |
| --- | --- | --- | --- |
| Lodge/residents | Restore each implemented resident routine and Bramble introduction boundary | Moss, Eddy, and Marnie derive calm routes/dialogue; Bramble restores before/after its committed loss or as complete without replay | `resident_test`, `bramble_encounter_test`; automated |
| Chapter | Become eligible for the ending | Stage three, pond response, Eddy's check, Marnie's request/Moss acknowledgement, clear overlays, and unstarted completion state are all required | `narrative_test`, `story_boundary_test`; automated #20 handoff shipped |
| Chapter | Save before, during, and after the ending | The sequence resumes only at supported boundaries; `act_one_complete` cannot fire twice | Pending #21 |
| Chapter | Finish and remain in calm post-chapter play | Controls, resident interactions, saves, and the next-region hook settle into the authored final state | Pending #21 |
| Web / keyboard | Complete Act I in the public Web build | No blockers; roughly 30–45 minutes without outside instructions | Manual release-candidate session |
| Web / gamepad | Complete Act I with a physical gamepad | Every required action and menu/dialogue focus path is reachable | Manual release-candidate session |
| First-time comprehension | Describe a resident and Willowbend's ecological change | Player recalls at least one resident and connects their action to the changed wetland | Manual playtest using `playtest-method.md` |
| Ending recognition | Identify that Act I ended | Player recognizes a distinct chapter ending without being told | Manual playtest after #21 |

When #20 or #21 lands, add its focused cases alongside that feature, then
update this table from pending to automated. The final human rows are evidence
requirements, not substitutes for headless coverage.
