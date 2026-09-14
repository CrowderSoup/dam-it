# Dam it! — Roadmap to 1.0

Last reviewed: 2026-09-14

Current phase: **Milestone 0 — Vision lock**

This roadmap turns the existing playable demo into a small, complete cozy
narrative builder. It is both a product definition and a development tracker:
new ideas should be evaluated against it before they become implementation
work.

The roadmap intentionally uses milestone exit criteria instead of calendar
dates. Dates will be more trustworthy after the first narrative vertical slice
reveals the team's actual content-production pace.

## North star

> Play as a young beaver restoring a chain of neglected wetlands. Build dams,
> reshape waterways, and bring habitats and a community back to life—then help
> the watershed weather one final storm.

The 1.0 target is a polished **2–4 hour**, mostly linear cozy adventure with
three connected regions, a small cast of recurring animal characters, a clear
ending, and optional free play after the credits.

This is a deliberately compact authored game, not an endless life simulator.
A player should be able to finish it, remember its characters, and see a
dramatically transformed world when they are done.

## Design pillars

Every substantial feature should strengthen at least one of these pillars. A
feature that strengthens none of them belongs outside 1.0.

1. **The world visibly heals.** Construction changes water, vegetation,
   wildlife, traversal, animation, and sound—not only counters in the HUD.
2. **Building solves changing problems.** Each region adds one meaningful new
   construction problem or decision instead of merely raising resource costs.
3. **Community is the reward.** Restored habitats attract named characters
   whose behavior and relationships evolve with the landscape.
4. **Pressure stays cozy.** Storms, fatigue, and scavenging ask for attention,
   but never erase major progress or create an unrecoverable fail state.
5. **Small, polished, and finishable.** A shorter experience with an ending is
   more valuable than a broad collection of half-developed simulation systems.

## The intended player experience

The full-game loop should be:

1. Meet a resident and understand a problem in the watershed.
2. Explore the region and inspect possible solutions.
3. Gather a modest amount of resources through varied, responsive actions.
4. Choose or construct an improvement.
5. Watch the water and habitat transform in a substantial payoff sequence.
6. See characters react, complete a relationship beat, and unlock the next
   problem or place.

Gathering supports this loop; it is not meant to be the primary source of
playtime. New content should add decisions, traversal, and character moments
before it adds larger material requirements.

## 1.0 scope envelope

These are planning constraints, not targets to exceed.

- **Length:** 2–4 hours for the main story; no grinding required.
- **World:** 3 authored regions connected into one watershed.
- **Structure:** prologue, 3 acts, a spring storm and runoff surge, epilogue,
  and post-credits free play.
- **Cast:** approximately 6 named residents, preferably using the frog, duck,
  fish, rabbit, butterfly, and raccoon already present.
- **Character content:** one compact arc per resident, changing ambient
  dialogue, and a visible home or activity in the restored world.
- **Construction vocabulary:** 3–4 well-developed build types across the whole
  game, plus cosmetic habitat improvements.
- **Resources:** keep the economy legible. Wood, stone, berries, and at most
  one region-specific resource unless playtesting proves another is necessary.
- **Progression:** a small number of upgrades that change capability or route
  choice; capacity increases alone are not enough.
- **Endings:** one authored ending with small acknowledgements of player
  choices. Branching endings are not required.
- **Platforms:** Free Web release for desktop browsers with keyboard and
  gamepad. Touch/mobile layouts, downloadable builds, and storefronts are
  outside the 1.0 baseline.

## Current foundation

The demo already proves the following and these should be preserved:

- [x] Responsive movement and a single context-sensitive interaction control.
- [x] Wood and stone gathering with depletion, respawn, feedback, and capacity.
- [x] A five-piece dam whose completion transforms the river into a pond.
- [x] A staged Lodge, cosmetic garden construction, and wildlife reveals.
- [x] Soft energy pressure, food, rest, pouch upgrades, leaks, and a raccoon
  event.
- [x] Three save slots, autosave, manual save, validation, and reset flow.
- [x] Keyboard and gamepad bindings.
- [x] Cohesive procedural visuals and sound effects.
- [x] Headless regression coverage of the complete demo loop.
- [x] Automated Web deployment.

