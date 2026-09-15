extends Node2D
## Wires up the "pond appears behind the finished dam" celebration, lets the
## player restart the level at any time, owns save/load for the level
## (SaveManager only knows how to read/write the file - it asks us for the
## data and hands us back whatever it finds on disk), and runs the ongoing
## low-stakes ongoing challenges: storms begin once the dam is complete, while
## recurring scavenging remains locked behind Bramble's authored introduction.
## It keeps the HUD's edge-arrow indicators pointed at whichever is currently
## active and connects Willowbend's authored Act I story beats to the
## world-state signals that actually earn them.

const STORM_MIN_INTERVAL := 90.0
const STORM_MAX_INTERVAL := 150.0
const RACCOON_MIN_INTERVAL := 60.0
const RACCOON_MAX_INTERVAL := 120.0
const RACCOON_SPAWN_POINTS := [
	Vector2(250, 150), Vector2(1150, 200), Vector2(250, 650), Vector2(1000, 650), Vector2(700, 720),
]

## Emitted only when the complete #21 eligibility contract changes. The ending
## controller can schedule/cancel its safe delay from this signal without
## inferring story readiness from resident visibility or Lodge artwork.
signal act_one_ending_eligibility_changed(eligible: bool)

@onready var pond: Polygon2D = $Pond
@onready var river_water: Area2D = $RiverWater
@onready var dam_slots: Node2D = $DamSlots
@onready var lodge: Area2D = $Lodge
@onready var pond_plants: Node2D = $PondPlants
@onready var garden_spots: Node2D = $GardenSpots
@onready var raccoon: Raccoon = $Raccoon
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var game_menu: CanvasLayer = $GameMenu
@onready var journal: CanvasLayer = $Journal
@onready var dialogue_box: CanvasLayer = $DialogueBox

var _storms_active := false
var _storm_timer: Timer
var _raccoon_timer: Timer
var _act_one_ending_was_eligible := false

func _ready() -> void:
	hud.set_camera(camera)
	player.interaction_option_changed.connect(hud.set_action_prompt)
	player.interaction_failed.connect(hud.show_failure)
	for slot in dam_slots.get_children():
		slot.leak_changed.connect(_update_storm_indicator)
	raccoon.despawned.connect(_on_raccoon_despawned)

	GameState.dam_completed.connect(_on_dam_completed)
	GameState.dam_completed.connect(_start_challenges)
	GameState.water_observed.connect(_on_water_observed)
	GameState.dam_progress_changed.connect(_on_dam_progress_changed)
	GameState.lodge_stage_changed.connect(_on_lodge_stage_changed)
	game_menu.new_game_requested.connect(_start_new_game)
	game_menu.set_journal(journal)
	journal.set_game_menu(game_menu)
	game_menu.visibility_changed.connect(_refresh_act_one_ending_eligibility)
	journal.visibility_changed.connect(_refresh_act_one_ending_eligibility)
	hud.journal_requested.connect(journal.open)
	# A dialogue pauses the tree itself (see dialogue_box.gd), same as
	# GameMenu - but GameMenu stays PROCESS_MODE_ALWAYS so it can still open
	# while paused. Without this, Escape/Start during a conversation would
	# pop the pause menu on top of it instead of leaving dialogue input
	# (advance/choose) as the only thing "menu" and friends can reach.
	ActOneController.dialogue_started.connect(_on_dialogue_started)
	ActOneController.dialogue_ended.connect(_on_dialogue_ended)
	ActOneController.objective_started.connect(_on_story_objective_started)
	ActOneController.objective_completed.connect(_on_story_objective_completed)
	ActOneController.flag_changed.connect(_on_story_flag_changed)
	# Story content must exist before apply_save_data() asks the controller to
	# restore objective/dialogue ids. The old order silently discarded every
	# saved story entry as unknown, then started the first objective fresh.
	_setup_act1_story()
	SaveManager.load_into(self)
	# Select dry/restored ambience from the fully applied save. This path is
	# intentionally sting-free; only the live dam_completed signal celebrates.
	Ambience.sync_from_game_state(true)
	_refresh_resident_visibility()
	_reconcile_act1_story()
	hud.restore_from_state()
	dialogue_box.restore_from_state()
	if not ActOneController.get_active_dialogue_id().is_empty():
		_on_dialogue_started(ActOneController.get_active_dialogue_id())
	_refresh_act_one_ending_eligibility()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		game_menu.request_new_game()

