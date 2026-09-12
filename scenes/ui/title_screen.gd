extends Node2D

@onready var prompt: Label = $Prompt

func _ready() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(prompt, "modulate:a", 0.35, 0.8)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_pressed():
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
