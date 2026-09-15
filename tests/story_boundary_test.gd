extends Node
## Regression coverage for story ordering and the save boundaries that bridge
## the controller to Willowbend's authored sequence. Moment-to-moment mechanics
## remain in smoke_test.gd; the full happy path remains in narrative_test.gd.

const OBJECTIVE_ORDER: Array[String] = [
	"meet_moss",
	"gather_starter_wood",
	"read_willowbend_water",
	"repair_willowbend_dam",
	"witness_pond_return",
	"check_eddy_route",
	"build_lodge_foundation",
	"talk_moss_home",
	"finish_willowbend_lodge",
	"answer_marnie",
]

const BOUNDARY_PROGRESS := {
	"meet_moss": 0,
	"gather_starter_wood": 3,
	"read_willowbend_water": 0,
	"repair_willowbend_dam": 2,
	"witness_pond_return": 0,
	"check_eddy_route": 0,
	"build_lodge_foundation": 0,
	"talk_moss_home": 0,
	"finish_willowbend_lodge": 2,
	"answer_marnie": 0,
}

const OBJECTIVE_PATHS: Array[String] = [
	"res://data/story/act1/objective_meet_moss.tres",
	"res://data/story/act1/objective_gather_starter_wood.tres",
	"res://data/story/act1/objective_read_willowbend_water.tres",
	"res://data/story/act1/objective_repair_willowbend_dam.tres",
	"res://data/story/act1/objective_witness_pond_return.tres",
	"res://data/story/act1/objective_check_eddy_route.tres",
	"res://data/story/act1/objective_build_lodge_foundation.tres",
	"res://data/story/act1/objective_talk_moss_home.tres",
	"res://data/story/act1/objective_finish_willowbend_lodge.tres",
	"res://data/story/act1/objective_answer_marnie.tres",
]

const DIALOGUE_PATHS: Array[String] = [
	"res://data/story/act1/dialogue_willowbend_arrival.tres",
	"res://data/story/act1/dialogue_moss_intro.tres",
	"res://data/story/act1/dialogue_moss_supplies_ready.tres",
	"res://data/story/act1/dialogue_pond_returns.tres",
	"res://data/story/act1/dialogue_eddy_flow_check.tres",
	"res://data/story/act1/dialogue_moss_lodge_foundation.tres",
	"res://data/story/act1/dialogue_moss_lodge_walls.tres",
	"res://data/story/act1/dialogue_marnie_upstream_call.tres",
]

func _ready() -> void:
	SaveManager.set_storage_root_for_tests("user://automated_tests")
	SaveManager.begin_session(2)
	SaveManager.delete_save(2)
	GameState.reset()
	ActOneController.reset()
	_load_act1_content()

	_test_every_objective_save_boundary()
	_test_supported_mid_dialogue_boundary()
	await _test_out_of_order_world_events()

	print("ALL STORY BOUNDARY TESTS PASSED")
	get_tree().quit()

