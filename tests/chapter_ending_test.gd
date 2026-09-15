extends Node
## End-to-end contract for #21: eligibility through calm post-chapter play.

var failures := 0

func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _ready() -> void:
	SaveManager.current_slot = -1
	GameState.reset()
	ActOneController.reset()
	var main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	# Clear the fresh-game arrival, then establish the exact public eligibility
	# contract rather than calling private ending choreography directly.
	while not ActOneController.get_active_dialogue_id().is_empty():
		ActOneController.advance_dialogue()
	main.act_one_ending.safe_delay = 0.01
	main.act_one_ending.beat_delay = 0.01
	main.act_one_ending.banner_duration = 0.01
	main.bramble_encounter.approach_duration = 0.01
	main.bramble_encounter.flee_leg_duration = 0.01
	ActOneController.set_flag("pond_restored")
	ActOneController.start_objective("check_eddy_route")
	ActOneController.complete_objective("check_eddy_route")
	ActOneController.set_flag("willowbend_narrative_spine_complete")
	GameState.lodge_stage = GameState.LODGE_MAX_STAGE
	GameState.lodge_stage_changed.emit(GameState.lodge_stage)

	for _frame in 240:
		await get_tree().process_frame
		if ActOneController.get_active_dialogue_id() == "bramble_willowbend_intro":
			ActOneController.advance_dialogue()
		if ActOneController.get_flag("act_one_complete") and not main.act_one_ending.is_active():
			break

	check(ActOneController.get_flag("act_one_ending_started"), "the eligible ending starts after its safe delay")
	check(ActOneController.get_flag("act_one_celebration_started"), "the Willowbend gathering is durable")
	check(ActOneController.get_flag("act_one_muddy_pulse_seen"), "the upstream warning is durable")
	check(ActOneController.get_flag("bramble_material_taken") and ActOneController.get_flag("bramble_intro_complete"), "Bramble's authored encounter completes")
	check(ActOneController.get_flag("act_one_route_revealed") and main.get_node("UpstreamRoute").visible, "the route exists before chapter completion")
	check(ActOneController.get_flag("act_one_complete"), "Act I records completion")
	check(main.player.input_enabled and not main.act_one_ending.is_active(), "calm free play resumes with controls enabled")
	check(Ambience.get_state() == Ambience.State.CALM_POST_CHAPTER, "post-chapter ambience replaces the ending bed")

	var cue_count := Ambience.get_chapter_complete_cue_count()
	main.act_one_ending.restore_from_story_state()
	await get_tree().process_frame
	check(Ambience.get_chapter_complete_cue_count() == cue_count, "restoring a completed chapter never replays its cue")
	check(main.get_node("UpstreamRoute").visible and main.player.input_enabled, "completed loads restore the route directly into calm play")

	main.queue_free()
	await get_tree().process_frame
	if failures == 0:
		print("ALL CHAPTER ENDING TESTS PASSED")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
