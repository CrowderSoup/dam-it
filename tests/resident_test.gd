extends Node
## Focused regression for #20's first resident/Lodge slice: composition,
## story-derived routines, save restoration, and the authored Bramble gate.

func _ready() -> void:
	SaveManager.set_storage_root_for_tests("user://automated_tests")
	SaveManager.begin_session(1)
	SaveManager.delete_save(1)
	GameState.reset()
	ActOneController.reset()

	var fresh_main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(fresh_main)
	var fresh_moss: Resident = fresh_main.get_node("Residents/Moss")
	var fresh_eddy: Resident = fresh_main.get_node("Residents/Eddy")
	var butterfly: Critter = fresh_main.get_node("Critters/Butterfly")
	assert(fresh_moss.visible and fresh_moss.monitorable)
	assert(fresh_moss.get_active_route_id() == "opening")
	assert(fresh_moss.get_route_points().size() >= 2, "Moss needs a visible opening routine")
	assert(not fresh_eddy.visible and not fresh_eddy.monitorable, "Eddy must wait for restored habitat")
	assert(not butterfly.has_method("get_interaction"), "garden wildlife must remain visual-only")
	assert(not fresh_main.is_recurring_scavenging_enabled(), "fresh games cannot schedule random Bramble")
	print("OK: fresh state composes resident actors separately from decorative wildlife")

	GameState.restore_dam_progress(GameState.dam_pieces_total)
	GameState.dam_progress_changed.emit(GameState.dam_pieces_built, GameState.dam_pieces_total)
	assert(fresh_eddy.visible and fresh_eddy.global_position == fresh_eddy.get_route_points()[0], "live Eddy arrival must begin at an authored water point")
	var eddy_start := fresh_eddy.global_position
	fresh_eddy._process(fresh_eddy.pause_seconds + 0.1)
	fresh_eddy._process(0.5)
	assert(fresh_eddy.global_position != eddy_start, "Eddy's routine should visibly traverse its route")
	assert(not fresh_main.is_recurring_scavenging_enabled(), "restoring habitat alone still cannot schedule Bramble")
	print("OK: restored habitat reveals Eddy directly on a moving authored route")

	# End the intentional opening conversation so the scene can leave its
	# paused state before it is replaced by the save-restoration scenario.
	while not ActOneController.get_active_dialogue_id().is_empty():
		ActOneController.advance_dialogue()
	fresh_main.queue_free()
	await get_tree().process_frame
	GameState.reset()
	ActOneController.reset()

	_write_stage_one_save()
	var restored_main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(restored_main)
	var moss: Resident = restored_main.get_node("Residents/Moss")
	var eddy: Resident = restored_main.get_node("Residents/Eddy")
	var marnie: Resident = restored_main.get_node("Residents/Marnie")
	var lodge: Area2D = restored_main.get_node("Lodge")

	assert(GameState.is_dam_complete() and GameState.lodge_stage == 1)
	assert(moss.visible and moss.get_active_route_id() == "stage_one")
	assert(moss.global_position == moss.get_route_points()[0], "restored Moss should snap to an authored route point")
	assert(eddy.visible and eddy.get_active_route_id() == "restored")
	assert(eddy.global_position == eddy.get_route_points()[0], "restored Eddy should not resume between waypoints")
	assert(eddy.get_interaction() != null and eddy.get_interaction().label == "Talk to Eddy")
	assert(not marnie.visible, "Marnie must still wait for her narrative objective")
	assert(lodge.visible and lodge.can_rest(), "stage-one saves must restore the Lodge's first practical payoff")
	assert(lodge.get_interaction().label == "Rest", "rest should be reachable before another build while tired")
	assert(not restored_main.is_recurring_scavenging_enabled(), "dam-complete legacy saves cannot bypass Bramble's introduction")
	print("OK: stage-one/restored-pond saves derive routines, dialogue, and rest without replaying arrivals")

	ActOneController.set_flag("bramble_intro_complete")
	assert(restored_main.is_recurring_scavenging_enabled(), "only the authored-introduction completion flag may unlock recurring scavenging")
	ActOneController.set_flag("bramble_intro_complete", false)
	assert(not restored_main.is_recurring_scavenging_enabled(), "clearing the gate must stop the timer again")
	print("OK: recurring scavenging is hard-gated by bramble_intro_complete")

	restored_main.queue_free()
	await get_tree().process_frame
	SaveManager.delete_save(1)
	print("ALL RESIDENT TESTS PASSED")
	get_tree().quit()

func _write_stage_one_save() -> void:
	var built_slots := {}
	for index in range(1, 6):
		built_slots["DamSlot%d" % index] = true
	var data := {
		"save_version": SaveManager.SAVE_VERSION,
		"wood": 2,
		"stone": 1,
		"berries": 0,
		"energy": 20.0,
		"lodge_stage": 1,
		"pouch_tier": 0,
		"seen_tutorials": {},
		"dam_slots_built": built_slots,
		"dam_slots_leaking": {},
		"garden_spots_built": {},
		"player_x": 200.0,
		"player_y": 200.0,
		"story": {
			"flags": {"met_moss": true, "pond_restored": true},
			"objectives": {
				"meet_moss": {"status": "completed", "current": 0},
				"gather_starter_wood": {"status": "completed", "current": 6},
				"read_willowbend_water": {"status": "completed", "current": 0},
				"repair_willowbend_dam": {"status": "completed", "current": 5},
				"witness_pond_return": {"status": "completed", "current": 0},
				"check_eddy_route": {"status": "active", "current": 0},
			},
			"current_objective_id": "check_eddy_route",
			"active_dialogue_id": "",
			"active_dialogue_line": -1,
			"active_dialogue_choice": "",
		},
	}
	var file := FileAccess.open(SaveManager._slot_path(1), FileAccess.WRITE)
	assert(file != null, "could not write isolated resident test save")
	file.store_string(JSON.stringify(data))
	file.close()