func _on_dialogue_started(_dialogue_id: String) -> void:
	game_menu.process_mode = Node.PROCESS_MODE_DISABLED
	journal.process_mode = Node.PROCESS_MODE_DISABLED
	_refresh_act_one_ending_eligibility()

func _on_dialogue_ended(_dialogue_id: String) -> void:
	# game_menu.tscn sets GameMenu's own process_mode to ALWAYS (see its
	# docstring) so it can open while paused - restore that, not the
	# CanvasLayer default of INHERIT, or Escape/Start would stop reaching it
	# once a dialogue has been opened and closed.
	game_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	journal.process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_act_one_ending_eligibility()

## Shared by the "restart" shortcut and the game menu's "New Game" button.
func _start_new_game() -> void:
	SaveManager.delete_save(SaveManager.current_slot)
	GameState.reset()
	# ActOneController is an autoload, so its story flags/objectives/active
	# dialogue would otherwise survive reload_current_scene() into the fresh
	# session below - e.g. a start_dialogue() call after restart would hit
	# the "already active" assert in act_one_controller.gd if a dialogue was
	# still open when New Game was confirmed.
	ActOneController.reset()
	get_tree().reload_current_scene()

## Registers the Willowbend narrative in story order. Registration happens
## before save restoration so every saved id is known to the controller.
## Idempotent because tests may instantiate several Main scenes in one run.
func _setup_act1_story() -> void:
	if not ActOneController.has_objective("gather_starter_wood"):
		var objectives: Array[ObjectiveDefinition] = [
			load("res://data/story/act1/objective_meet_moss.tres"),
			load("res://data/story/act1/objective_gather_starter_wood.tres"),
			load("res://data/story/act1/objective_read_willowbend_water.tres"),
			load("res://data/story/act1/objective_repair_willowbend_dam.tres"),
			load("res://data/story/act1/objective_witness_pond_return.tres"),
			load("res://data/story/act1/objective_check_eddy_route.tres"),
			load("res://data/story/act1/objective_build_lodge_foundation.tres"),
			load("res://data/story/act1/objective_talk_moss_home.tres"),
			load("res://data/story/act1/objective_finish_willowbend_lodge.tres"),
			load("res://data/story/act1/objective_answer_marnie.tres"),
		]
		var dialogues: Array[DialogueDefinition] = [
			load("res://data/story/act1/dialogue_willowbend_arrival.tres"),
			load("res://data/story/act1/dialogue_moss_intro.tres"),
			load("res://data/story/act1/dialogue_moss_supplies_ready.tres"),
			load("res://data/story/act1/dialogue_pond_returns.tres"),
			load("res://data/story/act1/dialogue_eddy_flow_check.tres"),
			load("res://data/story/act1/dialogue_moss_lodge_foundation.tres"),
			load("res://data/story/act1/dialogue_moss_lodge_walls.tres"),
			load("res://data/story/act1/dialogue_marnie_upstream_call.tres"),
		]
		ActOneController.load_content(objectives, dialogues)

## Fresh games begin with a short authored arrival. Existing saves retain
## their exact objective/dialogue boundary, including saves from before this
## content existed (which enter through the same arrival rather than being
## dropped into the middle of Act I).
func _reconcile_act1_story() -> void:
	if ActOneController.get_active_dialogue_id().is_empty() \
			and ActOneController.get_current_objective_id().is_empty():
		ActOneController.start_dialogue("willowbend_arrival")
		return
	_sync_active_story_progress()

