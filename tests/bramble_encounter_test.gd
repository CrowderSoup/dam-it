extends Node
## Focused #20 coverage for Bramble's deterministic authored introduction,
## protected material loss, discrete save restoration, and idempotency.

func _ready() -> void:
	SaveManager.set_storage_root_for_tests("user://automated_tests")
	SaveManager.current_slot = -1
	GameState.reset()
	ActOneController.reset()

	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	while not ActOneController.get_active_dialogue_id().is_empty():
		ActOneController.advance_dialogue()
	var encounter: BrambleEncounter = main.get_node("BrambleEncounter")
	var bramble: Raccoon = main.get_node("Raccoon")
	encounter.approach_duration = 0.01
	encounter.flee_leg_duration = 0.01

	assert(encounter.get_phase() == BrambleEncounter.Phase.IDLE)
	assert(not bramble.visible and bramble.get_interaction() == null)
	assert(main.start_bramble_introduction())
	assert(ActOneController.get_flag("bramble_intro_started"))
	assert(encounter.get_phase() == BrambleEncounter.Phase.APPROACHING)
	assert(bramble.visible and bramble.get_interaction() == null, "the authored Bramble cannot trigger recurring feed/steal behavior")
	await encounter.approach_completed
	assert(encounter.get_phase() == BrambleEncounter.Phase.READY_TO_TAKE)
	print("OK: Bramble follows the deterministic authored approach and cannot be interacted with as a random scavenger")

	# Protect the six wood required by the active gathering objective. Of the
	# eight carried, only two may be taken; stone has no active reservation.
	ActOneController.complete_objective("meet_moss")
	ActOneController.start_objective("gather_starter_wood")
	GameState.wood = 8
	GameState.stone = 2
	var taken: Dictionary = main.commit_bramble_material_take()
	assert(ActOneController.get_flag("bramble_material_taken"), "the durable flag must be committed with the loss")
	assert(taken == {"wood": 2, "stone": 1})
	assert(GameState.wood == 6 and GameState.stone == 1, "the active story requirement must remain affordable")
	assert(main.commit_bramble_material_take() == {"wood": 0, "stone": 0}, "the material loss must be idempotent")
	assert(GameState.wood == 6 and GameState.stone == 1)
	print("OK: Bramble's one-time loss preserves active objective resources and cannot charge twice")

	# A started-only save resumes at the pre-take anchor. Zero inventory changes
	# the committed amounts, never whether the scene can proceed.
	var started_story := ActOneController.get_save_data()
	started_story["flags"] = {"bramble_intro_started": true}
	ActOneController.load_from_save(started_story)
	GameState.wood = 0
	GameState.stone = 0
	encounter.restore_from_story_state()
	assert(encounter.get_phase() == BrambleEncounter.Phase.READY_TO_TAKE)
	assert(bramble.global_position == encounter.material_anchor.global_position)
	assert(main.commit_bramble_material_take() == {"wood": 0, "stone": 0})
	assert(ActOneController.get_flag("bramble_material_taken"))
	print("OK: a started save restores at the pre-take boundary and zero resources never block progress")

	# A material-taken save resumes after the irreversible side effect and can
	# run only the fixed escape. Completion is written after reaching the exit.
	var taken_story := ActOneController.get_save_data()
	encounter.restore_from_story_state()
	assert(encounter.get_phase() == BrambleEncounter.Phase.READY_TO_FLEE)
	assert(main.begin_bramble_escape())
	assert(encounter.get_phase() == BrambleEncounter.Phase.FLEEING)
	await encounter.encounter_completed
	assert(encounter.get_phase() == BrambleEncounter.Phase.COMPLETE)
	assert(ActOneController.get_flag("bramble_intro_complete"))
	assert(not bramble.visible)
	assert(not main.start_bramble_introduction() and not main.begin_bramble_escape(), "a completed introduction cannot replay")
	print("OK: post-take restoration completes the deterministic escape exactly once")

	ActOneController.load_from_save(taken_story)
	encounter.restore_from_story_state()
	assert(encounter.get_phase() == BrambleEncounter.Phase.READY_TO_FLEE, "loading the saved post-take boundary must not invent completion")
	ActOneController.set_flag("bramble_intro_complete")
	encounter.restore_from_story_state()
	assert(encounter.get_phase() == BrambleEncounter.Phase.COMPLETE and not bramble.visible)
	print("OK: every durable Bramble boundary restores to a stable authored phase")

	main.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	print("ALL BRAMBLE ENCOUNTER TESTS PASSED")
	get_tree().quit()
