class_name Resident
extends Area2D
## Interactive named story actor composed with a lightweight Critter visual.
## Availability and routine selection derive entirely from existing world and
## story state; waypoint position/phase deliberately need no save payload.

enum Availability { ALWAYS, DAM_COMPLETE, OBJECTIVE_REACHED }

@export var resident_id: String = ""
@export var speaker_id: String = ""
@export var resident_name: String = ""
@export var availability: Availability = Availability.ALWAYS
@export var availability_objective_id: String = ""
@export var dialogue_ids: PackedStringArray = []
@export var opening_points: PackedVector2Array = []
@export var restored_points: PackedVector2Array = []
@export var stage_one_points: PackedVector2Array = []
@export var settled_objective_id: String = ""
@export var settled_points: PackedVector2Array = []
@export var post_chapter_points: PackedVector2Array = []
@export var move_speed := 24.0
@export var pause_seconds := 1.4

var highlighted := false
var _route_id := "opening"
var _route_points: PackedVector2Array = []
var _waypoint_index := 0
var _pause_remaining := 0.0

func _ready() -> void:
	assert(StoryIdentifiers.is_valid(resident_id), "Resident has invalid resident_id '%s'" % resident_id)
	assert(StoryIdentifiers.is_known_speaker(speaker_id), "Resident '%s' has unknown speaker_id '%s'" % [resident_id, speaker_id])
	assert(not resident_name.is_empty(), "Resident '%s' needs a display name" % resident_id)
	add_to_group("residents")
	GameState.dam_progress_changed.connect(_on_world_state_changed.unbind(2))
	GameState.lodge_stage_changed.connect(_on_world_state_changed.unbind(1))
	ActOneController.flag_changed.connect(_on_world_state_changed.unbind(2))
	ActOneController.objective_started.connect(_on_world_state_changed.unbind(1))
	ActOneController.objective_completed.connect(_on_world_state_changed.unbind(1))
	restore_from_story_state()

## Save restoration snaps to a deterministic authored point. Live state
## transitions switch destinations without replaying an arrival or pop-in.
func restore_from_story_state() -> void:
	_apply_story_state(true)

func _on_world_state_changed() -> void:
	_apply_story_state(false)

func _apply_story_state(snap_to_route: bool) -> void:
	var was_available := visible and monitorable
	var available := _is_available_from_story()
	visible = available
	monitorable = available
	set_process(available)
	if not available:
		return

	var selected := _select_route()
	var next_route_id: String = selected[0]
	var next_points: PackedVector2Array = selected[1]
	var route_changed := next_route_id != _route_id or next_points != _route_points
	_route_id = next_route_id
	_route_points = next_points
	if _route_points.is_empty():
		_route_points = PackedVector2Array([global_position])
	if snap_to_route or not was_available:
		_waypoint_index = 1 if _route_points.size() > 1 else 0
		global_position = _route_points[0]
		_pause_remaining = pause_seconds
	elif route_changed:
		_waypoint_index = _nearest_waypoint_index()
		_pause_remaining = 0.0

func _is_available_from_story() -> bool:
	match availability:
		Availability.ALWAYS:
			return true
		Availability.DAM_COMPLETE:
			return GameState.is_dam_complete()
		Availability.OBJECTIVE_REACHED:
			return not availability_objective_id.is_empty() \
				and ActOneController.get_objective_status(availability_objective_id) in ["active", "completed"]
	return false

func _select_route() -> Array:
	if ActOneController.get_flag("act_one_complete") and not post_chapter_points.is_empty():
		return ["post_chapter", post_chapter_points]
	if not settled_objective_id.is_empty() \
			and ActOneController.get_objective_status(settled_objective_id) == "completed" \
			and not settled_points.is_empty():
		return ["settled", settled_points]
	if GameState.lodge_stage >= 1 and not stage_one_points.is_empty():
		return ["stage_one", stage_one_points]
	if GameState.is_dam_complete() and not restored_points.is_empty():
		return ["restored", restored_points]
	return ["opening", opening_points]

func _nearest_waypoint_index() -> int:
	var nearest := 0
	var nearest_distance := INF
	for index in _route_points.size():
		var distance := global_position.distance_squared_to(_route_points[index])
		if distance < nearest_distance:
			nearest = index
			nearest_distance = distance
	return nearest

func _process(delta: float) -> void:
	if _route_points.size() < 2:
		return
	if _pause_remaining > 0.0:
		_pause_remaining -= delta
		return
	var target := _route_points[_waypoint_index]
	global_position = global_position.move_toward(target, move_speed * delta)
	if global_position.is_equal_approx(target):
		_waypoint_index = (_waypoint_index + 1) % _route_points.size()
		_pause_remaining = pause_seconds

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func get_interaction() -> InteractionOption:
	if not visible:
		return null
	for dialogue_id in dialogue_ids:
		if ActOneController.can_start_dialogue(dialogue_id):
			return InteractionOption.new("Talk to %s" % resident_name, _start_dialogue.bind(dialogue_id), true)
	return null

func _start_dialogue(dialogue_id: String) -> void:
	if ActOneController.can_start_dialogue(dialogue_id):
		ActOneController.start_dialogue(dialogue_id)

func get_active_route_id() -> String:
	return _route_id

func get_route_points() -> PackedVector2Array:
	return _route_points.duplicate()

func _draw() -> void:
	if highlighted and get_interaction() != null:
		draw_arc(Vector2.ZERO, 17.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
