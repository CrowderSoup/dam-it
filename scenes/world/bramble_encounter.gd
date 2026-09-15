class_name BrambleEncounter
extends Node2D
## Save-safe choreography for Bramble's first Willowbend appearance. Issue #21
## owns when each public phase begins; this component owns the fixed route,
## idempotent material loss, stable restoration anchors, and completion flag.

signal approach_completed
signal material_committed(wood_taken: int, stone_taken: int)
signal encounter_completed

enum Phase { IDLE, APPROACHING, READY_TO_TAKE, READY_TO_FLEE, FLEEING, COMPLETE }

const TAKE_WOOD := 3
const TAKE_STONE := 1

@export var raccoon_path: NodePath
@export var approach_duration := 1.6
@export var flee_leg_duration := 1.0

@onready var bramble: Raccoon = get_node(raccoon_path)
@onready var entry_anchor: Marker2D = $EntryAnchor
@onready var material_anchor: Marker2D = $MaterialAnchor
@onready var flee_anchor: Marker2D = $FleeAnchor
@onready var exit_anchor: Marker2D = $ExitAnchor

var _phase := Phase.IDLE
var _movement: Tween

func _ready() -> void:
	restore_from_story_state()

## Starts the live authored approach once. A restored already-started encounter
## instead snaps to its next safe discrete boundary and reports false.
func start_encounter() -> bool:
	if ActOneController.get_flag("bramble_intro_complete"):
		restore_from_story_state()
		return false
	if ActOneController.get_flag("bramble_intro_started"):
		restore_from_story_state()
		return false
	ActOneController.set_flag("bramble_intro_started")
	_show_at(entry_anchor.global_position)
	_phase = Phase.APPROACHING
	_kill_movement()
	_movement = create_tween()
	_movement.tween_property(bramble, "global_position", material_anchor.global_position, approach_duration)
	_movement.tween_callback(_finish_approach)
	queue_redraw()
	return true

func _finish_approach() -> void:
	_movement = null
	_phase = Phase.READY_TO_TAKE
	approach_completed.emit()

## Commits the one recoverable loss. The durable flag is written first, so a
## save or re-entrant callback can never charge twice. Active resource goals
## retain enough inventory to meet their target.
func commit_material_take() -> Dictionary:
	if not ActOneController.get_flag("bramble_intro_started") \
			or ActOneController.get_flag("bramble_material_taken") \
			or ActOneController.get_flag("bramble_intro_complete"):
		return {"wood": 0, "stone": 0}
	ActOneController.set_flag("bramble_material_taken")
	var wood_taken := mini(TAKE_WOOD, _unreserved_amount("wood", GameState.wood))
	var stone_taken := mini(TAKE_STONE, _unreserved_amount("stone", GameState.stone))
	GameState.remove_wood(wood_taken)
	GameState.remove_stone(stone_taken)
	Sfx.play_steal()
	Fx.burst(material_anchor.global_position, Color(0.35, 0.28, 0.22), 10)
	_phase = Phase.READY_TO_FLEE
	queue_redraw()
	material_committed.emit(wood_taken, stone_taken)
	return {"wood": wood_taken, "stone": stone_taken}

func _unreserved_amount(resource_name: String, carried: int) -> int:
	var current_id := ActOneController.get_current_objective_id()
	if current_id.is_empty() or ActOneController.get_objective_status(current_id) != "active":
		return carried
	var objective := ActOneController.get_objective(current_id)
	if objective == null \
			or objective.completion_type != ObjectiveDefinition.CompletionType.RESOURCE_AT_LEAST \
			or objective.resource != resource_name:
		return carried
	return maxi(0, carried - objective.target_amount)

## Follows the same two-leg upstream escape every time. Completion is recorded
## only after Bramble reaches the stable off-map anchor.
func begin_flee() -> bool:
	if not ActOneController.get_flag("bramble_material_taken") \
			or ActOneController.get_flag("bramble_intro_complete") \
			or _phase == Phase.FLEEING:
		return false
	_show_at(material_anchor.global_position)
	_phase = Phase.FLEEING
	_kill_movement()
	_movement = create_tween()
	_movement.tween_property(bramble, "global_position", flee_anchor.global_position, flee_leg_duration)
	_movement.tween_property(bramble, "global_position", exit_anchor.global_position, flee_leg_duration)
	_movement.tween_callback(_finish_flee)
	return true

func _finish_flee() -> void:
	_movement = null
	bramble.hide_authored()
	_phase = Phase.COMPLETE
	ActOneController.set_flag("bramble_intro_complete")
	encounter_completed.emit()

## Restores only stable authored boundaries—never tween progress. The ending
## controller can inspect get_phase() and resume the appropriate next action.
func restore_from_story_state() -> void:
	_kill_movement()
	if ActOneController.get_flag("bramble_intro_complete"):
		bramble.hide_authored()
		_phase = Phase.COMPLETE
	elif ActOneController.get_flag("bramble_material_taken"):
		_show_at(material_anchor.global_position)
		_phase = Phase.READY_TO_FLEE
	elif ActOneController.get_flag("bramble_intro_started"):
		_show_at(material_anchor.global_position)
		_phase = Phase.READY_TO_TAKE
	else:
		bramble.hide_authored()
		_phase = Phase.IDLE
	queue_redraw()

func get_phase() -> Phase:
	return _phase

func _show_at(at: Vector2) -> void:
	bramble.show_authored_at(at)

func _kill_movement() -> void:
	if _movement != null and _movement.is_valid():
		_movement.kill()
	_movement = null

func _draw() -> void:
	# A small visible bundle plus charred debris grounds the loss in Bramble's
	# shelter-building need. It disappears once the committed take occurs.
	if ActOneController.get_flag("bramble_intro_started") \
			and not ActOneController.get_flag("bramble_material_taken"):
		var center := to_local(material_anchor.global_position)
		draw_line(center + Vector2(-12, 5), center + Vector2(12, -5), Color(0.18, 0.14, 0.12), 5.0)
		draw_line(center + Vector2(-10, -5), center + Vector2(11, 6), Palette.WOOD_DARK, 5.0)
		draw_circle(center + Vector2(0, -7), 3.0, Palette.STONE_DARK)
