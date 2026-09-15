class_name EddyPassage
extends Area2D
## A small habitat build that turns Eddy's advice into a physical action.

const WOOD_COST := 2
const STONE_COST := 1
var highlighted := false

func _ready() -> void:
	add_to_group("habitat_projects")
	_restore_visibility()
	ActOneController.objective_started.connect(_on_objective_changed.unbind(1))
	ActOneController.objective_completed.connect(_on_objective_changed.unbind(1))
	ActOneController.flag_changed.connect(_on_flag_changed)

func restore_from_story_state() -> void:
	_restore_visibility()

func _on_flag_changed(flag_name: String, _value: bool) -> void:
	if flag_name == "eddy_passage_restored":
		_restore_visibility()

func _restore_visibility() -> void:
	visible = ActOneController.get_objective_status("restore_eddy_passage") == "active" \
		or ActOneController.get_flag("eddy_passage_restored")
	monitorable = visible and not ActOneController.get_flag("eddy_passage_restored")
	queue_redraw()

func _on_objective_changed() -> void:
	_restore_visibility()

func set_highlighted(value: bool) -> void:
	highlighted = value
	queue_redraw()

func get_interaction() -> InteractionOption:
	if not visible or ActOneController.get_flag("eddy_passage_restored"):
		return null
	var available := GameState.can_afford(WOOD_COST, STONE_COST)
	return InteractionOption.new("Open Eddy's Passage", restore, available, "" if available else "Need 2 wood and 1 stone", {"wood": WOOD_COST, "stone": STONE_COST})

func restore() -> void:
	if ActOneController.get_flag("eddy_passage_restored") or not GameState.can_afford(WOOD_COST, STONE_COST):
		return
	GameState.spend(WOOD_COST, STONE_COST)
	ActOneController.set_flag("eddy_passage_restored")
	ActOneController.complete_objective("restore_eddy_passage")
	ActOneController.start_objective("build_lodge_foundation")
	Sfx.play_build()
	Fx.burst(global_position, Palette.WATER_SHALLOW, 16)
	monitorable = false
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	DrawUtil.shadow(self, Vector2(0, 9), Vector2(18, 4))
	if ActOneController.get_flag("eddy_passage_restored"):
		# A porous, stone-braced side channel rather than a solid barrier.
		draw_arc(Vector2.ZERO, 20, 0.15, PI - 0.15, 20, Palette.WATER_SHALLOW, 5.0)
		draw_circle(Vector2(-15, 5), 6, Palette.STONE_MID)
		draw_circle(Vector2(15, 5), 6, Palette.STONE_LIGHT)
	else:
		draw_line(Vector2(-17, 6), Vector2(16, -3), Palette.WOOD_DARK, 5.0)
		draw_line(Vector2(-12, -5), Vector2(14, 7), Palette.WOOD_MID, 4.0)
		if highlighted:
			draw_arc(Vector2.ZERO, 25, 0, TAU, 28, Palette.HIGHLIGHT_RING, 2.5)
