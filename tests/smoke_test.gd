extends Node
## Headless regression test for the core loop. Not a proper test framework
## (no GUT/GoDotTest set up yet) - just enough to catch obvious breakage
## before it reaches a session where you're testing by hand.
##
## Run with:
##   godot --headless --path . tests/smoke_test.tscn
## It exits 0 and prints ALL SMOKE TESTS PASSED on success, or hits a
## SCRIPT ERROR: Assertion failed on the first broken behavior.

func _ready() -> void:
	# A stray real save file (from manual/live testing on this machine, or a
	# previous run of this test) would otherwise get loaded into `main`
	# below and silently invalidate every assertion that follows.
	SaveManager.delete_save()

	var main_scene: PackedScene = load("res://scenes/main/main.tscn")
	var main: Node = main_scene.instantiate()
	add_child(main)

	var player: CharacterBody2D = main.get_node("Player")
	var tree1: StaticBody2D = main.get_node("Trees/Tree1")
	var rock1: StaticBody2D = main.get_node("Rocks/Rock1")
	var dam_slot1: Area2D = main.get_node("DamSlots/DamSlot1")
	var river_water: Area2D = main.get_node("RiverWater")
	var lodge: Area2D = main.get_node("Lodge")
	var frog: Node2D = main.get_node("Critters/Frog")

	assert(GameState.dam_pieces_total == 5, "expected 5 dam slots, got %d" % GameState.dam_pieces_total)
	print("OK: dam_pieces_total == 5")

	var tree_area: Area2D = tree1.get_node("InteractArea")
	var rock_area: Area2D = rock1.get_node("InteractArea")
	assert(player._resolve_target(tree_area) == tree1)
	assert(player._resolve_target(rock_area) == rock1)
	assert(player._resolve_target(dam_slot1) == dam_slot1)
	assert(player._resolve_target(lodge) == lodge)
	print("OK: Player._resolve_target resolves trees, rocks, dam slots, and the lodge correctly")

	assert(not tree1.highlighted)
	tree1.set_highlighted(true)
	assert(tree1.highlighted)
	tree1.set_highlighted(false)
	print("OK: tree highlighting toggles")

	for i in 3:
		tree1.chop()
	assert(GameState.wood == 3 and tree1.felled, "expected 3 wood, tree felled after 3 hits")
	tree1.chop()
	assert(GameState.wood == 3, "chopping a felled tree should not yield more wood")
	print("OK: chopping a tree 3 times yields wood and fells it; felled trees give no more")

	for i in 2:
		rock1.mine()
	assert(GameState.stone == 2 and rock1.broken, "expected 2 stone, rock broken after 2 hits")
	rock1.mine()
	assert(GameState.stone == 2, "mining a broken rock should not yield more stone")
	print("OK: mining a rock 2 times yields stone and breaks it; broken rocks give no more")

	assert(not lodge.unlocked, "lodge should be locked before the dam is finished")
	assert(not lodge.can_advance())
	print("OK: lodge starts locked")

	assert(GameState.can_afford_dam_piece())
	assert(dam_slot1.can_build())
	GameState.spend_resources_on_dam_piece()
	dam_slot1.build()
	assert(GameState.dam_pieces_built == 1 and not dam_slot1.can_build())
	print("OK: building a dam piece spends resources and marks the slot built")

	assert(is_instance_valid(river_water), "river_water should exist before completion")
	player.global_position = river_water.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(player.water_detector.get_overlapping_areas().size() > 0, "player standing in the river should detect RiverWater")
	print("OK: water detector notices the player standing in the river")

	var completed_flag := [false]
	GameState.dam_completed.connect(func(): completed_flag[0] = true)
	for slot_name in ["DamSlot2", "DamSlot3", "DamSlot4", "DamSlot5"]:
		var slot: Area2D = main.get_node("DamSlots/%s" % slot_name)
		GameState.add_wood(2)
		GameState.add_stone(1)
		GameState.spend_resources_on_dam_piece()
		slot.build()
	assert(completed_flag[0], "dam_completed should fire once all 5 slots are built")
	print("OK: dam_completed fires once all slots are built")

	# Let Fx.burst() timers (chop/mine/build/completion) run their course
	# before quitting, and let RiverWater's queue_free() take effect.
	await get_tree().create_timer(1.0).timeout
	assert(not is_instance_valid(river_water), "RiverWater should be freed once the dam is complete")
	print("OK: RiverWater is removed on completion, so crossing is no longer slowed")

	assert(lodge.unlocked, "lodge should unlock once the dam is complete")
	print("OK: lodge unlocks once the dam is complete")

	assert(not frog.visible, "frog should not be visible before lodge stage 1")
	GameState.add_wood(10)
	GameState.add_stone(10)
	assert(lodge.can_advance() and GameState.can_afford_lodge_stage())
	lodge.advance()
	assert(GameState.lodge_stage == 1)
	assert(frog.visible, "frog should appear once lodge reaches stage 1")
	print("OK: advancing the lodge spends resources, and the frog appears at stage 1")

	lodge.advance()
	lodge.advance()
	assert(GameState.lodge_stage == GameState.LODGE_MAX_STAGE)
	assert(not lodge.can_advance(), "lodge should not advance past max stage")
	print("OK: lodge reaches max stage and stops accepting further advances")

	# --- Garden spots (post-Lodge cosmetic decorations) ---
	var flower_spot: GardenSpot = main.get_node("GardenSpots/FlowerBedSpot")
	var butterfly: Node2D = main.get_node("Critters/Butterfly")
	assert(flower_spot.unlocked, "garden spots should unlock once the lodge is complete")
	assert(not butterfly.visible, "butterfly should stay hidden until its garden spot is built")
	assert(player._resolve_target(flower_spot) == flower_spot)

	GameState.add_wood(10)
	GameState.add_stone(10)
	assert(flower_spot.can_build() and GameState.can_afford(GardenSpot.WOOD_COST, GardenSpot.STONE_COST))
	flower_spot.build()
	assert(flower_spot.built and not flower_spot.can_build())
	assert(butterfly.visible, "building the flower bed should reveal the butterfly")
	print("OK: garden spots unlock with the lodge, and building one reveals its critter")

	for action_name in ["move_up", "move_down", "move_left", "move_right", "interact", "restart"]:
		assert(InputMap.has_action(action_name), "missing action: %s" % action_name)
		var has_physical := false
		var has_logical := false
		var has_joy := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey:
				if event.physical_keycode != KEY_NONE:
					has_physical = true
				if event.keycode != KEY_NONE:
					has_logical = true
			elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_joy = true
		assert(has_physical, "%s has no physical_keycode event" % action_name)
		assert(has_logical, "%s has no keycode event" % action_name)
		assert(has_joy, "%s has no joypad event" % action_name)
	print("OK: all actions have physical, logical, and joypad bindings")

	# --- Save / load ---
	SaveManager.delete_save()
	assert(not SaveManager.has_save())

	var saved_data: Dictionary = main.get_save_data()
	assert(saved_data["wood"] == GameState.wood)
	assert(saved_data["lodge_stage"] == GameState.LODGE_MAX_STAGE)
	assert(saved_data["dam_slots_built"]["DamSlot1"] == true)
	assert(saved_data["garden_spots_built"]["FlowerBedSpot"] == true)

	# save_game() reads get_tree().current_scene, which Godot only allows to
	# be a direct child of root - reparent there just for this call, the
	# same shape the real game runs in.
	main.reparent(get_tree().root)
	get_tree().current_scene = main
	SaveManager.save_game()
	get_tree().current_scene = self
	main.reparent(self)
	assert(SaveManager.has_save(), "save_game() should have written a save file")
	print("OK: save_game() writes a save file for the current scene's data")

	GameState.reset()
	assert(GameState.wood == 0 and GameState.lodge_stage == 0)

	var main2: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main2)
	# main2's own _ready() calls SaveManager.load_into(self), so by the time
	# add_child() returns, it should already be restored.
	assert(GameState.wood == saved_data["wood"], "loading should restore wood")
	assert(GameState.lodge_stage == GameState.LODGE_MAX_STAGE, "loading should restore lodge stage")
	var restored_slot1: Area2D = main2.get_node("DamSlots/DamSlot1")
	assert(restored_slot1.built, "loading should restore built dam slots")
	var restored_lodge: Area2D = main2.get_node("Lodge")
	assert(restored_lodge.unlocked, "loading should unlock the lodge if the dam was complete")
	var restored_flower_spot: GardenSpot = main2.get_node("GardenSpots/FlowerBedSpot")
	assert(restored_flower_spot.unlocked and restored_flower_spot.built, "loading should restore built garden spots")
	var restored_butterfly: Node2D = main2.get_node("Critters/Butterfly")
	assert(restored_butterfly.visible, "loading a built garden spot should re-reveal its critter")
	print("OK: a fresh scene instance auto-loads saved progress on _ready()")

	SaveManager.delete_save()
	assert(not SaveManager.has_save())
	print("OK: delete_save() removes the save file")

	GameState.reset()
	assert(GameState.wood == 0 and GameState.stone == 0)
	assert(GameState.dam_pieces_built == 0)
	assert(GameState.lodge_stage == 0)
	print("OK: GameState.reset() zeroes progress including lodge_stage")

	# Let the lodge-advance Fx.burst() timers run their course before quitting.
	await get_tree().create_timer(1.0).timeout

	print("ALL SMOKE TESTS PASSED")
	get_tree().quit()