The current demo becomes **Act I's mechanical foundation**. It should be
re-authored and expanded, not discarded.

## Working narrative shape

This outline gives production a direction while leaving names and individual
dialogue open for writing work.

### Prologue — The quiet creek

The player arrives at a diminished creek where old wetland habitats have
disappeared. A resident explains the immediate need for water and teaches the
player to observe the environment, gather materials, and make the first repair.
The player is given a personal reason to stay and restore the watershed.

### Act I — Willowbend

The existing map becomes the first complete chapter. The player constructs the
starter dam, creates the first pond, meets the frog and other returning
residents, and builds the first stage of a permanent home. The act ends with a
small community moment and a newly opened route upstream.

**Introduces:** gathering, fixed construction, pond transformation, energy,
rest, and resident requests.

### Act II — Aspen Meadow

Water reaches a broad meadow, but simply blocking the river would flood one
habitat while leaving another dry. The player learns a second construction verb
such as a channel gate or spillway and makes a legible habitat choice. The duck,
rabbit, and butterfly can turn this from an engineering puzzle into a conflict
between understandable needs.

**Introduces:** water distribution, one reversible or clearly previewed choice,
new traversal, and functional habitat improvements.

### Act III — Moraine Basin

The upper watershed is unstable after an older wildfire and littered with
deadfall and sediment. The raccoon is revealed as a displaced neighbor rather
than a permanent villain. The player combines earlier construction skills,
resolves the raccoon's arc, and prepares all three regions for spring runoff.

**Introduces:** combined building problems, a capability upgrade, storm
preparation, and the final relationship resolution.

### Finale — The spring surge

A warm storm accelerates the mountain snowmelt and tests the restored
watershed. This is an active but forgiving sequence: the player checks
vulnerable structures, helps residents, and sees earlier improvements slow and
spread the surge through the connected regions. Poor preparation may create
extra repairs or different character reactions, but it must not destroy hours
of work.

### Epilogue — A living watershed

The community gathers, the camera revisits the transformed regions, unresolved
optional requests are acknowledged, and credits roll. The completed save then
returns to calm free play with repairs, decorating, conversations, and any
unfinished side content still available.

## Milestones

### Milestone 0 — Vision lock

**Purpose:** settle the game's identity and production constraints before
building content that may not belong.

#### Product decisions

Approved brief:
[Milestone 0 — Product Decisions](docs/design/product-decisions.md). Record
future revisions there so implementation does not silently change the product.

- [x] Approve or revise the north-star pitch and 2–4 hour target.
- [x] Decide why the protagonist comes to the creek and what they personally
  want at the beginning.
- [x] Confirm the final story theme in one sentence.
- [x] Name the three regions and establish their visual identities.
- [x] Decide whether the player chooses a name or uses an authored identity.
- [x] Confirm whether construction choices are reversible, permanent, or only
  cosmetically acknowledged.
- [x] Confirm target release platforms and whether a storefront release is in
  scope.

#### Creative planning

Design index: [1.0 design documentation](docs/design/README.md).

- [x] Write a one-page story synopsis covering the opening, act turns, climax,
  and ending.
- [x] Give each resident a name, desire, conflict, relationship change, and
  habitat payoff.
- [x] Create a one-page visual reference for each region.
- [x] List the exact construction verbs and player upgrades planned for 1.0.
- [x] Establish tone rules for dialogue: length, humor, reading level, and how
  often characters interrupt play.

#### Production planning

- [x] Convert Milestone 1 into repository issues with owners or a clear next
  action.
- [x] Establish a repeatable external playtest method and feedback form.
- [x] Record a provisional baseline and friction points for the current demo;
  obtain the first valid human completion time through the asynchronous method.

Production practices and baseline records:
[Milestone 0 production planning](docs/production/README.md).

**Exit criteria:** the pitch, story synopsis, scope envelope, cast, region list,
and Act I content list can fit in a short design brief and do not contradict one
another.

### Milestone 1 — Act I narrative vertical slice

**Purpose:** prove that story, construction, and world transformation work
together in a polished 30–45 minute chapter.

#### Narrative foundation

- [ ] Add a dialogue presentation that supports keyboard, mouse, and gamepad.
- [ ] Add named speakers, portraits or expressive poses, and concise branching
  acknowledgements where useful.
