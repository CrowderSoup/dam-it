class_name SurveySpot
extends Area2D
## A one-time, save-safe place observation used by Willowbend's opening survey.

@export var spot_id := ""
@export var action_label := "Inspect the Creek"
@export_multiline var observation := ""

var highlighted := false

func _ready() -> void:
	add_to_group("survey_spots")

func _flag_id() -> String:
	return "surveyed_" + spot_id

func is_observed() -> bool:
	return ActOneController.get_flag(_flag_id())

func set_highlighted(value: bool) -> void:
	highlighted = value
	queue_redraw()

func get_interaction() -> InteractionOption:
	if is_observed() or ActOneController.get_objective_status("read_willowbend_water") != "active":
		return null
	return InteractionOption.new(action_label, observe, true)

func observe() -> void:
	if is_observed():
		return
	ActOneController.set_flag(_flag_id())
	if ActOneController.get_objective_status("read_willowbend_water") == "active":
		ActOneController.advance_objective("read_willowbend_water")
	Sfx.play_harvest()
	Fx.burst(global_position, Palette.WATER_SHALLOW, 8)
	var main := get_parent().get_parent()
	if main and main.has_method("on_survey_spot_observed"):
		main.on_survey_spot_observed(observation)
	queue_redraw()

func _draw() -> void:
	# Willow stakes and a pale field-guide ribbon keep these readable without
	# looking like modern signposts in the creek corridor.
	DrawUtil.shadow(self, Vector2(0, 8), Vector2(8, 3))
	draw_line(Vector2(-5, 8), Vector2(-3, -9), Palette.WOOD_DARK, 2.5)
	draw_line(Vector2(5, 8), Vector2(3, -7), Palette.WOOD_MID, 2.5)
	draw_line(Vector2(-3, -5), Vector2(4, -3), Palette.PETAL_YELLOW if not is_observed() else Palette.LEAF_MID, 3.0)
	if highlighted and not is_observed():
		draw_arc(Vector2.ZERO, 17.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
