extends Node
## End-to-end regression for Willowbend's authored Act I spine. Mechanics have
## their own smoke suite; this proves that their signals advance the right
## objectives and that every resident conversation becomes available in order.

func _ready() -> void:
	SaveManager.set_storage_root_for_tests("user://automated_tests")
	SaveManager.begin_session(1)
	SaveManager.delete_save(1)
	GameState.reset()
	ActOneController.reset()

	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	var moss: Resident = main.get_node("Residents/Moss")
	var eddy: Resident = main.get_node("Residents/Eddy")
	var marnie: Resident = main.get_node("Residents/Marnie")
	var gauge: RiverGauge = main.get_node("RiverGauge")

	assert(ActOneController.get_active_dialogue_id() == "willowbend_arrival")
	assert(get_tree().paused, "the brief arrival conversation should pause gameplay")
	_play_active_dialogue()
	assert(ActOneController.get_objective_status("meet_moss") == "active")
	assert(moss.visible and moss.get_interaction().label == "Talk to Moss")
	assert(moss.global_position.y < 275.0, "Moss's opening route must stay above the HUD safe edge")
	assert(main.hud.story_indicator.target == moss, "the first task should point a new player toward Moss")
	print("OK: the Willowbend arrival leads to a visible, actionable Moss")

	moss.get_interaction().perform.call()
	_play_active_dialogue("earnest_stay_for_everyone")
	assert(ActOneController.get_flag("met_moss"))
	assert(ActOneController.get_objective_status("meet_moss") == "completed")
	assert(ActOneController.get_objective_status("gather_starter_wood") == "active")
	assert(main.hud.story_indicator.target == null, "resource tasks should not keep pointing at the last speaker")

	GameState.add_wood(6)
	assert(ActOneController.get_objective_status("gather_starter_wood") == "completed")
	assert(ActOneController.get_objective_status("read_willowbend_water") == "active")
	assert(moss.get_interaction().label == "Talk to Moss", "Moss should offer the water-reading reminder")
	print("OK: Moss's introduction and gathering progress lead to reading the creek")

	gauge.read_water()
	assert(ActOneController.get_objective_status("read_willowbend_water") == "completed")
	assert(ActOneController.get_objective_status("repair_willowbend_dam") == "active")
	GameState.restore_dam_progress(GameState.dam_pieces_total)
	GameState.dam_progress_changed.emit(GameState.dam_pieces_built, GameState.dam_pieces_total)
	assert(ActOneController.get_objective_status("repair_willowbend_dam") == "completed")
	assert(ActOneController.get_objective_status("witness_pond_return") == "active")
	assert(eddy.visible, "Eddy should appear with the restored pond")

	moss.get_interaction().perform.call()
	assert(ActOneController.get_active_dialogue_id() == "pond_returns")
	_play_active_dialogue()
	assert(ActOneController.get_flag("pond_restored"))
	assert(ActOneController.get_objective_status("witness_pond_return") == "completed")
	assert(ActOneController.get_objective_status("check_eddy_route") == "active")
	print("OK: repairing the dam unlocks the pond reaction and Eddy's flow check")

	assert(eddy.get_interaction().label == "Talk to Eddy")
	eddy.get_interaction().perform.call()
	_play_active_dialogue()
	assert(ActOneController.get_objective_status("check_eddy_route") == "completed")
	assert(ActOneController.get_objective_status("build_lodge_foundation") == "active")

	GameState.lodge_stage = 1
	GameState.lodge_stage_changed.emit(1)
	assert(ActOneController.get_objective_status("build_lodge_foundation") == "completed")
	assert(ActOneController.get_objective_status("talk_moss_home") == "active")
	moss.get_interaction().perform.call()
	assert(ActOneController.get_active_dialogue_id() == "moss_lodge_foundation")
	_play_active_dialogue()
	assert(ActOneController.get_objective_status("finish_willowbend_lodge") == "active")

	GameState.lodge_stage = 2
	GameState.lodge_stage_changed.emit(2)
	assert(ActOneController.get_flag("lodge_walls_ready"))
	moss.get_interaction().perform.call()
	assert(ActOneController.get_active_dialogue_id() == "moss_lodge_walls")
	_play_active_dialogue()
	assert(ActOneController.get_flag("moss_saw_lodge_walls"))
	assert(not ActOneController.get_flag("lodge_walls_ready"), "the one-time walls beat must not repeat")

	GameState.lodge_stage = GameState.LODGE_MAX_STAGE
	GameState.lodge_stage_changed.emit(GameState.lodge_stage)
	assert(ActOneController.get_objective_status("finish_willowbend_lodge") == "completed")
	assert(ActOneController.get_objective_status("answer_marnie") == "active")
	assert(marnie.visible and marnie.get_interaction().label == "Talk to Marnie")
	assert(not main.is_act_one_ending_eligible(), "stage three must not skip Marnie's request and Moss's final acknowledgement")
	print("OK: Eddy's check and Lodge milestones lead to Marnie's arrival")

	var eligibility_events: Array[bool] = []
	main.act_one_ending_eligibility_changed.connect(func(eligible: bool): eligibility_events.append(eligible))
	marnie.get_interaction().perform.call()
	_play_active_dialogue()
	assert(ActOneController.get_objective_status("answer_marnie") == "completed")
	assert(ActOneController.get_flag("aspen_meadow_requested"))
	assert(ActOneController.get_flag("willowbend_narrative_spine_complete"))
	assert(not get_tree().paused and ActOneController.get_active_dialogue_id().is_empty())
	assert(main.is_act_one_ending_eligible(), "the completed stage-three narrative should expose #21's ending handoff")
	assert(eligibility_events == [true], "eligibility should become true exactly once after the closing dialogue releases its input")
	print("ALL NARRATIVE TESTS PASSED")
	# Let the gauge's short SFX playback release before the headless process
	# exits, matching the cleanup grace period in the mechanics suite.
	await get_tree().create_timer(0.5).timeout
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _play_active_dialogue(choice_id: String = "") -> void:
	while not ActOneController.get_active_dialogue_id().is_empty():
		var line := ActOneController.get_current_line()
		if not line.choices.is_empty() and ActOneController.get_active_choice_id().is_empty():
			var selected_id: String = choice_id if not choice_id.is_empty() else line.choices[0].id
			ActOneController.choose(selected_id)
		else:
			ActOneController.advance_dialogue()
