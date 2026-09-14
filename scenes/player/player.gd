extends CharacterBody2D
## The player-controlled beaver: movement, chopping trees, and building dam
## pieces via a single context-sensitive interact action.
##
## What "interact" actually does is never decided here - see
## interaction_option.gd: every nearby interactable exposes a
## get_interaction() contract (label, cost, whether it'll succeed, why not
## if it won't), and this script just resolves the nearest one, shows it,
## and presses it. Main wires interaction_option_changed/interaction_failed
## to HUD so the action prompt and any failure toast stay decoupled from
## Player itself.

## The live "what would pressing interact do right now" prompt - null when
## nothing's nearby. HUD.set_action_prompt() renders this.
signal interaction_option_changed(option: InteractionOption)
## Fired when interact was pressed but the resolved action couldn't
## succeed, carrying the same reason the prompt was already showing.
signal interaction_failed(reason: String)

const SPEED := 140.0
const WORLD_BOUNDS := Rect2(20, 20, 1360, 760)
const BOB_SPEED := 10.0
const BOB_HEIGHT := 2.0
const FOOTSTEP_INTERVAL := 0.35
const WATER_SPEED_MULTIPLIER := 0.5
const TIRED_SPEED_MULTIPLIER := 0.5
const AMBIENT_DRAIN_INTERVAL := 10.0
const AMBIENT_DRAIN_AMOUNT := 1.0

@onready var interact_area: Area2D = $InteractionArea
@onready var water_detector: Area2D = $WaterDetector
@onready var visual: Node2D = $Visual

var _bob_time := 0.0
var _footstep_time := 0.0
var _ambient_drain_time := 0.0
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

	var speed_multiplier := WATER_SPEED_MULTIPLIER if water_detector.get_overlapping_areas().size() > 0 else 1.0
	if GameState.is_tired():
		speed_multiplier *= TIRED_SPEED_MULTIPLIER
	velocity = input_vector * SPEED * speed_multiplier
	move_and_slide()

	global_position.x = clamp(global_position.x, WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.x)
	global_position.y = clamp(global_position.y, WORLD_BOUNDS.position.y, WORLD_BOUNDS.end.y)

	if absf(input_vector.x) > 0.01:
		visual.scale.x = 1.0 if input_vector.x > 0 else -1.0

	if input_vector.length() > 0.01:
		_bob_time += delta * BOB_SPEED
		visual.position.y = sin(_bob_time) * BOB_HEIGHT
		_footstep_time += delta
		if _footstep_time >= FOOTSTEP_INTERVAL:
			_footstep_time = 0.0
			Sfx.play_footstep()
	else:
		visual.position.y = lerp(visual.position.y, 0.0, 0.2)
		_footstep_time = FOOTSTEP_INTERVAL

	# No pond, no upkeep: energy only starts draining on its own once the dam
	# (and the pond behind it) is finished, so a new player can focus on
	# building without also having to watch the meter.
	if GameState.is_dam_complete() and not input_vector.is_zero_approx():
		_ambient_drain_time += delta
		if _ambient_drain_time >= AMBIENT_DRAIN_INTERVAL:
			_ambient_drain_time = 0.0
			GameState.spend_energy(AMBIENT_DRAIN_AMOUNT)

	_update_highlight()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

## Trees and rocks register their InteractArea (a child) in a "*_areas"
## group, so the overlap result is the area, not the interactable itself;
## dam slots, the Lodge, garden spots, raccoons, berry bushes, pond plants,
## and river gauges ARE the Area2D, so no indirection is needed. This
## resolves any of them to the node that actually has
## get_interaction()/set_highlighted().
func _resolve_target(area: Area2D) -> Node:
	if area.is_in_group("tree_areas") or area.is_in_group("rock_areas"):
		return area.get_parent()
	if area.is_in_group("dam_slots") or area.is_in_group("lodge") or area.is_in_group("garden_spots") or area.is_in_group("raccoons") or area.is_in_group("berry_bushes") or area.is_in_group("pond_plants") or area.is_in_group("river_gauges"):
		return area
	return null

func _try_interact() -> void:
	var target := _nearest_interaction_target()
	if target == null:
		return
	var option: InteractionOption = target.get_interaction()
	if option == null:
		return
	# Always safe to call - every get_interaction() implementation predicts
	# `available` from the same checks its action method re-runs itself
	# (see e.g. Tree.chop()/DamSlot.build()), so this can never double-spend
	# or act on stale state even if something changed between the two calls.
	option.perform.call()
	if not option.available and not option.reason.is_empty():
		interaction_failed.emit(option.reason)

func _nearest_interaction_target() -> Node:
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
	return nearest

func _update_highlight() -> void:
	var nearest := _nearest_interaction_target()
	if nearest != _highlighted_target:
		if _highlighted_target and is_instance_valid(_highlighted_target):
			_highlighted_target.set_highlighted(false)
		if nearest:
			nearest.set_highlighted(true)
		_highlighted_target = nearest
	# Recomputed every frame (not just on target change) since a target's
	# own affordability can change while the player just stands there -
	# e.g. gathering enough wood/stone to finally afford the dam piece
	# they're already next to.
	var option: InteractionOption = nearest.get_interaction() if nearest else null
	interaction_option_changed.emit(option)
