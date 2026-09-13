class_name DrawUtil
extends RefCounted
## Shared drawing helpers - a soft ground shadow and a consistent outline
## treatment are what make flat hand-drawn shapes read as one cohesive
## "cutout sticker" art style instead of a pile of raw circles and rects.
##
## Every function takes `item` (the CanvasItem doing the drawing) and must
## only be called from within that item's own _draw(), since draw_* calls
## are only valid during that node's draw notification.

static func shadow(item: CanvasItem, center: Vector2, radius: Vector2) -> void:
	item.draw_set_transform(center, 0.0, Vector2.ONE)
	var points := PackedVector2Array()
	var count := 20
	for i in count:
		var angle := TAU * i / count
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	item.draw_colored_polygon(points, Palette.SHADOW)
	item.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func outlined_circle(item: CanvasItem, center: Vector2, radius: float, fill: Color, outline_width: float = 2.0) -> void:
	item.draw_circle(center, radius, fill)
	item.draw_arc(center, radius - outline_width * 0.5, 0.0, TAU, 32, Palette.OUTLINE, outline_width)

static func outlined_rect(item: CanvasItem, rect: Rect2, fill: Color, outline_width: float = 2.0) -> void:
	item.draw_rect(rect, fill)
	item.draw_rect(rect, Palette.OUTLINE, false, outline_width)

static func outlined_polygon(item: CanvasItem, points: PackedVector2Array, fill: Color, outline_width: float = 2.0) -> void:
	item.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	item.draw_polyline(closed, Palette.OUTLINE, outline_width, true)

## A circle with a smaller offset highlight blob for a glossy/rounded look.
static func shaded_circle(item: CanvasItem, center: Vector2, radius: float, fill: Color, highlight: Color, outline_width: float = 2.0) -> void:
	outlined_circle(item, center, radius, fill, outline_width)
	item.draw_circle(center + Vector2(-radius * 0.32, -radius * 0.32), radius * 0.4, highlight)