## Each row represents the moment after an objective has become current and
## before its final action. Loading must preserve the completed prefix, exact
## current progress, and inactive suffix without replaying any effects.
func _test_every_objective_save_boundary() -> void:
	for boundary_index in OBJECTIVE_ORDER.size():
		var current_id: String = OBJECTIVE_ORDER[boundary_index]
		var story_save := _story_save_at(boundary_index)
		ActOneController.load_from_save(story_save)

		assert(ActOneController.get_current_objective_id() == current_id,
			"%s should remain the current objective after load" % current_id)
		for objective_index in OBJECTIVE_ORDER.size():
			var objective_id: String = OBJECTIVE_ORDER[objective_index]
			var expected_status := "inactive"
			if objective_index < boundary_index:
				expected_status = "completed"
			elif objective_index == boundary_index:
				expected_status = "active"
			assert(ActOneController.get_objective_status(objective_id) == expected_status,
				"%s boundary restored %s as %s instead of %s" % [
					current_id,
					objective_id,
					ActOneController.get_objective_status(objective_id),
					expected_status,
				])

		assert(ActOneController.get_objective_progress(current_id) == BOUNDARY_PROGRESS[current_id],
			"%s should restore its exact counted progress" % current_id)
		assert(ActOneController.get_active_dialogue_id().is_empty())

		var round_trip: Dictionary = ActOneController.get_save_data()
		assert(round_trip["current_objective_id"] == current_id)
		assert(round_trip["objectives"][current_id] == {
			"status": "active",
			"current": BOUNDARY_PROGRESS[current_id],
		})

	# The last currently implemented boundary is the completed narrative
	# spine, not chapter completion. Issue #21 will add that separate state.
	var completed_save := _story_save_at(OBJECTIVE_ORDER.size() - 1)
	completed_save["objectives"]["answer_marnie"] = {"status": "completed", "current": 0}
	completed_save["flags"] = {
		"met_moss": true,
		"pond_restored": true,
		"aspen_meadow_requested": true,
		"willowbend_narrative_spine_complete": true,
	}
	ActOneController.load_from_save(completed_save)
	assert(ActOneController.get_objective_status("answer_marnie") == "completed")
	assert(ActOneController.get_flag("willowbend_narrative_spine_complete"))
	assert(not ActOneController.get_flag("act_one_complete"),
		"#15 must not invent #21's future chapter-complete state")
	print("OK: all 10 implemented objective boundaries and the narrative-spine completion boundary round-trip")

func _test_supported_mid_dialogue_boundary() -> void:
	ActOneController.load_from_save(_empty_story_save())
	ActOneController.start_dialogue("willowbend_arrival")
	ActOneController.advance_dialogue()
	ActOneController.advance_dialogue()
	assert(ActOneController.get_current_line().text.begins_with("I came to build a home"))

	var mid_dialogue_save: Dictionary = ActOneController.get_save_data()
	assert(mid_dialogue_save["active_dialogue_id"] == "willowbend_arrival")
	assert(mid_dialogue_save["active_dialogue_line"] == 2)

	ActOneController.load_from_save(mid_dialogue_save)
	assert(ActOneController.get_active_dialogue_id() == "willowbend_arrival")
	assert(ActOneController.get_current_line().text.begins_with("I came to build a home"))
	ActOneController.advance_dialogue()
	assert(ActOneController.get_objective_status("meet_moss") == "active",
		"advancing a restored arrival must apply the next line's objective effect exactly once")
	ActOneController.advance_dialogue()
	assert(ActOneController.get_active_dialogue_id().is_empty())
	assert(ActOneController.get_objective_status("meet_moss") == "active")
	print("OK: the supported mid-dialogue boundary resumes on the exact panel and remains playable")

