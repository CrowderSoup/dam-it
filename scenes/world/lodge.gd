extends Area2D
## The Lodge build site. Hidden entirely until the dam is finished, then
## pops into view (see reveal()) south of the new pond; interact repeatedly
## (with enough wood + stone) to advance it through foundation -> walls ->
## roof.

var highlighted: bool = false

func _ready() -> void:
	add_to_group("lodge")
	monitorable = false
	hide()
	GameState.dam_completed.connect(reveal)
	GameState.lodge_stage_changed.connect(_on_stage_changed)

## Shows the Lodge with a little pop-in, if it isn't already visible.
## Called either by the dam_completed signal or directly on a save load
## where the dam was already complete.
func reveal() -> void:
	if visible:
		return
	monitorable = true
	show()
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _on_stage_changed(_stage: int) -> void:
	queue_redraw()

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func can_advance() -> bool:
	return visible and GameState.lodge_stage < GameState.LODGE_MAX_STAGE

func _story_allows_advance() -> bool:
	if GameState.lodge_stage == 0:
		return ActOneController.get_objective_status("build_lodge_foundation") in ["active", "completed"]
	return ActOneController.get_objective_status("finish_willowbend_lodge") in ["active", "completed"]

## See interaction_option.gd. Mirrors the old Player._try_interact()
## priority while making the stage-one platform's first practical payoff
## reachable: a tired beaver rests before advancing again; upgrading the
## reinforced pouch is the last resort) and then adds informative, non-priority
## fallbacks for the "nothing succeeded" cases the old code left silent:
## an unaffordable advance/upgrade, or a fully-built, fully-rested,
## fully-upgraded Lodge with nothing left to offer right now.
func get_interaction() -> InteractionOption:
	if not visible:
		return null
	if can_rest() and (GameState.is_tired() or not can_advance()):
		return InteractionOption.new("Rest", rest, true)
	if can_advance():
		var stage_cost: Dictionary = GameState.LODGE_STAGE_COSTS[GameState.lodge_stage]
		if not _story_allows_advance():
			return InteractionOption.new("Advance Lodge", advance, false, "Finish your current task first", stage_cost)
		if GameState.can_afford_lodge_stage():
			return InteractionOption.new("Advance Lodge", advance, true, "", stage_cost)
	if can_upgrade_pouch():
		return InteractionOption.new("Reinforce Pouch", upgrade_pouch, true, "", GameState.POUCH_UPGRADE_COST)
	if can_advance():
		return InteractionOption.new("Advance Lodge", advance, false, "Not enough wood or stone", GameState.LODGE_STAGE_COSTS[GameState.lodge_stage])
	if GameState.pouch_tier < GameState.POUCH_MAX_TIER:
		return InteractionOption.new("Reinforce Pouch", upgrade_pouch, false, "Not enough wood or stone", GameState.POUCH_UPGRADE_COST)
	return InteractionOption.new("Rest", rest, false, "Not tired right now")

## The affordability check used to live only in Player (the group-based
## dispatch that get_interaction() replaces) - now advance() guards its own
## cost the same way chop()/mine() always have.
func advance() -> void:
	if not can_advance() or not _story_allows_advance() or not GameState.can_afford_lodge_stage():
		return
	GameState.advance_lodge_stage()
	Sfx.play_build()
	Fx.burst(global_position, Color(0.7, 0.55, 0.35), 14)
	queue_redraw()

## The stage-one dry platform is already a usable place to rest. It keeps the
## cozy full refill; later Lodge stages add other payoffs independently.
func can_rest() -> bool:
	return visible and GameState.lodge_stage >= 1 and GameState.energy < GameState.ENERGY_MAX

func rest() -> void:
	if not can_rest():
		return
	GameState.restore_energy_fully()
	Sfx.play_rest()
	Fx.burst(global_position, Color(0.95, 0.9, 0.6), 12)

## The stage-two dry-storage payoff alongside rest() - only reachable once
## resting isn't urgent, so a single E press never has to choose between the
## two. Widens the beaver's carry pouch once; see
## GameState.purchase_pouch_upgrade().
func can_upgrade_pouch() -> bool:
	return visible and GameState.lodge_stage >= 2 and GameState.can_afford_pouch_upgrade()

func upgrade_pouch() -> void:
	if not can_upgrade_pouch():
		return
	GameState.purchase_pouch_upgrade()
	Sfx.play_build()
	Fx.burst(global_position, Color(0.6, 0.8, 0.5), 12)

func _draw() -> void:
	DrawUtil.shadow(self, Vector2(0, 15), Vector2(24, 5))
	if highlighted and (can_advance() or can_rest() or can_upgrade_pouch()):
		draw_arc(Vector2(0, -10), 34, 0, TAU, 32, Palette.HIGHLIGHT_RING, 2.5)

	var stage := GameState.lodge_stage
	if stage >= 1:
		_rounded_rect(Rect2(-20, -4, 40, 18), Palette.WOOD_DARK, 3.0)
	else:
		var marker_points := PackedVector2Array([
			Vector2(-20, -4), Vector2(20, -4), Vector2(20, 14), Vector2(-20, 14),
		])
		var closed := marker_points.duplicate()
		closed.append(marker_points[0])
		draw_polyline(closed, Color(1, 1, 1, 0.6), 2.0, true)

	if stage >= 2:
		_rounded_rect(Rect2(-18, -24, 36, 22), Palette.WOOD_MID, 3.0)
		_rounded_rect(Rect2(-4, -9, 8, 5), Palette.DOOR, 1.5)
		_rounded_rect(Rect2(8, -19, 7, 7), Palette.WINDOW_GLOW, 1.5)
		draw_line(Vector2(11.5, -19), Vector2(11.5, -12), Palette.OUTLINE, 1.0)
		draw_line(Vector2(8, -15.5), Vector2(15, -15.5), Palette.OUTLINE, 1.0)

	if stage >= 3:
		var roof_points := PackedVector2Array([
			Vector2(-24, -24), Vector2(24, -24), Vector2(0, -42),
		])
		DrawUtil.outlined_polygon(self, roof_points, Palette.ROOF, 2.0)
		draw_line(Vector2(-24, -24), Vector2(24, -24), Palette.ROOF_DARK, 2.0)
		_rounded_rect(Rect2(11, -38, 6, 11), Palette.STONE_MID, 1.5)
		draw_circle(Vector2(14, -42), 3.0, Color(1, 1, 1, 0.35))
		draw_circle(Vector2(16, -47), 4.0, Color(1, 1, 1, 0.28))
		draw_circle(Vector2(13, -51), 5.0, Color(1, 1, 1, 0.2))

func _rounded_rect(rect: Rect2, color: Color, border_width: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	if border_width > 0.0:
		style.border_color = Palette.OUTLINE
		style.set_border_width_all(border_width)
	style.draw(get_canvas_item(), rect)