func _on_story_objective_started(_objective_id: String) -> void:
	_sync_active_story_progress()
	_refresh_act_one_ending_eligibility()

func _on_story_objective_completed(objective_id: String) -> void:
	match objective_id:
		"gather_starter_wood":
			ActOneController.start_objective("read_willowbend_water")
		"repair_willowbend_dam":
			ActOneController.start_objective("witness_pond_return")
		"finish_willowbend_lodge":
			ActOneController.start_objective("answer_marnie")
	_refresh_act_one_ending_eligibility()

func _on_water_observed() -> void:
	_sync_active_story_progress()

func _on_dam_progress_changed(_built: int, _total: int) -> void:
	_sync_active_story_progress()

func _on_lodge_stage_changed(_stage: int) -> void:
	_sync_active_story_progress()
	_refresh_act_one_ending_eligibility()

## The pure, public handoff from #20 to #21. Stage three alone is deliberately
## insufficient: the pond response, Eddy's flow check, and Marnie's request
## (whose closing Moss line acknowledges Reed's home) must all be complete.
## Presentation overlays and the ending's own durable flags prevent an unsafe
## or duplicate start. This method never mutates story or world state.
func is_act_one_ending_eligible() -> bool:
	return GameState.lodge_stage == GameState.LODGE_MAX_STAGE \
		and ActOneController.get_flag("pond_restored") \
		and ActOneController.get_objective_status("check_eddy_route") == "completed" \
		and ActOneController.get_flag("willowbend_narrative_spine_complete") \
		and ActOneController.get_active_dialogue_id().is_empty() \
		and not game_menu.visible \
		and not journal.visible \
		and not ActOneController.get_flag("act_one_ending_started") \
		and not ActOneController.get_flag("act_one_complete")

func _refresh_act_one_ending_eligibility() -> void:
	var eligible := is_act_one_ending_eligible()
	if eligible == _act_one_ending_was_eligible:
		return
	_act_one_ending_was_eligible = eligible
	act_one_ending_eligibility_changed.emit(eligible)

## World events report absolute totals and may be re-announced after load.
## The controller setter is therefore absolute/idempotent too: no save can
## accidentally count a dam piece or Lodge stage twice.
func _sync_active_story_progress() -> void:
	if ActOneController.get_objective_status("read_willowbend_water") == "active" \
			and GameState.water_read:
		ActOneController.complete_objective("read_willowbend_water")
		ActOneController.start_objective("repair_willowbend_dam")

	if ActOneController.get_objective_status("repair_willowbend_dam") == "active":
		ActOneController.set_objective_progress("repair_willowbend_dam", GameState.dam_pieces_built)
		if GameState.is_dam_complete():
			ActOneController.complete_objective("repair_willowbend_dam")

	if ActOneController.get_objective_status("build_lodge_foundation") == "active":
		ActOneController.set_objective_progress("build_lodge_foundation", GameState.lodge_stage)
		if GameState.lodge_stage >= 1:
			ActOneController.complete_objective("build_lodge_foundation")
			ActOneController.start_objective("talk_moss_home")

	if ActOneController.get_objective_status("finish_willowbend_lodge") == "active":
		ActOneController.set_objective_progress("finish_willowbend_lodge", GameState.lodge_stage)
		if GameState.lodge_stage >= 2 \
				and not ActOneController.get_flag("moss_saw_lodge_walls"):
			ActOneController.set_flag("lodge_walls_ready")
		if GameState.lodge_stage >= GameState.LODGE_MAX_STAGE:
			ActOneController.complete_objective("finish_willowbend_lodge")

func _refresh_resident_visibility() -> void:
	for resident in $Residents.get_children():
		resident.restore_from_story_state()