## Premature actions may update world state, but cannot open gated dialogue or
## mutate objectives that have not begun. Once the story reaches an already-
## satisfied requirement, normal reconciliation should recognize it once.
func _test_out_of_order_world_events() -> void:
	GameState.reset()
	ActOneController.reset()
	SaveManager.delete_save(2)

	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	# #20 replaces the temporary named Critter anchors with composed Resident
	# actors. Accept both layouts so this story-ordering suite stays useful on
	# either side of that independently reviewable refactor.
	var moss: Area2D = _story_actor(main, "Residents/Moss", "Critters/Frog")
	var eddy: Area2D = _story_actor(main, "Residents/Eddy", "Critters/Fish")
	var marnie: Area2D = _story_actor(main, "Residents/Marnie", "Critters/Duck")

	assert(ActOneController.get_active_dialogue_id() == "willowbend_arrival")
	assert(moss.get_interaction() == null,
		"a second conversation must not become available over the arrival dialogue")
	_play_active_dialogue()
	assert(ActOneController.get_objective_status("meet_moss") == "active")

	ActOneController.start_dialogue("eddy_flow_check")
	assert(ActOneController.get_active_dialogue_id().is_empty(),
		"Eddy's condition must block the conversation before its objective")
	ActOneController.start_dialogue("marnie_upstream_call")
	assert(ActOneController.get_active_dialogue_id().is_empty(),
		"Marnie's condition must block the conversation before its objective")
	assert(eddy.get_interaction() == null and marnie.get_interaction() == null)

	# Signal arguments are advisory; Main reconciles from authoritative state.
	GameState.dam_progress_changed.emit(5, 5)
	GameState.lodge_stage_changed.emit(GameState.LODGE_MAX_STAGE)
	assert(ActOneController.get_objective_status("repair_willowbend_dam") == "inactive")
	assert(ActOneController.get_objective_status("finish_willowbend_lodge") == "inactive")
	assert(ActOneController.get_objective_status("answer_marnie") == "inactive")

	# These valid world actions happen early. They must not alter the active
	# meeting objective, then must be acknowledged when their objectives start.
	GameState.read_water()
	GameState.add_wood(6)
	assert(ActOneController.get_objective_status("meet_moss") == "active")
	assert(ActOneController.get_objective_status("gather_starter_wood") == "inactive")
	assert(ActOneController.get_objective_status("read_willowbend_water") == "inactive")

	moss.get_interaction().perform.call()
	_play_active_dialogue("practical_start_together")
	assert(ActOneController.get_objective_status("gather_starter_wood") == "completed")
	assert(ActOneController.get_objective_status("read_willowbend_water") == "completed")
	assert(ActOneController.get_objective_status("repair_willowbend_dam") == "active")

	GameState.restore_dam_progress(2)
	GameState.dam_progress_changed.emit(2, GameState.dam_pieces_total)
	assert(ActOneController.get_objective_progress("repair_willowbend_dam") == 2)
	GameState.dam_progress_changed.emit(2, GameState.dam_pieces_total)
	assert(ActOneController.get_objective_progress("repair_willowbend_dam") == 2,
		"re-announcing an absolute world total must not double-count progress")
	ActOneController.start_dialogue("pond_returns")
	assert(ActOneController.get_active_dialogue_id().is_empty(),
		"the pond conversation must remain gated until all repairs are complete")
	print("OK: premature dialogue and world events cannot skip the spine; satisfied requirements reconcile once")

	main.queue_free()
	await get_tree().process_frame

func _story_save_at(boundary_index: int) -> Dictionary:
	var save := _empty_story_save()
	for objective_index in OBJECTIVE_ORDER.size():
		var objective_id: String = OBJECTIVE_ORDER[objective_index]
		if objective_index < boundary_index:
			save["objectives"][objective_id] = {"status": "completed", "current": 0}
		elif objective_index == boundary_index:
			save["objectives"][objective_id] = {
				"status": "active",
				"current": BOUNDARY_PROGRESS[objective_id],
			}
		save["current_objective_id"] = OBJECTIVE_ORDER[boundary_index]
	return save

func _empty_story_save() -> Dictionary:
	var objectives := {}
	for objective_id in OBJECTIVE_ORDER:
		objectives[objective_id] = {"status": "inactive", "current": 0}
	return {
		"flags": {},
		"objectives": objectives,
		"current_objective_id": "",
		"active_dialogue_id": "",
		"active_dialogue_line": -1,
		"active_dialogue_choice": "",
	}

func _load_act1_content() -> void:
	var objectives: Array[ObjectiveDefinition] = []
	for path in OBJECTIVE_PATHS:
		objectives.append(load(path))
	var dialogues: Array[DialogueDefinition] = []
	for path in DIALOGUE_PATHS:
		dialogues.append(load(path))
	ActOneController.load_content(objectives, dialogues)

func _play_active_dialogue(choice_id: String = "") -> void:
	while not ActOneController.get_active_dialogue_id().is_empty():
		var line := ActOneController.get_current_line()
		if not line.choices.is_empty() and ActOneController.get_active_choice_id().is_empty():
			var selected_id: String = choice_id if not choice_id.is_empty() else line.choices[0].id
			ActOneController.choose(selected_id)
		else:
			ActOneController.advance_dialogue()

func _story_actor(main: Node, resident_path: String, legacy_path: String) -> Area2D:
	var actor := main.get_node_or_null(resident_path)
	if actor == null:
		actor = main.get_node(legacy_path)
	return actor as Area2D
