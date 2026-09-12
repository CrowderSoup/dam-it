extends CharacterBody2D
## The player-controlled beaver: movement, chopping trees, and building dam
## pieces via a single context-sensitive interact action.

const SPEED := 140.0
const WORLD_BOUNDS := Rect2(20, 20, 1360, 760)
const BOB_SPEED := 10.0
const BOB_HEIGHT := 2.0

@onready var interact_area: Area2D = $InteractionArea
@onready var visual: Node2D = $Visual

var _bob_time := 0.0
var _highlighted_target: Node = null

func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	input_vector = input_vector.normalized()

	velocity = input_vector * SPEED
	move_and_slide()

	global_position.x = clamp(global_position.x, WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.x)
	global_position.y = clamp(global_position.y, WORLD_BOUNDS.position.y, WORLD_BOUNDS.end.y)

	if absf(input_vector.x) > 0.01:
		visual.scale.x = 1.0 if input_vector.x > 0 else -1.0

	if input_vector.length() > 0.01:
		_bob_time += delta * BOB_SPEED
		visual.position.y = sin(_bob_time) * BOB_HEIGHT
	else:
		visual.position.y = lerp(visual.position.y, 0.0, 0.2)

	_update_highlight()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

## Trees register their InteractArea (a child) in the "trees" group, so the
## overlap result is the area, not the interactable itself; dam slots ARE
## the Area2D, so no indirection is needed. This resolves either case to the
## node that actually has chop()/build()/set_highlighted().
func _resolve_target(area: Area2D) -> Node:
	if area.is_in_group("tree_areas"):
		return area.get_parent()
	if area.is_in_group("dam_slots"):
		return area
	return null

func _try_interact() -> void:
	for area in interact_area.get_overlapping_areas():
		var target := _resolve_target(area)
		if target == null:
			continue
		if target.is_in_group("trees"):
			target.chop()
			return
		if target.is_in_group("dam_slots"):
			if target.can_build() and GameState.can_afford_dam_piece():
				GameState.spend_wood_on_dam_piece()
				target.build()
			return

func _update_highlight() -> void:
	var nearest: Node = null
	var nearest_dist := INF
	for area in interact_area.get_overlapping_areas():
		var target := _resolve_target(area)
		if target == null:
			continue
		var dist := global_position.distance_squared_to(target.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = target
	if nearest == _highlighted_target:
		return
	if _highlighted_target and is_instance_valid(_highlighted_target):
		_highlighted_target.set_highlighted(false)
	if nearest:
		nearest.set_highlighted(true)
	_highlighted_target = nearest
