extends Control
## Points toward an off-screen target (a leaking dam piece, the raccoon) so
## threats are noticeable without needing a full minimap. Hides itself once
## the target is on-screen or cleared. HUD is a CanvasLayer, so this works
## in the base-viewport pixel space directly - independent of the in-game
## Camera2D's own position/zoom, which is why those are projected manually
## instead of relying on any built-in screen-space transform.

const BASE_VIEWPORT_SIZE := Vector2(640, 360)
const EDGE_MARGIN := 22.0
## Tutorial/objective banners occupy the top strip and the resource HUD plus
## action prompts occupy the bottom. A target behind either is not meaningfully
## visible, even though it is technically inside the raw viewport.
const SAFE_RECT := Rect2(22, 54, 596, 220)
const ARROW_COLOR := Color("fff0a0")

var target: Node2D = null
var _camera: Camera2D = null

func _ready() -> void:
	hide()

func set_camera(camera: Camera2D) -> void:
	_camera = camera

func point_to(new_target: Node2D) -> void:
	target = new_target

func clear() -> void:
	target = null
	hide()

func _process(_delta: float) -> void:
	if target == null or not is_instance_valid(target) or _camera == null:
		if visible:
			hide()
		return

	var screen_center := BASE_VIEWPORT_SIZE / 2.0
	var offset := (target.global_position - _camera.global_position) * _camera.zoom
	var screen_position := screen_center + offset

	if SAFE_RECT.has_point(screen_position):
		if visible:
			hide()
		return

	position = Vector2(
		clampf(screen_position.x, SAFE_RECT.position.x, SAFE_RECT.end.x),
		clampf(screen_position.y, SAFE_RECT.position.y, SAFE_RECT.end.y)
	)
	rotation = offset.angle()
	show()
	queue_redraw()

func _draw() -> void:
	var points := PackedVector2Array([Vector2(10, 0), Vector2(-7, -7), Vector2(-7, 7)])
	draw_colored_polygon(points, ARROW_COLOR)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, Palette.OUTLINE, 1.5, true)
