extends Area2D
## A lightweight resident anchor. It retains the demo's procedural critter
## drawing and reveal behavior, while named Act I residents can additionally
## offer data-driven conversations through the shared interaction contract.
## Movement/routines and changing ambient lines remain issue #20 work.

enum Kind { FROG, DUCK, FISH, BUTTERFLY, RABBIT }

@export var kind: Kind = Kind.FROG
@export var required_stage: int = 1
@export var bob_height: float = 2.0
@export var bob_speed: float = 2.5
@export var resident_name: String = ""
@export var dialogue_ids: PackedStringArray = []
@export var requires_restored_pond := false

var _time := 0.0
var _base_position: Vector2
var highlighted := false

func _ready() -> void:
	add_to_group("residents")
	_base_position = position
	GameState.lodge_stage_changed.connect(_on_stage_changed)
	GameState.dam_progress_changed.connect(_on_dam_progress_changed)
	visible = _meets_reveal_condition()
	monitorable = visible

func _on_stage_changed(stage: int) -> void:
	if not requires_restored_pond and stage >= required_stage:
		reveal()

func _on_dam_progress_changed(_built: int, _total: int) -> void:
	if requires_restored_pond and GameState.is_dam_complete():
		reveal()

func _meets_reveal_condition() -> bool:
	if requires_restored_pond:
		return GameState.is_dam_complete()
	return GameState.lodge_stage >= required_stage

## Re-evaluates save-restored world state after Main has rebuilt dam slots.
func refresh_visibility() -> void:
	if _meets_reveal_condition():
		reveal()

## Shows the critter with a little pop-in, if it isn't already visible.
## Called either by lodge progress (see _on_stage_changed) or directly by a
## GardenSpot when it's built.
func reveal() -> void:
	if visible:
		monitorable = true
		return
	visible = true
	monitorable = true
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	position = _base_position + Vector2(0, sin(_time * bob_speed) * bob_height)

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func get_interaction() -> InteractionOption:
	if not visible or resident_name.is_empty():
		return null
	for dialogue_id in dialogue_ids:
		if ActOneController.can_start_dialogue(dialogue_id):
			return InteractionOption.new("Talk to %s" % resident_name, _start_dialogue.bind(dialogue_id), true)
	return null

func _start_dialogue(dialogue_id: String) -> void:
	if ActOneController.can_start_dialogue(dialogue_id):
		ActOneController.start_dialogue(dialogue_id)

func _draw() -> void:
	if highlighted and get_interaction() != null:
		draw_arc(Vector2.ZERO, 17.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
	match kind:
		Kind.FROG:
			_draw_frog()
		Kind.DUCK:
			_draw_duck()
		Kind.FISH:
			_draw_fish()
		Kind.BUTTERFLY:
			_draw_butterfly()
		Kind.RABBIT:
			_draw_rabbit()

func _draw_frog() -> void:
	DrawUtil.shadow(self, Vector2(0, 6), Vector2(7, 2))
	draw_circle(Vector2(-4, -3), 3.0, Palette.FROG_BODY)
	draw_circle(Vector2(4, -3), 3.0, Palette.FROG_BODY)
	DrawUtil.outlined_circle(self, Vector2.ZERO, 7.0, Palette.FROG_BODY, 1.5)
	draw_circle(Vector2(0, 2), 3.5, Palette.FROG_BELLY)
	draw_circle(Vector2(-4, -3), 1.2, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(4, -3), 1.2, Color(0.1, 0.1, 0.1))

func _draw_duck() -> void:
	DrawUtil.shadow(self, Vector2(0, 8), Vector2(9, 2.5))
	DrawUtil.outlined_circle(self, Vector2.ZERO, 8.0, Palette.DUCK_BODY, 1.5)
	DrawUtil.outlined_circle(self, Vector2(6, -5), 4.5, Palette.DUCK_BODY, 1.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(9, -6), Vector2(14, -5), Vector2(9, -3.5),
	]), Palette.DUCK_BILL)
	draw_circle(Vector2(6.5, -6), 0.9, Color(0.1, 0.1, 0.1))
	draw_arc(Vector2(-2, 0), 5.0, PI * 0.15, PI * 0.85, 8, Color(0.85, 0.8, 0.72), 1.2)

func _draw_fish() -> void:
	draw_circle(Vector2(0, 3), 8.0, Color(1, 1, 1, 0.15))
	var tail := PackedVector2Array([
		Vector2(-6, 0), Vector2(-13, -4.5), Vector2(-13, 4.5),
	])
	DrawUtil.outlined_polygon(self, tail, Palette.FISH_BODY, 1.2)
	DrawUtil.outlined_circle(self, Vector2.ZERO, 6.5, Palette.FISH_BODY, 1.5)
	draw_circle(Vector2(1, 2), 3.2, Palette.FISH_BELLY)
	var dorsal := PackedVector2Array([
		Vector2(-1, -6), Vector2(2, -10), Vector2(4, -6),
	])
	DrawUtil.outlined_polygon(self, dorsal, Palette.FISH_BODY, 1.0)
	draw_circle(Vector2(3.5, -1), 1.0, Color(0.1, 0.1, 0.1))

func _draw_butterfly() -> void:
	var wing := Palette.BUTTERFLY_WING
	draw_colored_polygon(PackedVector2Array([Vector2(0, -1), Vector2(-7, -6), Vector2(-4, 1)]), wing)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -1), Vector2(7, -6), Vector2(4, 1)]), wing)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(-5, 4), Vector2(-2, 6)]), wing)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(5, 4), Vector2(2, 6)]), wing)
	draw_line(Vector2(0, -4), Vector2(0, 5), Color(0.2, 0.15, 0.1), 1.2)

func _draw_rabbit() -> void:
	DrawUtil.shadow(self, Vector2(0, 7), Vector2(7, 2))
	draw_circle(Vector2(-2.2, -8), 1.8, Palette.RABBIT_FUR)
	draw_circle(Vector2(2.2, -8), 1.8, Palette.RABBIT_FUR)
	DrawUtil.outlined_circle(self, Vector2.ZERO, 6.0, Palette.RABBIT_FUR, 1.3)
	draw_circle(Vector2(-1.6, -1), 0.9, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(1.6, -1), 0.9, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(0, 1.5), 0.8, Color(0.85, 0.55, 0.55))