func _on_dam_completed() -> void:
	river_water.queue_free()

	pond.show()
	pond.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(pond, "modulate:a", 1.0, 2.0)

	for slot in dam_slots.get_children():
		Fx.burst(slot.global_position, Color(0.85, 0.95, 1.0), 16)

	var base_zoom := camera.zoom
	var zoom_tween := create_tween()
	zoom_tween.tween_property(camera, "zoom", base_zoom * 1.15, 0.25)
	zoom_tween.tween_property(camera, "zoom", base_zoom, 0.4)

## Storms begin once there's a finished dam to threaten. Recurring scavenging
## has its own authored-introduction gate below.
## Idempotent: safe to call from both the live dam_completed signal and
## the save-load path (a save can already have the dam complete).
func _start_challenges() -> void:
	if _storms_active:
		_start_recurring_scavenging_if_eligible()
		return
	_storms_active = true

	_storm_timer = Timer.new()
	_storm_timer.one_shot = true
	add_child(_storm_timer)
	_storm_timer.timeout.connect(_on_storm_timeout)
	_schedule_next_storm()

	_start_recurring_scavenging_if_eligible()

func _schedule_next_storm() -> void:
	_storm_timer.wait_time = randf_range(STORM_MIN_INTERVAL, STORM_MAX_INTERVAL)
	_storm_timer.start()

func _on_storm_timeout() -> void:
	var candidates: Array = []
	for slot in dam_slots.get_children():
		if slot.built and not slot.leaking:
			candidates.append(slot)
	if candidates.size() > 0:
		var slot = candidates[randi() % candidates.size()]
		slot.start_leaking()
		Sfx.play_storm()
		hud.show_toast("A storm damaged a dam piece!")
	_schedule_next_storm()

