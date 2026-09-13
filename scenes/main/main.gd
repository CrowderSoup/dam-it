extends Node2D
## Wires up the "pond rises behind the finished dam" celebration and lets
## the player restart the level at any time.

@onready var river: ColorRect = $River
@onready var river_water: Area2D = $RiverWater
@onready var dam_slots: Node2D = $DamSlots
@onready var camera: Camera2D = $Player/Camera2D

func _ready() -> void:
	GameState.dam_completed.connect(_on_dam_completed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
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
