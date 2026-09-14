# Dialogue and Objective Schema

Status: **Implemented**
Milestone: **1 — Act I narrative vertical slice**

This document describes the data schema and runtime that let writers define
dialogue and objectives without editing gameplay scripts (roadmap item under
"Narrative foundation"). It covers the Resource classes under `scripts/story/`,
the `ActOneController` autoload that runs them, and the worked fixture in
`data/story/act1/`. It assumes familiarity with
[Dialogue style](dialogue-style.md) and [Cast](cast.md) - this document is
about the data shape, not the writing voice.

There is no dialogue/objective UI yet (see roadmap item "Add a dialogue
presentation..." and issue #18). `ActOneController` only tracks state and
emits signals; it never touches a scene, node, or UI control.

## Why Resources

Content lives as Godot `Resource` subclasses (`.tres` files), the same
data-driven approach the engine already uses for scenes and other assets.
A writer builds a dialogue or objective as a `.tres` resource - by hand, or by
using the editor's Inspector against these classes' `@export` fields - with
no GDScript required. `ActOneController.load_content()` then validates and
registers whatever was authored.

## The schema

All classes live in `scripts/story/`. Every identifier field (a flag name, an
objective id, a dialogue or choice id) must be a lowercase snake_case
identifier - see `StoryIdentifiers.is_valid()`. That, and the known-speaker /
known-resource lists, are the two small registries the rest of the schema
validates against.

### ObjectiveDefinition (`objective_definition.gd`)

A trackable Act I goal.

| Field | Type | Notes |
|---|---|---|
| `id` | String | Unique snake_case identifier. |
| `title` | String | Short player-facing name. |
| `description` | String | Player-facing detail. |
| `completion_type` | enum `MANUAL` \| `RESOURCE_AT_LEAST` | How the objective completes. |
| `resource` | String | `RESOURCE_AT_LEAST` only - one of `wood`, `stone`, `berries` (GameState's resources). |
| `target_amount` | int | `RESOURCE_AT_LEAST` only - must be positive. |

`MANUAL` objectives only complete when a `StoryEffect(COMPLETE_OBJECTIVE)`
targets them (a dialogue or scripted beat). `RESOURCE_AT_LEAST` objectives
complete themselves: `ActOneController` watches `GameState`'s
`wood_changed`/`stone_changed`/`berries_changed` signals and completes the
objective once the named resource reaches `target_amount` - nothing else has
to call `advance_objective()` by hand for the gathering case.

### DialogueDefinition (`dialogue_definition.gd`)

A speaker-led scene: an ordered list of `DialogueLine`s.

| Field | Type | Notes |
|---|---|---|
| `id` | String | Unique snake_case identifier. |
| `speaker` | String | Default speaker; must be a known cast member (see `StoryIdentifiers.KNOWN_SPEAKERS`). |
| `condition` | StoryCondition? | Gates whether `start_dialogue()` may begin this at all. |
| `lines` | Array[DialogueLine] | At least one. |

### DialogueLine (`dialogue_line.gd`)

One panel.

| Field | Type | Notes |
|---|---|---|
| `speaker` | String | Overrides the dialogue's default speaker for this line only; empty = use the default. |
| `text` | String | The line itself. Validation flags anything over ~40 words as likely malformed - see [Dialogue style](dialogue-style.md)'s 25-30 word guideline. |
| `condition` | StoryCondition? | Gates whether this line is reachable. |
| `effects` | Array[StoryEffect] | Applied the moment the line is shown. |
| `choices` | Array[DialogueChoice] | At most 3, matching [Dialogue style](dialogue-style.md)'s tone rule. |

### DialogueChoice (`dialogue_choice.gd`)

A concise response option.

| Field | Type | Notes |
|---|---|---|
| `id` | String | Unique among the choices on its line. |
| `tone` | enum `EARNEST` \| `PRACTICAL` \| `PLAYFUL` | Matches the three tones [Dialogue style](dialogue-style.md) allows. |
| `text` | String | The player's line. |
| `acknowledgement` | String | The speaker's reply to picking this choice. |
| `effects` | Array[StoryEffect] | Applied when the choice is picked. |

Per style guide, choices never branch the main story or hide a "wrong"
answer - they're free to share the same effects (see the fixture, where all
three tones set the same flag).

### StoryCondition (`story_condition.gd`)

A gate: `FLAG_TRUE`, `FLAG_FALSE`, `OBJECTIVE_ACTIVE`, or
`OBJECTIVE_COMPLETE`, each paired with a `target_id` (a flag name or
objective id). `null` means unconditional.

### StoryEffect (`story_effect.gd`)

A state change: `SET_FLAG`, `CLEAR_FLAG`, `START_OBJECTIVE`,
`ADVANCE_OBJECTIVE` (reads `amount`), or `COMPLETE_OBJECTIVE`, each paired
with a `target_id`.

## Validation ("fail clearly in development")

Every schema class has a `validate() -> Array[String]` method that checks its
own shape (valid identifiers, non-empty text, a known speaker, at most 3
choices, positive amounts, and so on) and returns a list of human-readable
problems. `ActOneController.register_objective()`/`register_dialogue()` call
`validate()` and additionally cross-check identifiers a bare Resource can't
verify on its own - that a `StoryCondition`/`StoryEffect` naming an objective
actually names one that was registered.

Any problem becomes a **failed `assert()`**, the same development-only
safety net `tests/smoke_test.gd` already relies on: it prints a clear
`SCRIPT ERROR: Assertion failed` with every problem found, and the
content is not registered. Like all `assert()` calls, this only runs in
debug/editor builds - the check has zero cost in an exported release build,
where malformed content should never ship in the first place. Register
objectives before dialogues that might reference them; `load_content()`
does this for you.

## ActOneController

Autoloaded as `ActOneController` (`scripts/autoload/act_one_controller.gd`),
registered in `project.godot` alongside `GameState`. It owns Act I's story
flags and objective progress - orchestration that used to have nowhere to
live except `GameState` (which stays focused on resources/dam/Lodge/energy).

Content is not auto-loaded; nothing currently calls `load_content()` outside
of `tests/story_test.gd`. Wiring a resident's interact() to actually offer
`start_dialogue()`, and hooking real Act I content into scene startup, is
follow-up work for later issues (#16/#17), not part of this data layer.

Key API:

- `load_content(objectives, dialogues)` / `register_objective()` /
  `register_dialogue()` - validate and register content.
- `start_dialogue(id)`, `advance_dialogue()`, `choose(choice_id)`,
  `get_current_line()`, `get_current_speaker()`, `get_active_dialogue_id()` -
  step through a dialogue. Matches [Dialogue style](dialogue-style.md)'s
  "ordinary dialogue never auto-advances" rule: nothing here advances on its
  own, including after a choice - a caller (eventually the dialogue UI)
  always calls `advance_dialogue()` explicitly.
- `start_objective(id)`, `advance_objective(id, amount)`,
  `complete_objective(id)`, `get_objective_status(id)`,
  `get_objective_progress(id)` - objective state, callable directly or
  reached indirectly through a `StoryEffect`.
- `get_flag(name)` - story flag state.
- Signals for a future UI to render, never a scene/node it manipulates
  itself: `flag_changed`, `objective_started`, `objective_progress_changed`,
  `objective_completed`, `dialogue_started`, `dialogue_line_shown`,
  `dialogue_choice_made`, `dialogue_ended`.

## Save/load

Status: **Implemented** (issue #8). Covers persistence only - there is still
no dialogue/objective UI to load *into* (issue #18); this is what lets a
future one resume correctly once it exists.

`SaveManager` (`scripts/autoload/save_manager.gd`) owns the save file and its
`save_version`, but not what's in the payload - that's assembled by
`Main.get_save_data()`/`apply_save_data()` from `GameState` and
`ActOneController`. Version 2 adds a `"story"` section, produced by
`ActOneController.get_save_data()`:

```gdscript
"story": {
    "flags": {"met_moss": true, ...},            # flag name -> bool
    "objectives": {                                # objective id -> progress
        "gather_starter_wood": {"status": "active", "current": 3},
    },
    "active_dialogue_id": "moss_intro",           # "" if none active
    "active_dialogue_line": 1,                    # index into that dialogue's lines, -1 if none active
}
```

**The mid-dialogue boundary**: a `DialogueLine`'s effects apply synchronously
the moment it's shown (`_advance_to_next_visible_line()`), so a session is
never saved "mid-effect" - only ever sitting on a fully-applied line, waiting
for `advance_dialogue()` or `choose()`. Saving the active dialogue's id and
line index is therefore enough to resume exactly there; `load_from_save()`
just re-points at that line without replaying anything.

**Restoring unknown ids** (an objective or dialogue id the save references
that isn't registered - removed/renamed content, or a save taken before any
content was loaded) is the documented player-safe fallback:
`ActOneController.load_from_save()` silently skips that id rather than
failing, so at worst the player loses an in-progress flag/objective/dialogue
instead of hitting a crash.

**Migrating version 1 saves**: version 1 (every save before this) has no
`"story"` key at all. `SaveManager._migrate_v1_to_v2()` (in
`scripts/autoload/save_manager.gd`) adds the section at its empty default -
narratively a no-op, since a v1 save was always written before any Act I
content existed to have flags or an active dialogue against. Migrations are
explicit, named functions keyed by source version in `SaveManager._MIGRATIONS`
and covered in `tests/smoke_test.gd`; a version with no registered migration
is treated as unreadable (`peek_slot()` returns `{}`) rather than guessed at.

## The fixture

`data/story/act1/` contains the worked example this schema was designed
against: `objective_gather_starter_wood.tres` (a `RESOURCE_AT_LEAST` wood
objective) and `dialogue_moss_intro.tres` (Moss's introduction - see
[Story outline](story-outline.md#act-i--willowbend)). Moss's closing line
starts the gathering objective via a `StoryEffect`. `tests/story_test.gd`
loads both, plays the dialogue end to end including a choice, and drives the
objective to completion by adding wood through `GameState` - proving the
schema and controller work together without any UI.
