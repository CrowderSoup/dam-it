extends Node
## Headless regression test for the data-driven dialogue/objective
## foundation (ActOneController + the story/ Resource schema). Companion to
## tests/smoke_test.gd - same conventions, separate file because this
## exercises story data rather than the moment-to-moment gameplay loop.
##
## Run with:
##   godot --headless --path . tests/story_test.tscn
## It exits 0 and prints ALL STORY TESTS PASSED on success, or hits a
## SCRIPT ERROR: Assertion failed on the first broken behavior.

func _ready() -> void:
	GameState.reset()
	ActOneController.reset()

	# --- Loading the Act I fixture: Moss's introduction + the first
	# gathering objective (data/story/act1/) ---
	var meet_objective: ObjectiveDefinition = load("res://data/story/act1/objective_meet_moss.tres")
	var objective: ObjectiveDefinition = load("res://data/story/act1/objective_gather_starter_wood.tres")
	var dialogue: DialogueDefinition = load("res://data/story/act1/dialogue_moss_intro.tres")
	assert(meet_objective != null and objective != null and dialogue != null, "fixture .tres files failed to load")

	var objectives: Array[ObjectiveDefinition] = [meet_objective, objective]
	var dialogues: Array[DialogueDefinition] = [dialogue]
	ActOneController.load_content(objectives, dialogues)
	assert(ActOneController.has_objective("gather_starter_wood"))
	assert(ActOneController.has_dialogue("moss_intro"))
	print("OK: the Moss-intro fixture loads and validates without error")

	# --- Driving the dialogue end to end ---
	var started_events: Array = []
	ActOneController.dialogue_started.connect(func(id): started_events.append(id))
	var line_shown_events: Array = []
	ActOneController.dialogue_line_shown.connect(func(id, index): line_shown_events.append([id, index]))
	var dialogue_ended_events: Array = []
	ActOneController.dialogue_ended.connect(func(id): dialogue_ended_events.append(id))

	ActOneController.start_objective("meet_moss")
	ActOneController.start_dialogue("moss_intro")
	assert(ActOneController.get_active_dialogue_id() == "moss_intro")
	assert(ActOneController.get_current_speaker() == "moss")
	assert(ActOneController.get_current_line().text.begins_with("So you are Hazel's grandkit"))
	assert(started_events == ["moss_intro"])
	assert(line_shown_events == [["moss_intro", 0]])
	print("OK: start_dialogue() emits dialogue_started and begins the fixture dialogue on its first line")

	ActOneController.advance_dialogue()
	var current_line := ActOneController.get_current_line()
	assert(current_line.choices.size() == 3, "expected 3 response choices, got %d" % current_line.choices.size())
	print("OK: advancing reaches the line with Moss's three response choices")

	var choice_events: Array = []
	ActOneController.dialogue_choice_made.connect(func(id, choice_id, ack): choice_events.append([id, choice_id, ack]))
	assert(not ActOneController.get_flag("met_moss"), "met_moss should not be set before a choice is made")
	ActOneController.choose("practical_start_together")
	assert(ActOneController.get_flag("met_moss"), "choosing a response should set the met_moss flag")
	assert(choice_events == [["moss_intro", "practical_start_together", "Practical. I can work with practical."]])
	print("OK: choosing a response applies its effect and reports its acknowledgement")

	ActOneController.advance_dialogue()
	assert(ActOneController.get_current_line().text.begins_with("Fine."))
	assert(ActOneController.get_objective_status("gather_starter_wood") == "active", "the closing line's effect should have started the gathering objective")
	print("OK: the dialogue's closing line starts the first gathering objective")

	ActOneController.advance_dialogue()
	assert(ActOneController.get_active_dialogue_id() == "", "the dialogue should have ended after its last line")
	assert(dialogue_ended_events == ["moss_intro"])
	print("OK: advancing past the last line ends the dialogue and emits dialogue_ended")

	# --- Driving the objective to completion via ordinary gameplay state ---
	var progress_events: Array = []
	ActOneController.objective_progress_changed.connect(func(id, current, target): progress_events.append([id, current, target]))
	var completed_events: Array = []
	ActOneController.objective_completed.connect(func(id): completed_events.append(id))

	GameState.add_wood(3)
	assert(ActOneController.get_objective_progress("gather_starter_wood") == 3)
	assert(progress_events.has(["gather_starter_wood", 3, 6]))
	assert(completed_events.is_empty(), "the objective should not complete before reaching its target")
	print("OK: gathering wood advances the active objective's progress")

	GameState.add_wood(3)
	assert(ActOneController.get_objective_status("gather_starter_wood") == "completed")
	assert(completed_events == ["gather_starter_wood"], "reaching the target amount should complete the objective exactly once")
	GameState.add_wood(1)
	assert(completed_events == ["gather_starter_wood"], "an already-completed objective should not re-fire objective_completed")
	print("OK: reaching the target wood amount completes the objective exactly once")

	# --- Save/load: mid-objective and mid-dialogue boundaries (issue #8) ---
	# See ActOneController.get_save_data()/load_from_save() and
	# docs/design/dialogue-schema.md#save-load.
	GameState.reset()
	ActOneController.reset()
	ActOneController.load_content(objectives, dialogues)
	ActOneController.start_objective("meet_moss")

	# Mid-objective: active, with partial progress, no dialogue active.
	ActOneController.start_dialogue("moss_intro")
	ActOneController.advance_dialogue()
	ActOneController.choose("practical_start_together")
	ActOneController.advance_dialogue()  # closing line starts gather_starter_wood
	ActOneController.advance_dialogue()  # past the last line - ends the dialogue
	assert(ActOneController.get_active_dialogue_id() == "", "the dialogue should have ended before this boundary")
	assert(ActOneController.get_objective_status("gather_starter_wood") == "active")
	GameState.add_wood(3)
	assert(ActOneController.get_objective_progress("gather_starter_wood") == 3)

	var mid_objective_save: Dictionary = ActOneController.get_save_data()
	assert(mid_objective_save["flags"]["met_moss"] == true, "the flag set by the earlier choice should be in the save data")
	assert(mid_objective_save["objectives"]["gather_starter_wood"] == {"status": "active", "current": 3})
	assert(mid_objective_save["current_objective_id"] == "gather_starter_wood")
	assert(mid_objective_save["active_dialogue_id"] == "", "the dialogue had already ended before this save")

	ActOneController.reset()
	assert(not ActOneController.has_objective("gather_starter_wood"), "reset() should clear registered content too")
	ActOneController.load_content(objectives, dialogues)  # a fresh session re-registers content before restoring
	ActOneController.load_from_save(mid_objective_save)
	assert(ActOneController.get_flag("met_moss"), "loading should restore the flag")
	assert(ActOneController.get_objective_status("gather_starter_wood") == "active")
	assert(ActOneController.get_objective_progress("gather_starter_wood") == 3, "loading should restore mid-objective progress")
	assert(ActOneController.get_current_objective_id() == "gather_starter_wood", "loading should restore which objective the HUD calls current")
	assert(ActOneController.get_active_dialogue_id() == "", "no dialogue was active when this was saved")
	print("OK: save/load restores flags, progress, and the current objective")

	# Major objective boundary: completed.
	GameState.add_wood(3)
	assert(ActOneController.get_objective_status("gather_starter_wood") == "completed")
	var completed_objective_save: Dictionary = ActOneController.get_save_data()
	assert(completed_objective_save["objectives"]["gather_starter_wood"]["status"] == "completed")
	ActOneController.reset()
	ActOneController.load_content(objectives, dialogues)
	ActOneController.load_from_save(completed_objective_save)
	assert(ActOneController.get_objective_status("gather_starter_wood") == "completed", "loading should restore a completed objective")
	print("OK: save/load restores a completed-objective boundary")

	# Mid-dialogue boundary: saved on the line with the three response
	# choices, before any choice has been made.
	GameState.reset()
	ActOneController.reset()
	ActOneController.load_content(objectives, dialogues)
	ActOneController.start_objective("meet_moss")
	ActOneController.start_dialogue("moss_intro")
	ActOneController.advance_dialogue()
	var mid_dialogue_line := ActOneController.get_current_line()
	assert(mid_dialogue_line.choices.size() == 3, "should be sitting on the choice line before saving")

	var mid_dialogue_save: Dictionary = ActOneController.get_save_data()
	assert(mid_dialogue_save["active_dialogue_id"] == "moss_intro")
	assert(mid_dialogue_save["active_dialogue_line"] == 1)
	assert(mid_dialogue_save["active_dialogue_choice"] == "")
	assert(not mid_dialogue_save["flags"].get("met_moss", false), "no choice has been made yet at this boundary")

	ActOneController.reset()
	ActOneController.load_content(objectives, dialogues)
	ActOneController.load_from_save(mid_dialogue_save)
	assert(ActOneController.get_active_dialogue_id() == "moss_intro", "loading should resume the active dialogue")
	assert(ActOneController.get_current_line().text == mid_dialogue_line.text, "loading should resume on the exact saved line")
	assert(ActOneController.get_current_line().choices.size() == 3)
	# Confirm the resumed dialogue is genuinely interactive, not just
	# cosmetically restored.
	ActOneController.choose("playful_lucky_you")
	assert(ActOneController.get_flag("met_moss"), "choosing after a mid-dialogue load should still apply its effects")
	print("OK: save/load resumes mid-dialogue at the exact saved line, and it's still interactive")

	# Saving after a choice must restore the acknowledgement phase rather
	# than offer the choices (and their effects) a second time.
	var acknowledgement_save := ActOneController.get_save_data()
	assert(acknowledgement_save["active_dialogue_choice"] == "playful_lucky_you")
	ActOneController.reset()
	ActOneController.load_content(objectives, dialogues)
	ActOneController.load_from_save(acknowledgement_save)
	assert(ActOneController.get_active_choice_id() == "playful_lucky_you")
	assert(ActOneController.get_active_choice_acknowledgement() == "That confidence again. Let's see it fed.")
	ActOneController.advance_dialogue()
	assert(ActOneController.get_active_choice_id().is_empty(), "advancing should leave the restored acknowledgement phase")
	assert(ActOneController.get_current_line().text.begins_with("Fine."), "advancing a restored acknowledgement should reach the next line")
	print("OK: save/load preserves a post-choice acknowledgement without replaying the choice")

	# --- Unknown ids in saved data are dropped safely, not crashed on ---
	ActOneController.reset()
	ActOneController.load_content(objectives, dialogues)
	ActOneController.load_from_save({
		"flags": {"met_moss": true},
		"objectives": {"an_objective_that_was_removed": {"status": "active", "current": 5}},
		"current_objective_id": "an_objective_that_was_removed",
		"active_dialogue_id": "a_dialogue_that_was_removed",
		"active_dialogue_line": 0,
		"active_dialogue_choice": "removed_choice",
	})
	assert(ActOneController.get_flag("met_moss"), "a known flag should still restore")
	assert(ActOneController.get_objective_status("gather_starter_wood") == "inactive", "an untouched known objective should keep its default state")
	assert(ActOneController.get_active_dialogue_id() == "", "an unknown dialogue id should fall back to no active dialogue instead of crashing")
	print("OK: load_from_save() drops unknown objective/dialogue ids safely instead of crashing")

	# --- Malformed content fails loudly instead of silently no-op-ing ---
	ActOneController.reset()

	var bad_objective := ObjectiveDefinition.new()
	bad_objective.id = "Not A Valid Id!"
	bad_objective.title = "Broken"
	bad_objective.description = "Has a malformed identifier."
	ActOneController.register_objective(bad_objective)
	assert(not ActOneController.has_objective("Not A Valid Id!"), "an ObjectiveDefinition with a malformed id should be rejected, not registered")
	print("OK: an objective with a malformed identifier fails validation and is not registered (see the SCRIPT ERROR above)")

	var good_objective := ObjectiveDefinition.new()
	good_objective.id = "gather_starter_wood"
	good_objective.title = "Wood for Moss's Trust"
	good_objective.description = "Gather wood for the first dam repair."
	good_objective.completion_type = ObjectiveDefinition.CompletionType.RESOURCE_AT_LEAST
	good_objective.resource = "wood"
	good_objective.target_amount = 6
	ActOneController.register_objective(good_objective)

	var bad_speaker_line := DialogueLine.new()
	bad_speaker_line.text = "This line is spoken by nobody in the cast."
	var bad_speaker_dialogue := DialogueDefinition.new()
	bad_speaker_dialogue.id = "broken_unknown_speaker"
	bad_speaker_dialogue.speaker = "godzilla"
	bad_speaker_dialogue.lines = [bad_speaker_line]
	ActOneController.register_dialogue(bad_speaker_dialogue)
	assert(not ActOneController.has_dialogue("broken_unknown_speaker"), "a dialogue with an unknown speaker should be rejected, not registered")
	print("OK: a dialogue with an unknown speaker fails validation and is not registered")

	var dangling_effect := StoryEffect.new()
	dangling_effect.type = StoryEffect.Type.ADVANCE_OBJECTIVE
	dangling_effect.target_id = "an_objective_nobody_registered"
	var dangling_line := DialogueLine.new()
	dangling_line.text = "This line quietly points at an objective that doesn't exist."
	dangling_line.effects = [dangling_effect]
	var dangling_dialogue := DialogueDefinition.new()
	dangling_dialogue.id = "broken_dangling_reference"
	dangling_dialogue.speaker = "moss"
	dangling_dialogue.lines = [dangling_line]
	ActOneController.register_dialogue(dangling_dialogue)
	assert(not ActOneController.has_dialogue("broken_dangling_reference"), "a dialogue effect targeting an unregistered objective should be rejected, not registered")
	print("OK: a dialogue effect referencing an unknown objective id fails validation and is not registered")

	print("ALL STORY TESTS PASSED")
	get_tree().quit()
