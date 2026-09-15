extends Node2D
## Layered Wasatch Front foothills: pale quartzite benches, Gambel-oak scrub,
## alluvial fans, and a cottonwood/willow riparian ribbon.

func _draw() -> void:
	# Dry foothill benches enclosing the greener creek bottom.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(2600, 0), Vector2(2600, 175), Vector2(2250, 135), Vector2(1900, 190), Vector2(1510, 125), Vector2(1120, 185), Vector2(710, 120), Vector2(330, 170), Vector2(0, 125)]), Color("8f895f"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 900), Vector2(2600, 900), Vector2(2600, 735), Vector2(2240, 780), Vector2(1870, 710), Vector2(1490, 775), Vector2(1100, 720), Vector2(700, 785), Vector2(300, 715), Vector2(0, 760)]), Color("827b52"))
	# Warm exposed rock ribs characteristic of the canyon-mouth benches.
	for ridge in [Vector2(210, 95), Vector2(760, 80), Vector2(1320, 105), Vector2(2040, 82), Vector2(2420, 120)]:
		var points := PackedVector2Array([ridge + Vector2(-85, 45), ridge + Vector2(-35, -20), ridge + Vector2(20, 5), ridge + Vector2(80, 55)])
		draw_polyline(points, Color("b8a184"), 18.0, true)
		draw_polyline(points, Color("d0bb9b"), 5.0, true)
	# Scrub-oak clumps stay on the dry benches, leaving a readable riparian lane.
	for p in [Vector2(90, 100), Vector2(430, 110), Vector2(1030, 105), Vector2(1670, 115), Vector2(2320, 95), Vector2(180, 790), Vector2(560, 760), Vector2(1220, 790), Vector2(1780, 760), Vector2(2380, 790)]:
		draw_circle(p, 25, Color("59683f"))
		draw_circle(p + Vector2(22, 5), 19, Color("71804b"))
		draw_circle(p + Vector2(-18, 8), 17, Color("697847"))