- [x] Add data-driven dialogue and objective definitions so writing does not
  require editing gameplay scripts.
- [ ] Add story flags and objective progress to the save format, including a
  migration path from existing demo saves.
- [ ] Write and implement the prologue, frog introduction, dam completion
  reaction, Lodge beats, and chapter ending.

#### Goals and interaction UX

- [ ] Add a current-objective display and a small journal/history screen.
- [ ] Show contextual action prompts with resource costs and affordability.
- [ ] Explain unsuccessful interactions: insufficient resources, full pouch,
  unavailable rest, or locked construction.
- [ ] Replace the single temporary instruction banner with staged tutorials.
- [ ] Ensure tutorials do not reappear unnecessarily after loading a save.

#### Act I gameplay pass

- [ ] Reduce repetitive harvesting by tuning costs, yields, travel, and
  respawns around a 30–45 minute chapter target.
- [ ] Give the first dam at least one observation or preparation step beyond
  filling five identical slots.
- [ ] Make Lodge stages produce distinct functional or narrative payoffs.
- [ ] Turn the first raccoon encounter into an authored character beat; keep
  later scavenging events only if they remain enjoyable.
- [ ] Give returning residents visible routines or interactions after arrival.
- [ ] End the act with a celebration and an explicit chapter-complete state.

#### Technical foundation

- [ ] Replace the player's growing group-based interaction branch with a
  shared interaction contract that supplies action, prompt, cost, and failure
  feedback.
- [ ] Separate Act I orchestration from global campaign state.
- [ ] Introduce versioned save migrations and preserve existing saves where
  practical.
- [ ] Keep save serialization independent from browser-local storage so a
  future game library can exchange complete versioned save payloads.
- [ ] Add automated coverage for dialogue progression, objective completion,
  chapter completion, and mid-dialogue/mid-objective save loading.

#### Presentation

- [ ] Add an Act I ambient soundscape and at least a title, exploration, and
  transformation music cue.
- [ ] Add a real walk cycle or equivalent movement animation.
- [ ] Give the dam completion and chapter ending distinct audiovisual payoffs.
- [ ] Perform a readability pass on HUD scale, contrast, prompts, and dialogue.

**Exit criteria:** a first-time player can start a new save, understand their
motivation and current objective without outside instructions, finish Act I in
roughly 30–45 minutes, describe at least one resident, and recognize the end of
the chapter. The entire path works on keyboard and gamepad and survives saving
and loading at every major step.

### Milestone 2 — Region pipeline and Act II

**Purpose:** prove that the game can efficiently produce new authored regions
and that the second act meaningfully expands play.

#### Region pipeline

- [ ] Define a reusable region scene structure for water, resources,
  construction, residents, objectives, boundaries, and entry points.
- [ ] Move region-specific event scheduling out of the global main script.
- [ ] Support transitions between regions and restore the correct region and
  position when loading.
- [ ] Create lightweight editor/debug tools for jumping to objectives, granting
  resources, and resetting a region.
- [ ] Document how to add a resident, objective, build site, and save field.

#### Act II content

- [ ] Build Aspen Meadow with a distinct palette, layout, ambience, and
  traversal identity.
- [ ] Implement and tutorialize the water-distribution construction verb.
- [ ] Preview consequences clearly before the habitat choice is made.
- [ ] Add the duck, rabbit, and butterfly story beats and post-restoration
  routines.
- [ ] Add at least one optional resident request that changes the environment.
- [ ] Connect Act I improvements to a useful Act II capability or shortcut.
- [ ] Finish Act II with a transformation sequence and narrative turn toward
  the coming storm.

#### Validation

- [ ] Playtest the first two acts back-to-back for pacing and repetition.
- [ ] Verify that gathering time does not grow merely because Act II is later.
- [ ] Test every meaningful habitat outcome and its save/load behavior.
- [ ] Add regression coverage for region transitions and region state.

**Exit criteria:** two regions form a coherent 60–120 minute experience, Act II
requires different thinking from Act I, and adding the second region has
produced a documented, reusable content workflow.

### Milestone 3 — Act III, finale, and epilogue

**Purpose:** make the game complete from opening through credits.

#### Act III

