extends Node2D
## Wires up the "pond rises behind the finished dam" celebration, lets the
## player restart the level at any time, and owns save/load for the level
## (SaveManager only knows how to read/write the file - it asks us for the
## data and hands us back whatever it finds on disk).

@onready var river: ColorRect = $River
@onready var river_water: Area2D = $RiverWater
@onready var dam_slots: Node2D = $DamSlots
@onready var lodge: Area2D = $Lodge
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D

func _ready() -> void:
	GameState.dam_completed.connect(_on_dam_completed)
	SaveManager.load_into(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		SaveManager.delete_save()
		GameState.reset()
		get_tree().reload_current_scene()

func _on_dam_completed() -> void:
	river_water.queue_free()

	var tween := create_tween()
	tween.tween_property(river, "material:shader_parameter/shallow_color", Palette.WATER_POND, 2.0)
	tween.parallel().tween_property(river, "material:shader_parameter/deep_color", Palette.WATER_POND_DEEP, 2.0)
	tween.parallel().tween_property(river, "offset_top", 250.0, 2.0)

	for slot in dam_slots.get_children():
		Fx.burst(slot.global_position, Color(0.85, 0.95, 1.0), 16)

	var base_zoom := camera.zoom
	var zoom_tween := create_tween()
	zoom_tween.tween_property(camera, "zoom", base_zoom * 1.15, 0.25)
	zoom_tween.tween_property(camera, "zoom", base_zoom, 0.4)

func get_save_data() -> Dictionary:
	var dam_slots_built := {}
	for slot in dam_slots.get_children():
		dam_slots_built[slot.name] = slot.built
	return {
		"wood": GameState.wood,
		"stone": GameState.stone,
		"lodge_stage": GameState.lodge_stage,
		"dam_slots_built": dam_slots_built,
		"player_x": player.global_position.x,
		"player_y": player.global_position.y,
	}

func apply_save_data(data: Dictionary) -> void:
	GameState.load_from_save(data)

	var built_count := 0
	var slots_built: Dictionary = data.get("dam_slots_built", {})
	for slot in dam_slots.get_children():
		if slots_built.get(slot.name, false):
			slot.set_built_silently(true)
			built_count += 1
	GameState.restore_dam_progress(built_count)

	if built_count > 0 and built_count >= GameState.dam_pieces_total:
		_apply_completed_dam_visuals()
		lodge.restore_unlocked()

	if data.has("player_x") and data.has("player_y"):
		player.global_position = Vector2(data["player_x"], data["player_y"])

	# Only now that dam slots, the lodge, and the river are all fully
	# restored is it safe to let anything (HUD, critters, SaveManager's
	# autosave-on-signal) react to the change - see GameState.load_from_save().
	GameState.announce_loaded_state()

## Same end state as the _on_dam_completed() tween, applied instantly since
## this is restoring a save rather than reacting to it happening live.
func _apply_completed_dam_visuals() -> void:
	if is_instance_valid(river_water):
		river_water.queue_free()
	river.material.set_shader_parameter("shallow_color", Palette.WATER_POND)
	river.material.set_shader_parameter("deep_color", Palette.WATER_POND_DEEP)
	river.offset_top = 250.0
