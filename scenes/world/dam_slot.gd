extends Area2D
## A marked spot along the riverbank where a dam piece can be built. Once
## built, a storm can weaken it into a leaking state (see Main's storm
## timer) that needs a repair - same interact action, same cost - before it
## goes back to just sitting there quietly.
##
## One slot in the scene is marked `is_keystone` - the gap that sits in the
## river's main channel (see main.tscn). That slot can't be built until the
## player has read the water at a nearby RiverGauge (see river_gauge.gd) -
## the dam's observation step from issue #19, so the first dam asks for more
## than five identical slots without adding any real risk: the gauge is
## free and instant, and the slot just waits, cost and all, until it's been
## read.

## Emitted whenever `leaking` starts or stops, live or restored from a save
## - Main listens to keep the storm edge-indicator pointed at a leak that
## still needs attention (or cleared once none remain).
signal leak_changed

## Set in the scene on the one slot that sits in the river's strongest
## current. See the class comment and GameState.water_read.
@export var is_keystone: bool = false

var built: bool = false
var leaking: bool = false
var highlighted: bool = false
var _piece: Node2D = null

func _ready() -> void:
	add_to_group("dam_slots")
	GameState.register_dam_slot()

func _draw() -> void:
	if built and not leaking:
		return
	if built and leaking:
		if highlighted:
			draw_arc(Vector2.ZERO, 16.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
		return
	draw_circle(Vector2.ZERO, 11.0, Color(1, 1, 1, 0.18))
	var ring_width := 3.5 if highlighted else 2.0
	var ring_color := Palette.HIGHLIGHT_RING if highlighted else Color(1, 1, 1, 0.75)
	# A dashed ring reads as a "build marker" rather than a solid object.
	var dash_count := 10
	for i in dash_count:
		var start_angle := TAU * i / dash_count
		var end_angle := start_angle + TAU / dash_count * 0.6
		draw_arc(Vector2.ZERO, 10.0, start_angle, end_angle, 4, ring_color, ring_width)

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func can_build() -> bool:
	return not built

func can_repair() -> bool:
	return built and leaking

## True once this slot is blocked on the water not having been read yet -
## only ever true for the keystone slot, and only until GameState.water_read
## flips. See the class comment.
func _needs_reading() -> bool:
	return is_keystone and not GameState.water_read

func _story_allows_building() -> bool:
	return ActOneController.get_objective_status("repair_willowbend_dam") in ["active", "completed"]

## See interaction_option.gd. can_build()/can_repair() are mutually
## exclusive by construction (a slot is either not built, built and
## leaking, or built and fine), so there's never a priority question here -
## null once a slot is built and intact, since there's nothing left to do.
func get_interaction() -> InteractionOption:
	var cost := {"wood": GameState.WOOD_PER_DAM_PIECE, "stone": GameState.STONE_PER_DAM_PIECE}
	var available := GameState.can_afford_dam_piece()
	var reason := "" if available else "Not enough wood or stone"
	if can_repair():
		return InteractionOption.new("Repair Dam Piece", repair, available, reason, cost)
	if can_build():
		if not _story_allows_building():
			return InteractionOption.new("Build Dam Piece", build, false, "Talk to Moss first", cost)
		if _needs_reading():
			return InteractionOption.new("Build Dam Piece", build, false, "Read the water first", cost)
		return InteractionOption.new("Build Dam Piece", build, available, reason, cost)
	return null

## The affordability check used to live only in Player (the group-based
## dispatch that get_interaction() replaces) - now build()/repair() guard
## their own cost the same way chop()/mine() always have.
func build() -> void:
	if not can_build() or not _story_allows_building() or _needs_reading() or not GameState.can_afford_dam_piece():
		return
	GameState.spend_resources_on_dam_piece()
	Sfx.play_build()
	Fx.burst(global_position, Color(0.6, 0.6, 0.65), 12)
	_place_piece()

## Called by Main's storm timer on a random already-built, non-leaking slot.
func start_leaking() -> void:
	if not built or leaking:
		return
	leaking = true
	if _piece:
		_piece.set_leaking(true)
	queue_redraw()
	leak_changed.emit()

func repair() -> void:
	if not can_repair() or not GameState.can_afford_dam_piece():
		return
	GameState.spend_resources_on_repair()
	leaking = false
	if _piece:
		_piece.set_leaking(false)
	Sfx.play_build()
	Fx.burst(global_position, Color(0.6, 0.6, 0.65), 10)
	queue_redraw()
	leak_changed.emit()

## Restores a built slot from a save file - same end state as build(), but
## silent (no sound/particles) since nothing just happened live.
func set_built_silently(value: bool) -> void:
	if not value or built:
		return
	_place_piece()

## Restores a leaking slot from a save file - silent, same reasoning as
## set_built_silently().
func set_leaking_silently(value: bool) -> void:
	if not value or not built or leaking:
		return
	leaking = true
	if _piece:
		_piece.set_leaking(true)
	queue_redraw()
	leak_changed.emit()

func _place_piece() -> void:
	built = true
	set_highlighted(false)
	queue_redraw()
	var piece := preload("res://scenes/world/dam_piece.tscn").instantiate()
	_piece = piece
	add_child(piece)