- [ ] Build Moraine Basin with its own visual and traversal identity.
- [ ] Implement burn-debris or bank-stability problems using existing verbs
  in a new combination.
- [ ] Deliver the final capability upgrade before the player needs it.
- [ ] Complete the raccoon relationship arc.
- [ ] Give each earlier resident a role in preparing the watershed.
- [ ] Provide a clear point-of-no-return warning before the finale, while
  allowing the player to continue optional preparation.

#### Finale and ending

- [ ] Build a scripted, forgiving spring-surge sequence spanning the three
  regions.
- [ ] Reflect earlier improvements through easier repairs, protected habitats,
  alternate dialogue, or visual details.
- [ ] Ensure the finale remains recoverable at zero resources and low energy.
- [ ] Implement the community celebration, transformed-world recap, credits,
  and completed-save marker.
- [ ] Return completed saves to stable post-credits free play.

#### Whole-game pacing

- [ ] Balance the full resource economy around decisions rather than grind.
- [ ] Remove or vary repeated tasks that no longer teach, surprise, or create a
  meaningful choice.
- [ ] Ensure upgrades arrive early enough to be enjoyed.
- [ ] Confirm optional content remains optional and cannot obscure the main
  objective.

**Exit criteria:** the game is playable from new save to credits, all required
content is present, all character arcs resolve, and a completed save can safely
continue. Missing work after this milestone should be polish, balance, bugs,
and release support—not new core content.

### Milestone 4 — Alpha: content complete

**Purpose:** stabilize and make the complete game understandable and robust.

- [ ] Conduct blind playtests with players unfamiliar with the README.
- [ ] Track completion time, objective confusion, abandon points, repeated
  inputs, and favorite moments.
- [ ] Resolve progression blockers and common soft locks.
- [ ] Test save/load at every chapter boundary and during every multi-step
  objective.
- [ ] Add backup/recovery behavior for interrupted or corrupt saves.
- [ ] Complete keyboard, mouse, and gamepad navigation for every screen.
- [ ] Add settings for master/music/effects volume, fullscreen/window mode,
  resolution where applicable, and control rebinding.
- [ ] Add adjustable text size, reduced camera motion/flash options, and
  color-independent status cues.
- [ ] Prepare all player-facing text for localization even if 1.0 ships in one
  language.
- [ ] Finish music, ambience, sound effects, animation, and environmental art.
- [ ] Perform a performance pass on the minimum supported hardware and Web.

**Exit criteria:** no known progression blockers or data-loss bugs; every
screen is usable without a mouse; all final content and settings exist; the
remaining bug list is triaged and finite.

### Milestone 5 — Beta and release candidate

**Purpose:** validate distribution, presentation, and release quality without
expanding scope.

- [ ] Create and test the Web release across the supported desktop-browser
  matrix.
- [ ] Test first launch, upgrade from an older save, returning play, and clear
  messaging when browser storage is unavailable.
- [ ] Complete credits, licenses, privacy disclosures if needed, and version
  display.
- [ ] Add crash/error logging appropriate to each target without collecting
  unnecessary personal data.
- [ ] Verify pause behavior, focus loss, controller disconnect/reconnect, and
  unusual display aspect ratios.
- [ ] Run a final accessibility and photosensitivity review.
- [ ] Prepare store/page copy, screenshots, trailer footage, capsule art, and a
  support contact if a public release page is in scope.
- [ ] Run a closed beta on release builds rather than editor builds.
- [ ] Fix release-blocking defects; defer non-blocking new ideas to post-1.0.
- [ ] Tag and archive the final tested release commit.

**Exit criteria:** the exact distributable builds have completed the full QA
matrix, no release-blocking issues remain, store/download materials accurately
represent the game, and the version shipped is the version tested.

## Cross-cutting workstreams

These are quality bars applied throughout the milestones rather than saved for
one late polish pass.

### Story and writing

- Keep routine conversations short enough that returning to a character feels
  pleasant, not expensive.
- Prefer dialogue triggered by visible world changes over exposition about
  events the player did not witness.
- Let every resident want something besides “bring me materials.”
- Use optional follow-up conversations for flavor; keep required information in
  the primary path and objective UI.
- Track speaker voice, facts, relationships, and unlocked lines in a compact
  narrative bible.

