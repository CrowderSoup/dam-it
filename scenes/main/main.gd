extends Node2D
## Wires up the "pond appears behind the finished dam" celebration, lets the
## player restart the level at any time, owns save/load for the level
## (SaveManager only knows how to read/write the file - it asks us for the
## data and hands us back whatever it finds on disk), and runs the ongoing
## "Storms & Scavengers" challenges that start once the dam is complete:
## storms occasionally weaken a dam piece into a leak, and a raccoon
## occasionally shows up to raid the resource pile if not shooed off. Also
## keeps the HUD's edge-arrow indicators pointed at whichever of those is
## currently active.

const STORM_MIN_INTERVAL := 90.0
const STORM_MAX_INTERVAL := 150.0
const RACCOON_MIN_INTERVAL := 60.0
const RACCOON_MAX_INTERVAL := 120.0
const RACCOON_SPAWN_POINTS := [
	Vector2(250, 150), Vector2(1150, 200), Vector2(250, 650), Vector2(1000, 650), Vector2(700, 720),
]

@onready var pond: Polygon2D = $Pond
@onready var river_water: Area2D = $RiverWater
@onready var dam_slots: Node2D = $DamSlots
@onready var lodge: Area2D = $Lodge
@onready var garden_spots: Node2D = $GardenSpots
@onready var raccoon: Raccoon = $Raccoon
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud: CanvasLayer = $HUD

var _challenges_active := false
var _storm_timer: Timer
var _raccoon_timer: Timer

func _ready() -> void:
	hud.set_camera(camera)
	for slot in dam_slots.get_children():
		slot.leak_changed.connect(_update_storm_indicator)
	raccoon.despawned.connect(_on_raccoon_despawned)

	GameState.dam_completed.connect(_on_dam_completed)
	GameState.dam_completed.connect(_start_challenges)
	SaveManager.load_into(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		SaveManager.delete_save()
		GameState.reset()
		get_tree().reload_current_scene()

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

## Storms and the raccoon only begin once there's a finished dam to
## threaten - no point stressing a new player before they have a pond.
## Idempotent: safe to call from both the live dam_completed signal and
## the save-load path (a save can already have the dam complete).
func _start_challenges() -> void:
	if _challenges_active:
		return
	_challenges_active = true

	_storm_timer = Timer.new()
	_storm_timer.one_shot = true
	add_child(_storm_timer)
	_storm_timer.timeout.connect(_on_storm_timeout)
	_schedule_next_storm()

	_raccoon_timer = Timer.new()
	_raccoon_timer.one_shot = true
	add_child(_raccoon_timer)
	_raccoon_timer.timeout.connect(_on_raccoon_timeout)
	_schedule_next_raccoon()

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
	_raccoon_timer.wait_time = randf_range(RACCOON_MIN_INTERVAL, RACCOON_MAX_INTERVAL)
	_raccoon_timer.start()

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
		"lodge_stage": GameState.lodge_stage,
		"dam_slots_built": dam_slots_built,
		"dam_slots_leaking": dam_slots_leaking,
		"garden_spots_built": garden_spots_built,
		"player_x": player.global_position.x,
		"player_y": player.global_position.y,
	}

func apply_save_data(data: Dictionary) -> void:
	GameState.load_from_save(data)

	var built_count := 0
	var slots_built: Dictionary = data.get("dam_slots_built", {})
	var slots_leaking: Dictionary = data.get("dam_slots_leaking", {})
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
		_start_challenges()

	if GameState.lodge_stage >= GameState.LODGE_MAX_STAGE:
		var spots_built: Dictionary = data.get("garden_spots_built", {})
		for spot in garden_spots.get_children():
			spot.reveal()
			if spots_built.get(spot.name, false):
				spot.set_built_silently(true)

	if data.has("player_x") and data.has("player_y"):
		player.global_position = Vector2(data["player_x"], data["player_y"])

	# Only now that dam slots, the lodge, garden spots, and the river are
	# all fully restored is it safe to let anything (HUD, critters,
	# SaveManager's autosave-on-signal) react to the change - see
	# GameState.load_from_save().
	GameState.announce_loaded_state()

## Same end state as the _on_dam_completed() tween, applied instantly since
## this is restoring a save rather than reacting to it happening live.
func _apply_completed_dam_visuals() -> void:
	if is_instance_valid(river_water):
		river_water.queue_free()
	pond.show()
	pond.modulate.a = 1.0
