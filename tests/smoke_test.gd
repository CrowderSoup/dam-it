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
	# Never read, overwrite, or delete the player's real user:// save slots.
	SaveManager.set_storage_root_for_tests("user://automated_tests")
	# A leftover test save file in slot 1 (from a previous run) would get loaded
	# into `main` below and silently invalidate every assertion that
	# follows. Main no longer auto-loads without a session, so begin one
	# first - the same thing the title screen does when a slot is picked.
	SaveManager.begin_session(1)
	SaveManager.delete_save(1)

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
	var cattail1: PondPlant = main.get_node("PondPlants/Cattail1")

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
	assert(GameState.wood == 3 and tree1.depleted, "expected 3 wood, tree felled after 3 hits")
	tree1.chop()
	assert(GameState.wood == 3, "chopping a felled tree should not yield more wood")
	assert(GameState.energy == energy_before_chop, "chopping before the dam/pond exists should not spend energy")
	print("OK: chopping a tree 3 times yields wood and fells it; felled trees give no more")

	var energy_before_mine := GameState.energy
	for i in 2:
		rock1.mine()
	assert(GameState.stone == 2 and rock1.depleted, "expected 2 stone, rock broken after 2 hits")
	rock1.mine()
	assert(GameState.stone == 2, "mining a broken rock should not yield more stone")
	assert(GameState.energy == energy_before_mine, "mining before the dam/pond exists should not spend energy")
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

	assert(berry_bush1.can_harvest(), "a fresh berry bush should be harvestable")
	assert(player._resolve_target(berry_bush1) == berry_bush1)
	var berries_before_harvest := GameState.berries
	var energy_before_harvest := GameState.energy
	berry_bush1.harvest()
	assert(GameState.berries == berries_before_harvest + BerryBush.HARVEST_AMOUNT, "harvesting should add HARVEST_AMOUNT berries")
	assert(GameState.energy == energy_before_harvest, "harvesting berries should not restore energy - that's cattails/lilies now")
	assert(not berry_bush1.can_harvest(), "a just-harvested bush should not be harvestable again until it respawns")
	berry_bush1.harvest()
	assert(GameState.berries == berries_before_harvest + BerryBush.HARVEST_AMOUNT, "harvesting a picked bush should be a no-op")
	print("OK: harvesting a berry bush stockpiles berries once, then blocks re-harvesting until it respawns")

	# --- Ambient energy drain is gated behind the pond (dam completion) ---
	assert(not GameState.is_dam_complete(), "dam should not be complete yet")
	assert(not cattail1.visible, "pond plants should stay hidden before the dam is complete")
	var energy_before_ambient := GameState.energy
	player._physics_process(player.AMBIENT_DRAIN_INTERVAL + 1.0)
	assert(GameState.energy == energy_before_ambient, "ambient energy drain should not run before the dam/pond exists")
	print("OK: energy does not drain before the dam is finished")

	assert(not lodge.visible, "lodge should be hidden before the dam is finished")
	assert(not lodge.can_advance())
	print("OK: lodge starts hidden")

	assert(GameState.can_afford_dam_piece())
	assert(dam_slot1.can_build())
	var energy_before_build := GameState.energy
	GameState.spend_resources_on_dam_piece()
	dam_slot1.build()
	assert(GameState.dam_pieces_built == 1 and not dam_slot1.can_build())
	assert(GameState.energy == energy_before_build, "building dam pieces before the pond exists should not spend energy")
	print("OK: building a dam piece spends resources and marks the slot built, without spending energy")

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

	# --- Pond plants appear once the pond does, and ambient drain kicks in ---
	assert(GameState.is_dam_complete())
	assert(cattail1.visible, "pond plants should appear once the dam/pond is complete")
	assert(cattail1.can_eat(), "a fresh pond plant should be eatable")
	assert(player._resolve_target(cattail1) == cattail1)
	GameState.spend_energy(50.0)
	var energy_before_pond_eat := GameState.energy
	cattail1.eat()
	assert(GameState.energy == energy_before_pond_eat + PondPlant.ENERGY_RESTORE, "eating a pond plant should restore ENERGY_RESTORE energy")
	assert(not cattail1.can_eat(), "a just-eaten pond plant should not be eatable again until it regrows")
	cattail1.eat()
	assert(GameState.energy == energy_before_pond_eat + PondPlant.ENERGY_RESTORE, "eating an already-picked pond plant should be a no-op")
	print("OK: eating a pond plant restores energy once, then blocks re-eating until it regrows")

	var energy_before_ambient_active := GameState.energy
	player._physics_process(player.AMBIENT_DRAIN_INTERVAL + 1.0)
	assert(GameState.energy == energy_before_ambient_active, "ambient energy drain should not run while the player is idle")
	Input.action_press("move_right")
	player._physics_process(player.AMBIENT_DRAIN_INTERVAL + 1.0)
	Input.action_release("move_right")
	assert(GameState.energy == energy_before_ambient_active - player.AMBIENT_DRAIN_AMOUNT, "ambient energy drain should run while moving once the dam/pond exists")
	print("OK: energy drains during active movement once the dam is finished, but not while idle")

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

	# --- Scavenger: feeding it berries vs. steal-and-flee ---
	assert(not raccoon.can_feed(), "raccoon should be inactive until spawned")
	raccoon.spawn_at(Vector2(300, 300))
	hud.point_to_raccoon(raccoon)
	GameState.remove_berries(GameState.berries)
	assert(GameState.berries == 0, "berries should be empty after draining stock for this check")
	assert(not raccoon.can_feed(), "feeding should require at least one berry in stock")
	assert(raccoon.visible, "spawn_at() should show the raccoon even without berries to feed it")
	assert(player._resolve_target(raccoon) == raccoon)

	GameState.add_berries(1)
	assert(raccoon.can_feed(), "feeding should be possible once a berry is in stock")
	raccoon.feed()
	assert(GameState.berries == 0, "feed() should spend the berry")
	assert(not raccoon.can_feed() and not raccoon.visible, "feed() should despawn the raccoon with no theft")
	assert(hud.raccoon_indicator.target == null, "despawning (via feed) should clear the raccoon indicator")
	print("OK: feeding the raccoon a berry despawns it without stealing anything, and clears its indicator")

	raccoon.spawn_at(Vector2(300, 300))
	var wood_before_theft := GameState.wood
	var stone_before_theft := GameState.stone
	raccoon._steal_and_flee()
	assert(GameState.wood == wood_before_theft - Raccoon.STEAL_WOOD, "the raccoon should steal STEAL_WOOD wood")
	assert(GameState.stone == stone_before_theft - Raccoon.STEAL_STONE, "the raccoon should steal STEAL_STONE stone")
	assert(not raccoon.can_feed(), "the raccoon should despawn after stealing")
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

	# --- Pouch capacity + upgrades ---
	GameState.wood = 0
	GameState.stone = 0
	assert(GameState.pouch_tier == 0 and GameState.wood_capacity() == GameState.POUCH_BASE_CAPACITY, "pouch should start at tier 0 / base capacity")
	GameState.add_wood(GameState.POUCH_BASE_CAPACITY + 5)
	GameState.add_stone(GameState.POUCH_BASE_CAPACITY + 5)
	assert(GameState.wood == GameState.POUCH_BASE_CAPACITY and GameState.stone == GameState.POUCH_BASE_CAPACITY, "add_wood()/add_stone() should clamp at the pouch's capacity")
	assert(not GameState.has_wood_room() and not GameState.has_stone_room(), "a full pouch should report no room left")

	var pouch_full_events := []
	GameState.pouch_full.connect(func(kind): pouch_full_events.append(kind))
	tree1.depleted = false
	tree1.hits_taken = 0
	tree1.chop()
	assert(GameState.wood == GameState.POUCH_BASE_CAPACITY, "chopping with a full wood pouch should not add more wood")
	assert(tree1.hits_taken == 0, "chopping with a full pouch should not register a hit, so nothing is wasted")
	rock1.depleted = false
	rock1.hits_taken = 0
	rock1.mine()
	assert(GameState.stone == GameState.POUCH_BASE_CAPACITY, "mining with a full stone pouch should not add more stone")
	assert(rock1.hits_taken == 0, "mining with a full pouch should not register a hit either")
	assert(pouch_full_events == ["wood", "stone"], "a blocked chop/mine should emit pouch_full() so the HUD can toast it")
	print("OK: a full pouch blocks further chopping/mining until there's room")

	assert(GameState.can_afford_pouch_upgrade(), "a full pouch (10/10) should afford the first upgrade (6 wood/3 stone)")
	assert(lodge.can_upgrade_pouch(), "a maxed lodge should offer a pouch upgrade when one is affordable")
	lodge.upgrade_pouch()
	assert(GameState.pouch_tier == 1, "upgrade_pouch() should raise the pouch tier")
	assert(GameState.wood_capacity() == GameState.POUCH_BASE_CAPACITY + GameState.POUCH_CAPACITY_PER_TIER, "wood capacity should grow by one tier's worth")
	assert(GameState.stone_capacity() == GameState.POUCH_BASE_CAPACITY + GameState.POUCH_CAPACITY_PER_TIER, "stone capacity should grow by one tier's worth too")
	print("OK: upgrading the pouch at a finished lodge raises both wood and stone capacity")

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

	# "restart" is intentionally keyboard-only (see the safe-controls test
	# block below) - a gamepad can only reach new-game through the paused
	# menu's confirmed New Game button, never a single unconfirmed button.
	for action_name in ["move_up", "move_down", "move_left", "move_right", "interact", "restart", "menu"]:
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
		if action_name == "restart":
			assert(not has_joy, "restart must not be directly reachable from a gamepad button")
		else:
			assert(has_joy, "%s has no joypad event" % action_name)
	for event in InputMap.action_get_events("menu"):
		if event is InputEventJoypadButton:
			assert(event.button_index in [JOY_BUTTON_START, JOY_BUTTON_BACK], "menu should only bind Start/Back, not restart's old Start binding")
	print("OK: all actions have physical, logical bindings; restart is keyboard-only and menu owns gamepad Start/Back")

	# --- Safe controls: the "restart" shortcut (keyboard R) never destroys
	# progress on its own - it only ever reaches game_menu's existing
	# confirmation dialog, same as clicking "New Game" would. ---
	var game_menu: CanvasLayer = main.get_node("GameMenu")
	assert(not game_menu.visible, "game menu should start closed")
	# main's own listener would delete the save and reload the scene once
	# confirmed - disconnect it here so this block can exercise the menu's
	# confirm/cancel logic itself without tearing down the rest of the test.
	game_menu.new_game_requested.disconnect(main._start_new_game)
	var new_game_signaled := [false]
	game_menu.new_game_requested.connect(func(): new_game_signaled[0] = true)
	var wood_before_new_game_request := GameState.wood

	game_menu.request_new_game()
	assert(game_menu.visible, "request_new_game() should open the paused menu behind the confirmation")
	assert(get_tree().paused, "opening the menu for a new-game request should pause the tree")
	assert(game_menu.confirm_new_game.visible, "request_new_game() should show the confirmation dialog")
	assert(game_menu.resume_button.has_focus(), "opening the menu should focus Resume, not Save")

	game_menu.confirm_new_game.hide()
	assert(not new_game_signaled[0], "dismissing the confirmation must not start a new game")
	assert(GameState.wood == wood_before_new_game_request, "dismissing the confirmation must leave existing progress untouched")
	assert(game_menu.visible and get_tree().paused, "dismissing only the confirmation should leave the menu itself open")
	game_menu.close()
	assert(not get_tree().paused, "closing the menu should unpause the tree")

	game_menu.request_new_game()
	# A real click on the dialog's OK button hides the window itself before/
	# alongside emitting "confirmed" - replicate both since emitting the
	# signal alone (unlike a real click) would leave the window registered
	# as root's exclusive child and break the next dialog's popup.
	game_menu.confirm_new_game.hide()
	game_menu.confirm_new_game.confirmed.emit()
	assert(new_game_signaled[0], "confirming should emit new_game_requested")
	assert(not game_menu.visible and not get_tree().paused, "confirming should close the menu and unpause")
	print("OK: request_new_game() reaches new_game_requested only through an explicit confirmation, and cancelling preserves progress")

	# --- Save / load (slot-based) ---
	var dam_slot2: Area2D = main.get_node("DamSlots/DamSlot2")
	dam_slot2.start_leaking()

	SaveManager.delete_save(1)
	assert(not SaveManager.has_save(1))
	assert(SaveManager.peek_slot(1).is_empty(), "peek_slot() should be empty for a slot with no save file")

	GameState.spend_energy(37.0)
	GameState.add_berries(3)
	var saved_data: Dictionary = main.get_save_data()
	assert(saved_data["wood"] == GameState.wood)
	assert(saved_data["berries"] == GameState.berries)
	assert(saved_data["energy"] == GameState.energy)
	assert(saved_data["lodge_stage"] == GameState.LODGE_MAX_STAGE)
	assert(saved_data["pouch_tier"] == GameState.pouch_tier)
	assert(saved_data["dam_slots_built"]["DamSlot1"] == true)
	assert(saved_data["dam_slots_leaking"]["DamSlot2"] == true)
	assert(saved_data["garden_spots_built"]["FlowerBedSpot"] == true)

	# save_game() reads get_tree().current_scene, which Godot only allows to
	# be a direct child of root - reparent there just for this call, the
	# same shape the real game runs in.
	main.reparent(get_tree().root)
	get_tree().current_scene = main
	assert(SaveManager.save_game(), "save_game() should report a successful write")
	get_tree().current_scene = self
	main.reparent(self)
	assert(SaveManager.has_save(1), "save_game() should have written a save file to the active session's slot")
	assert(not SaveManager.has_save(2), "save_game() must not touch other slots")
	main.reparent(get_tree().root)
	get_tree().current_scene = main
	assert(SaveManager.save_game(), "save_game() should atomically replace an existing save")
	get_tree().current_scene = self
	main.reparent(self)
	print("OK: save_game() writes a save file to the active session's slot only")

	assert(SaveManager.peek_slot(1)["wood"] == saved_data["wood"], "peek_slot() should read back what was saved, without starting a session")
	assert(SaveManager.peek_slot(1)["save_version"] == SaveManager.SAVE_VERSION, "saved data should include its format version")
	print("OK: peek_slot() reads a slot's data without loading it into a scene")

	# --- Title screen save-slot rows. title_screen.gd itself just wires a
	# row's slot_chosen signal to change_scene_to_file(), which we don't
	# want to trigger mid-test - so exercise the row directly. Slot 1 is
	# read-only here (main2 below still needs its save intact); slot 2 is
	# untouched so far and safe to fully exercise. ---
	var occupied_row: Panel = load("res://scenes/ui/save_slot_row.tscn").instantiate()
	occupied_row.slot_index = 1
	add_child(occupied_row)
	assert(occupied_row.continue_button.visible, "a slot with a save should offer Continue")
	assert(occupied_row.info_label.text.begins_with("Dam "), "an occupied slot should summarize its progress, got: %s" % occupied_row.info_label.text)
	var occupied_chosen := [-1]
	occupied_row.slot_chosen.connect(func(i): occupied_chosen[0] = i)
	occupied_row._on_new_game_pressed()
	assert(occupied_chosen[0] == -1, "New Game on an occupied slot must ask for confirmation before doing anything")
	assert(occupied_row.confirm_overwrite.visible, "the overwrite confirmation dialog should be showing")
	print("OK: New Game on an occupied save-slot row requires confirmation before touching anything")

	var empty_row: Panel = load("res://scenes/ui/save_slot_row.tscn").instantiate()
	empty_row.slot_index = 2
	add_child(empty_row)
	assert(not empty_row.continue_button.visible, "an empty slot should not offer Continue")
	assert(empty_row.info_label.text == "Empty", "an empty slot should say Empty")
	var empty_chosen := [-1]
	empty_row.slot_chosen.connect(func(i): empty_chosen[0] = i)
	empty_row._on_new_game_pressed()
	assert(empty_chosen[0] == 2, "New Game on an empty slot should start immediately, with no confirmation needed")
	print("OK: New Game on an empty save-slot row skips the overwrite confirmation")

	GameState.reset()
	assert(GameState.wood == 0 and GameState.lodge_stage == 0)
	assert(GameState.berries == 0, "reset() should zero out berries")
	assert(GameState.energy == GameState.ENERGY_MAX, "reset() should restore energy to max")

	SaveManager.current_slot = -1
	var main_no_session: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_no_session)
	assert(GameState.wood == 0, "load_into() must be a no-op with no active session, so nothing auto-loads before a slot is picked")
	print("OK: nothing auto-loads before begin_session() runs (i.e. before the title screen picks a slot)")

	# main_no_session's own DamSlots just registered themselves with
	# GameState (dam_pieces_total is a running count across every Main
	# instance in the tree, real gameplay only ever has one) - reset again
	# so main2 below starts from a clean 0 and its apply_save_data() sees
	# built_count == dam_pieces_total as it would in a real session.
	GameState.reset()
	SaveManager.begin_session(1)
	var main2: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main2)
	# main2's own _ready() calls SaveManager.load_into(self), so by the time
	# add_child() returns, it should already be restored.
	assert(GameState.wood == saved_data["wood"], "loading should restore wood")
	assert(GameState.berries == saved_data["berries"], "loading should restore berries")
	assert(GameState.energy == saved_data["energy"], "loading should restore energy")
	assert(GameState.lodge_stage == GameState.LODGE_MAX_STAGE, "loading should restore lodge stage")
	assert(GameState.pouch_tier == saved_data["pouch_tier"], "loading should restore the pouch tier")
	var restored_slot1: Area2D = main2.get_node("DamSlots/DamSlot1")
	assert(restored_slot1.built, "loading should restore built dam slots")
	var restored_slot2: Area2D = main2.get_node("DamSlots/DamSlot2")
	assert(restored_slot2.leaking, "loading should restore a leaking dam slot")
	assert(restored_slot2.can_repair())
	var restored_lodge: Area2D = main2.get_node("Lodge")
	assert(restored_lodge.visible, "loading should reveal the lodge if the dam was complete")
	var restored_cattail: PondPlant = main2.get_node("PondPlants/Cattail1")
	assert(restored_cattail.visible, "loading should reveal pond plants if the dam was complete")
	var restored_flower_spot: GardenSpot = main2.get_node("GardenSpots/FlowerBedSpot")
	assert(restored_flower_spot.visible and restored_flower_spot.built, "loading should restore built garden spots")
	var restored_butterfly: Node2D = main2.get_node("Critters/Butterfly")
	assert(restored_butterfly.visible, "loading a built garden spot should re-reveal its critter")
	print("OK: a fresh scene instance auto-loads the active session's slot on _ready()")

	SaveManager.delete_save(1)
	assert(not SaveManager.has_save(1))
	print("OK: delete_save() removes a slot's save file")

	# --- Invalid/out-of-range save values are safe and bounded ---
	GameState.load_from_save({
		"wood": 999,
		"stone": -4,
		"berries": -3,
		"lodge_stage": 999,
		"energy": 999,
		"pouch_tier": 99,
	})
	assert(GameState.pouch_tier == GameState.POUCH_MAX_TIER, "saved pouch tier should clamp to the supported maximum")
	assert(GameState.wood == GameState.wood_capacity(), "saved wood should clamp to the restored pouch capacity")
	assert(GameState.stone == 0 and GameState.berries == 0, "saved resources should not load below zero")
	assert(GameState.lodge_stage == GameState.LODGE_MAX_STAGE and GameState.energy == GameState.ENERGY_MAX, "saved progress and energy should clamp to valid maxima")
	GameState.load_from_save({"pouch_tier": "invalid", "wood": "invalid", "energy": "invalid"})
	assert(GameState.pouch_tier == 0 and GameState.wood == 0, "wrongly typed pouch/resource values should use safe defaults")
	assert(GameState.energy == GameState.ENERGY_MAX, "wrongly typed energy should use its safe default")
	print("OK: malformed and out-of-range save values fall back or clamp safely")

	GameState.reset()
	assert(GameState.wood == 0 and GameState.stone == 0)
	assert(GameState.dam_pieces_built == 0)
	assert(GameState.lodge_stage == 0)
	assert(GameState.pouch_tier == 0, "reset() should zero the pouch tier")
	print("OK: GameState.reset() zeroes progress including lodge_stage and pouch_tier")

	# Let the lodge-advance Fx.burst() timers run their course before quitting.
	await get_tree().create_timer(1.0).timeout

	print("ALL SMOKE TESTS PASSED")
	get_tree().quit()