### Economy and progression

- Measure time spent gathering, traveling, deciding, building, and talking in
  playtests.
- Avoid costs that require waiting for the same nearby nodes to respawn.
- Prefer upgrades that enable a new action, route, or strategy over larger
  numerical capacity.
- Provide useful resource sinks after critical construction is complete, but do
  not require indefinite upkeep to see the ending.
- Let players understand costs before committing to travel or construction.

### World and level design

- Give each region a landmark visible from its main routes.
- Place objectives so exploration teaches the geography instead of causing
  blind searching.
- Change music, ambience, wildlife, plants, and traversal after restoration.
- Keep important interactables visually distinct without relying only on
  color.
- Revisit earlier regions with new dialogue or shortcuts so the connected
  watershed feels like one world.

### Engineering and saves

- Keep global state limited to campaign-wide facts; region scenes own regional
  behavior.
- Store stable IDs in save data rather than relying only on scene node names.
- Every save-schema change includes a migration and a malformed-data test.
- Every objective can be resumed safely after quitting between its steps.
- Add automated tests at system boundaries; use playtests for feel and
  presentation rather than attempting to automate them away.

### Accessibility and input

- All required actions must be reachable with keyboard alone and gamepad alone.
- Never encode required information through color, audio, or animation alone.
- Dialogue must support pause, advance, and readable timing without forcing
  speed.
- Camera pulses, shake, flashes, and rapid motion must respect reduced-motion
  settings.
- Prompts display the player's current binding, not a hard-coded key name.

## Explicitly outside 1.0

These ideas may be revisited after release, but should not enter active 1.0
work unless they replace an existing scoped feature.

- Procedural or randomized worlds.
- Multiplayer or online services.
- Combat, health, death, or irreversible game-over states.
- Farming calendars, seasons, breeding, or a full life-sim schedule.
- Large inventory grids, equipment rarity, or a broad crafting recipe tree.
- Multiple substantially branching campaigns or endings.
- Voice acting.
- User-generated content or mod support.
- Achievements, trading cards, cloud saves, or platform-specific extras before
  the base release is stable.
- Mobile-specific controls and layouts.

## Development tracking rules

### Issue structure

Use one milestone label and one workstream label on each implementation issue:

- Milestones: `M0-vision`, `M1-vertical-slice`, `M2-act-2`, `M3-complete-game`,
  `M4-alpha`, `M5-release`, `post-1.0`
- Workstreams: `story`, `gameplay`, `world`, `ui-ux`, `art-audio`, `engineering`,
  `accessibility`, `qa-release`
- Priority: `P0-blocker`, `P1-required`, `P2-polish`, `P3-later`

An issue should describe a player-visible outcome, its acceptance criteria,
save/load implications, input requirements, and tests. Split work that cannot
be reviewed or playtested as one coherent change.

### Definition of done

A feature is done only when:

- It works in real play, not only through a direct test call.
- It has complete keyboard and gamepad behavior.
- Its success, cost, and failure states have clear player feedback.
- It survives save/load and reset where applicable.
- Relevant regression tests pass and new stateful logic is covered.
- Its final—or intentionally temporary—visual and audio treatment is explicit.
- Player-facing text and documentation are updated.
- It has been exercised in the surrounding chapter, not only in isolation.

### Scope control

- Keep only one large gameplay or narrative system in active implementation at
  a time; smaller art, writing, and test work may proceed alongside it.
- Finish and playtest the current milestone before pulling work from the next.
- A new 1.0 feature must either be required by a pillar or replace something of
  comparable cost already in scope.
- Record attractive but nonessential ideas under `post-1.0` instead of allowing
  them to interrupt the active milestone.
- Review this roadmap at every milestone exit. Update it deliberately rather
  than silently allowing implementation to redefine the product.

## Immediate next actions

1. Resolve the seven product decisions in Milestone 0.
2. Write the one-page synopsis and compact resident bible.
3. Record two or three blind playthroughs of the current demo and measure where
   players become confused or bored.
4. Turn the Milestone 1 checkboxes into small issues, beginning with dialogue,
   objectives, interaction prompts, and versioned story saves.
5. Build only enough narrative infrastructure to ship the Act I slice, then
   validate it before starting Aspen Meadow.
