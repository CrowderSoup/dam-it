# Current demo baseline

## Status

**Provisional internal baseline — 2026-09-14**

- Build: `f3e84c9` (merged Milestone 0 creative-planning revision)
- Scope: fresh save through the completed Lodge and both garden spots
- Maximum session length: 45 minutes
- Validation: three independent role-based walkthroughs plus the existing
  headless smoke test

The smoke test validates that the mechanical sequence is completable and that
major state transitions work. It does not provide human completion time,
comprehension, enjoyment, or accessibility evidence.

The role-based walkthroughs are useful early reviews, but they are not a
substitute for sessions with real target players or physical gamepad hardware.
External validation therefore remains pending and should use the documented
[playtest method](playtest-method.md).

## Review methods and limitations

| Perspective | Method | Directly observed | Completion |
| --- | --- | --- | --- |
| Target-age reader (11–12) | Player-facing instructions and cognitive walkthrough of the native build and implemented loop | Native launch; shared-desktop focus prevented reliable control | Not completed; no valid time |
| Adult cozy-game player | Scene, progression, and feedback review plus native and public-Web launch attempts | Native launch and Web loader | Not completed; no valid time |
| Gamepad-oriented player | Isolated headless-Chromium probe plus input-map and focus-flow review | Fresh save, movement, one tree harvest, and pause-menu navigation | Partial 28.25-second probe; not a completion time |

The perspectives were reviewed independently before synthesis. They are agent
role simulations, not human demographic samples. No physical gamepad was
available, and simultaneous native windows shared one desktop session; those
limitations are why the reports are classified as an internal baseline.

## Completion times

**No trustworthy player completion time was produced.** None of the three
passes completed the defined demo scope under reliable input conditions. The
28.25-second browser probe establishes that a fresh save can be entered and
controlled in headless Chromium, but it is not representative play and must not
be reported as a completion time.

This gap is intentionally visible. The first asynchronous human response that
reaches a stopping point should establish the initial observed time; later
responses should be preserved individually rather than averaged prematurely.

## Friction inventory

### Critical

- **A likely pause button can erase the active save.** Gamepad Start is mapped
  to `restart`, while Back opens the menu. The restart handler immediately
  deletes the current slot without confirmation. Keyboard `R` uses the same
  destructive path. This is tracked in
  [issue #22](https://github.com/CrowderSoup/dam-it/issues/22).

### High

- **The first objective is under-explained.** The temporary hint teaches some
  controls, while `Dam 0/5` and `Lodge Locked` require a new player to infer
  gathering, costs, the dam-site location, and the sequence of goals.
- **Failed construction is silent.** An unaffordable or unavailable action can
  produce no explanation, leaving position, input, cost, and game state equally
  plausible causes.
- **Controller onboarding is absent.** The opening hint names keyboard input
  only and does not explain controller movement, interact, or pause.
- **The ecosystem lesson lacks a character/story interpretation.** The pond,
  plants, and arriving animals demonstrate change, but silent critter unlocks
  can read as a reward checklist rather than an ecological relationship.

### Moderate

- **Repetition precedes the main payoff.** The dam requires 10 wood and 5
  stone; the Lodge adds 15 wood and 9 stone, all using the same repeated gather
  actions plus travel.
- **One action has many invisible meanings.** Highlighting helps, but there is
  no visible verb or cost, and nearest-target selection may be opaque near
  clustered objects.
- **Several upkeep systems arrive together.** Energy drain, pond food, Lodge
  construction, storms, and raccoons activate after the dam, potentially
  competing with discovery of the restored pond.
- **Pause opens on Save Game.** Focusing **Save Game** rather than **Resume** is
  an unexpected default for keyboard/controller navigation.
- **Controls cannot be reviewed or remapped.** The six-second hint disappears,
  and there is no persistent controls reference. Physical-browser gamepad
  activation and reconnect behavior remain unverified.

## Strengths to preserve

- The pond reveal is the clearest current delight and teaching moment: water
  visibly spreads, traversal changes, plants appear, and the Lodge is revealed
  with sound, particles, and camera feedback.
- Gathering has responsive highlight, shake, sound, particles, depletion, and
  quick regrowth feedback.
- The loop is forgiving: renewable resources, no pre-dam energy pressure, no
  hard failure, recoverable upkeep, and persistent saves.
- Staged Lodge construction and animal arrivals give resources a visible
  purpose, even before those arrivals receive narrative context.
- The simple movement-plus-interact vocabulary is approachable, and existing
  title/menu focus behavior provides a useful base for controller support.

## What the current build already validates

- A player can gather wood and stone with one context-sensitive action.
- Five constructed dam pieces trigger a visible pond transformation.
- The Lodge has three construction stages and reveals residents over time.
- Two garden spots provide finite post-Lodge goals.
- Progress can be saved and loaded from three slots.
- Keyboard and gamepad actions are defined in the input map.
- The full mechanical sequence is covered by a headless regression test.

## Milestone 1 comparison targets

Act I should replace this provisional baseline with observed first-time-player
evidence that:

- the chapter takes roughly 30–45 minutes;
- motivation and the current objective are understandable without outside
  explanation;
- gathering supports construction rather than dominating playtime;
- the player can identify at least one resident and explain how the restored
  wetland changed;
- the chapter ending is unmistakable; and
- the complete route works with both keyboard and a physical gamepad.
