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
	var raccoon: Raccoon = main.get_node("Raccoon")
	var hud: CanvasLayer = main.get_node("HUD")
	var berry_bush1: Area2D = main.get_node("BerryBushes/BerryBush1")

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

	var energy_before_chop := GameState.energy
	for i in 3:
		tree1.chop()
	assert(GameState.wood == 3 and tree1.felled, "expected 3 wood, tree felled after 3 hits")
	tree1.chop()
	assert(GameState.wood == 3, "chopping a felled tree should not yield more wood")
	assert(GameState.energy == energy_before_chop - 3 * GameState.CHOP_ENERGY_COST, "3 successful chops should spend CHOP_ENERGY_COST each")
	print("OK: chopping a tree 3 times yields wood and fells it; felled trees give no more")

	var energy_before_mine := GameState.energy
	for i in 2:
		rock1.mine()
	assert(GameState.stone == 2 and rock1.broken, "expected 2 stone, rock broken after 2 hits")
	rock1.mine()
	assert(GameState.stone == 2, "mining a broken rock should not yield more stone")
	assert(GameState.energy == energy_before_mine - 2 * GameState.MINE_ENERGY_COST, "2 successful mines should spend MINE_ENERGY_COST each")
	print("OK: mining a rock 2 times yields stone and breaks it; broken rocks give no more")

	# --- Energy / tired mechanic ---
	assert(not GameState.is_tired(), "energy should still be well above the tired threshold")
	GameState.spend_energy(1000.0)
	assert(GameState.energy == 0.0, "spend_energy should clamp at zero, not go negative")
	assert(GameState.is_tired(), "energy at zero should count as tired")
	GameState.restore_energy(10.0)
	assert(GameState.energy == 10.0)
	assert(GameState.is_tired(), "10/100 energy should still be tired (threshold is 25)")
	GameState.restore_energy(1000.0)
	assert(GameState.energy == GameState.ENERGY_MAX, "restore_energy should clamp at ENERGY_MAX, not overshoot")
	assert(not GameState.is_tired())
	print("OK: spend_energy()/restore_energy() clamp correctly and is_tired() reflects the threshold")

	assert(berry_bush1.can_eat(), "a fresh berry bush should be eatable")
	assert(player._resolve_target(berry_bush1) == berry_bush1)
	GameState.spend_energy(50.0)
	var energy_before_eat := GameState.energy
	berry_bush1.eat()
	assert(GameState.energy == energy_before_eat + BerryBush.ENERGY_RESTORE, "eating should restore ENERGY_RESTORE energy")
	assert(not berry_bush1.can_eat(), "a just-eaten bush should not be eatable again until it respawns")
	berry_bush1.eat()
	assert(GameState.energy == energy_before_eat + BerryBush.ENERGY_RESTORE, "eating a picked bush should be a no-op")
	print("OK: eating a berry bush restores energy once, then blocks re-eating until it respawns")

	assert(not lodge.visible, "lodge should be hidden before the dam is finished")
	assert(not lodge.can_advance())
	print("OK: lodge starts hidden")

	assert(GameState.can_afford_dam_piece())
	assert(dam_slot1.can_build())
	GameState.spend_resources_on_dam_piece()
	dam_slot1.build()
	assert(GameState.dam_pieces_built == 1 and not dam_slot1.can_build())
	print("OK: building a dam piece spends resources and marks the slot built")

	assert(is_instance_valid(river_water), "river_water should exist before completion")
	player.global_position = dam_slot1.global_position
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

	assert(lodge.visible, "lodge should appear once the dam is complete")
	print("OK: lodge appears once the dam is complete")

	# --- HUD toast + edge indicators (threat visibility) ---
	assert(hud.toast_label.visible and hud.toast_background.visible, "dam_completed should have shown a toast")
	hud.point_to_storm(dam_slot1)
	assert(hud.storm_indicator.target == dam_slot1)
	hud.clear_storm_indicator()
	assert(hud.storm_indicator.target == null, "clear_storm_indicator() should drop the target")
	hud.point_to_raccoon(raccoon)
	assert(hud.raccoon_indicator.target == raccoon)
	hud.clear_raccoon_indicator()
	assert(hud.raccoon_indicator.target == null, "clear_raccoon_indicator() should drop the target")
	print("OK: HUD shows a toast on dam completion, and the edge indicators track/clear targets")

	# --- Storms: a leak on a built dam slot, repaired without re-triggering
	# dam completion or changing the built-piece count. ---
	assert(not dam_slot1.can_repair(), "an intact slot should not be repairable")
	dam_slot1.start_leaking()
	assert(dam_slot1.leaking and dam_slot1.can_repair(), "start_leaking() should mark the slot leaking and repairable")
	assert(not dam_slot1.can_build(), "a leaking slot is still built, not buildable again")
	dam_slot1.start_leaking()
	assert(dam_slot1.leaking, "start_leaking() should be idempotent, not double-apply")

	# Main listens to every slot's leak_changed to keep the storm indicator
	# pointed at a real leak - not just testing the HUD API in isolation.
	assert(hud.storm_indicator.target == dam_slot1, "leak_changed should have pointed the storm indicator at the leaking slot")

	GameState.add_wood(5)
	GameState.add_stone(5)
	var built_before_repair := GameState.dam_pieces_built
	var repair_completed_flag := [false]
	GameState.dam_completed.connect(func(): repair_completed_flag[0] = true)
	assert(GameState.can_afford_dam_piece())
	GameState.spend_resources_on_repair()
	dam_slot1.repair()
	assert(not dam_slot1.leaking and not dam_slot1.can_repair(), "repair() should clear the leak")
	assert(GameState.dam_pieces_built == built_before_repair, "repairing must not change the built-piece count")
	assert(not repair_completed_flag[0], "repairing an already-complete dam must not refire dam_completed")
	assert(hud.storm_indicator.target == null, "repairing the only leak should clear the storm indicator")
	print("OK: a leaking dam slot can be repaired without affecting dam_pieces_built or re-firing dam_completed")

	# --- Scavenger: shoo vs. steal-and-flee ---
	assert(not raccoon.can_shoo(), "raccoon should be inactive until spawned")
	raccoon.spawn_at(Vector2(300, 300))
	hud.point_to_raccoon(raccoon)
	assert(raccoon.can_shoo() and raccoon.visible, "spawn_at() should activate and show the raccoon")
	assert(player._resolve_target(raccoon) == raccoon)
	raccoon.shoo()
	assert(not raccoon.can_shoo() and not raccoon.visible, "shoo() should despawn the raccoon with no theft")
	assert(hud.raccoon_indicator.target == null, "despawning (via shoo) should clear the raccoon indicator")
	print("OK: shooing the raccoon despawns it without stealing anything, and clears its indicator")

	raccoon.spawn_at(Vector2(300, 300))
	var wood_before_theft := GameState.wood
	var stone_before_theft := GameState.stone
	raccoon._steal_and_flee()
	assert(GameState.wood == wood_before_theft - Raccoon.STEAL_WOOD, "the raccoon should steal STEAL_WOOD wood")
	assert(GameState.stone == stone_before_theft - Raccoon.STEAL_STONE, "the raccoon should steal STEAL_STONE stone")
	assert(not raccoon.can_shoo(), "the raccoon should despawn after stealing")
	print("OK: an unshooed raccoon steals a small amount of wood/stone then despawns")

	GameState.wood = 0
	assert(GameState.remove_wood(3) == 0, "remove_wood should clamp to what's actually available")
	assert(GameState.wood == 0, "wood should never go negative")
	print("OK: GameState.remove_wood()/remove_stone() clamp at zero")

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

	# --- Resting at the finished Lodge ---
	GameState.restore_energy_fully()
	assert(not lodge.can_rest(), "a lodge at full energy should not offer resting")
	GameState.spend_energy(80.0)
	assert(lodge.can_rest(), "a finished lodge should offer resting once energy is below max")
	assert(player._resolve_target(lodge) == lodge)
	lodge.rest()
	assert(GameState.energy == GameState.ENERGY_MAX, "resting at the lodge should fully refill energy")
	assert(not lodge.can_rest(), "a freshly-rested lodge should not offer resting again immediately")
	print("OK: resting at a finished lodge fully refills energy")

	# --- Garden spots (post-Lodge cosmetic decorations) ---
	var flower_spot: GardenSpot = main.get_node("GardenSpots/FlowerBedSpot")
	var butterfly: Node2D = main.get_node("Critters/Butterfly")
	assert(flower_spot.visible, "garden spots should appear once the lodge is complete")
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
	var dam_slot2: Area2D = main.get_node("DamSlots/DamSlot2")
	dam_slot2.start_leaking()

	SaveManager.delete_save()
	assert(not SaveManager.has_save())

	GameState.spend_energy(37.0)
	var saved_data: Dictionary = main.get_save_data()
	assert(saved_data["wood"] == GameState.wood)
	assert(saved_data["energy"] == GameState.energy)
	assert(saved_data["lodge_stage"] == GameState.LODGE_MAX_STAGE)
	assert(saved_data["dam_slots_built"]["DamSlot1"] == true)
	assert(saved_data["dam_slots_leaking"]["DamSlot2"] == true)
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
	assert(GameState.energy == GameState.ENERGY_MAX, "reset() should restore energy to max")

	var main2: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main2)
	# main2's own _ready() calls SaveManager.load_into(self), so by the time
	# add_child() returns, it should already be restored.
	assert(GameState.wood == saved_data["wood"], "loading should restore wood")
	assert(GameState.energy == saved_data["energy"], "loading should restore energy")
	assert(GameState.lodge_stage == GameState.LODGE_MAX_STAGE, "loading should restore lodge stage")
	var restored_slot1: Area2D = main2.get_node("DamSlots/DamSlot1")
	assert(restored_slot1.built, "loading should restore built dam slots")
	var restored_slot2: Area2D = main2.get_node("DamSlots/DamSlot2")
	assert(restored_slot2.leaking, "loading should restore a leaking dam slot")
	assert(restored_slot2.can_repair())
	var restored_lodge: Area2D = main2.get_node("Lodge")
	assert(restored_lodge.visible, "loading should reveal the lodge if the dam was complete")
	var restored_flower_spot: GardenSpot = main2.get_node("GardenSpots/FlowerBedSpot")
	assert(restored_flower_spot.visible and restored_flower_spot.built, "loading should restore built garden spots")
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
