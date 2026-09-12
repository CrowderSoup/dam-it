extends CharacterBody2D
## The player-controlled beaver: movement, chopping trees, and building dam
## pieces via a single context-sensitive interact action.

const SPEED := 140.0
const WORLD_BOUNDS := Rect2(20, 20, 1360, 760)

const BODY_COLOR := Color(0.42, 0.28, 0.15)
const BELLY_COLOR := Color(0.62, 0.46, 0.28)
const TAIL_COLOR := Color(0.2, 0.12, 0.08)

@onready var interact_area: Area2D = $InteractionArea

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1

	velocity = input_vector.normalized() * SPEED
	move_and_slide()

	global_position.x = clamp(global_position.x, WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.x)
	global_position.y = clamp(global_position.y, WORLD_BOUNDS.position.y, WORLD_BOUNDS.end.y)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	for area in interact_area.get_overlapping_areas():
		if area.is_in_group("trees"):
			area.get_parent().chop()
			return
		if area.is_in_group("dam_slots"):
			if area.can_build() and GameState.can_afford_dam_piece():
				GameState.spend_wood_on_dam_piece()
				area.build()
			return

func _draw() -> void:
	draw_rect(Rect2(-6, 4, 12, 10), TAIL_COLOR)
	draw_circle(Vector2.ZERO, 12, BODY_COLOR)
	draw_circle(Vector2(0, 3), 7, BELLY_COLOR)
	draw_circle(Vector2(-4, -4), 2, Color.BLACK)
	draw_circle(Vector2(4, -4), 2, Color.BLACK)