## Points the storm indicator at whichever leaking slot is nearest the
## player, or clears it once none remain. Connected to every slot's
## leak_changed signal, so this stays correct through repairs too.
func _update_storm_indicator() -> void:
	var nearest: Area2D = null
	var nearest_dist := INF
	for slot in dam_slots.get_children():
		if slot.leaking:
			var dist: float = player.global_position.distance_squared_to(slot.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = slot
	if nearest:
		hud.point_to_storm(nearest)
	else:
		hud.clear_storm_indicator()

func _schedule_next_raccoon() -> void:
	if not is_instance_valid(_raccoon_timer):
		return
	_raccoon_timer.wait_time = randf_range(RACCOON_MIN_INTERVAL, RACCOON_MAX_INTERVAL)
	_raccoon_timer.start()

## Bramble's first appearance is authored in a later #20 slice. Until that
## encounter has completed, no random timer exists and scavenging is
## impossible even on a restored dam-complete save.
func _start_recurring_scavenging_if_eligible() -> void:
	if not _storms_active or not ActOneController.get_flag("bramble_intro_complete"):
		return
	if is_instance_valid(_raccoon_timer):
		return
	_raccoon_timer = Timer.new()
	_raccoon_timer.one_shot = true
	add_child(_raccoon_timer)
	_raccoon_timer.timeout.connect(_on_raccoon_timeout)
	_schedule_next_raccoon()

func _on_story_flag_changed(flag_name: String, value: bool) -> void:
	_refresh_act_one_ending_eligibility()
	if flag_name != "bramble_intro_complete":
		return
	if value:
		_start_recurring_scavenging_if_eligible()
	elif is_instance_valid(_raccoon_timer):
		_raccoon_timer.stop()
		_raccoon_timer.queue_free()
		_raccoon_timer = null

func is_recurring_scavenging_enabled() -> bool:
	return is_instance_valid(_raccoon_timer)

func _on_raccoon_timeout() -> void:
	var spawn_point: Vector2 = RACCOON_SPAWN_POINTS[randi() % RACCOON_SPAWN_POINTS.size()]
	raccoon.spawn_at(spawn_point)
	hud.point_to_raccoon(raccoon)
	hud.show_toast("A raccoon is nearby!")

func _on_raccoon_despawned() -> void:
	hud.clear_raccoon_indicator()
	_schedule_next_raccoon()

func get_save_data() -> Dictionary:
	var dam_slots_built := {}
	var dam_slots_leaking := {}
	for slot in dam_slots.get_children():
		dam_slots_built[slot.name] = slot.built
		dam_slots_leaking[slot.name] = slot.leaking
	var garden_spots_built := {}
	for spot in garden_spots.get_children():
		garden_spots_built[spot.name] = spot.built
	return {
		"wood": GameState.wood,
		"stone": GameState.stone,
		"berries": GameState.berries,
		"energy": GameState.energy,
		"lodge_stage": GameState.lodge_stage,
		"pouch_tier": GameState.pouch_tier,
		"seen_tutorials": GameState.seen_tutorials,
		"dam_slots_built": dam_slots_built,
		"dam_slots_leaking": dam_slots_leaking,
		"garden_spots_built": garden_spots_built,
		"player_x": player.global_position.x,
		"player_y": player.global_position.y,
		# Story flags/objective progress/mid-dialogue boundary, introduced in
		# save version 2 (see docs/design/dialogue-schema.md#save-load).
		# ActOneController owns the semantics of what's in here; Main just
		# slots it into the payload alongside its own scene-shaped state.
		"story": ActOneController.get_save_data(),
	}

func apply_save_data(data: Dictionary) -> void:
	GameState.load_from_save(data)
	# Content (objectives/dialogues) must already be registered via
	# _setup_act1_story() before this runs; otherwise every saved id would
	# be treated as removed content and silently skipped.
	ActOneController.load_from_save(_saved_dictionary(data, "story"))

	var built_count := 0
	var slots_built := _saved_dictionary(data, "dam_slots_built")
	var slots_leaking := _saved_dictionary(data, "dam_slots_leaking")
	for slot in dam_slots.get_children():
		if slots_built.get(slot.name, false):
			slot.set_built_silently(true)
			built_count += 1
			if slots_leaking.get(slot.name, false):
				slot.set_leaking_silently(true)
	GameState.restore_dam_progress(built_count)

	if built_count > 0 and built_count >= GameState.dam_pieces_total:
		_apply_completed_dam_visuals()
		lodge.reveal()
		for plant in pond_plants.get_children():
			plant.reveal()
		_start_challenges()

	if GameState.lodge_stage >= GameState.LODGE_MAX_STAGE:
		var spots_built := _saved_dictionary(data, "garden_spots_built")
		for spot in garden_spots.get_children():
			spot.reveal()
			if spots_built.get(spot.name, false):
				spot.set_built_silently(true)

	var saved_x: Variant = data.get("player_x")
	var saved_y: Variant = data.get("player_y")
	if (saved_x is int or saved_x is float) and (saved_y is int or saved_y is float):
		var saved_position := Vector2(float(saved_x), float(saved_y))
		player.global_position = Vector2(
			clampf(saved_position.x, player.WORLD_BOUNDS.position.x, player.WORLD_BOUNDS.end.x),
			clampf(saved_position.y, player.WORLD_BOUNDS.position.y, player.WORLD_BOUNDS.end.y)
		)

	# Only now that dam slots, the lodge, garden spots, and the river are
	# all fully restored is it safe to let anything (HUD, critters,
	# SaveManager's autosave-on-signal) react to the change - see
	# GameState.load_from_save().
	GameState.announce_loaded_state()

func _saved_dictionary(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	return value if value is Dictionary else {}

## Same end state as the _on_dam_completed() tween, applied instantly since
## this is restoring a save rather than reacting to it happening live.
func _apply_completed_dam_visuals() -> void:
	if is_instance_valid(river_water):
		river_water.queue_free()
	pond.show()
	pond.modulate.a = 1.0
