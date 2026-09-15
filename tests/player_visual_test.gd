extends Node
## Deterministic checks for the procedural four-direction player walk cycle.
## Run with:
##   godot --headless --path . tests/player_visual_test.tscn

const PlayerScene := preload("res://scenes/player/player.tscn")

func _ready() -> void:
	var player: CharacterBody2D = PlayerScene.instantiate()
	add_child(player)
	player.set_physics_process(false)
	var visual = player.get_node("Visual")

	var cases := [
		["move_down", visual.Facing.DOWN],
		["move_left", visual.Facing.LEFT],
		["move_right", visual.Facing.RIGHT],
		["move_up", visual.Facing.UP],
	]
	for test_case in cases:
		Input.action_press(test_case[0])
		player._physics_process(0.1)
		Input.action_release(test_case[0])
		assert(visual.moving, "%s should put the visual in its moving pose" % test_case[0])
		assert(visual.facing == test_case[1], "%s should select the expected cardinal pose" % test_case[0])
		assert(visual.scale == Vector2.ONE, "directional drawing must not mirror the player node")
		player._physics_process(0.0)
		assert(not visual.moving, "releasing movement should restore the idle pose")
	print("OK: Player forwards all four movement directions to distinct visual poses")

	visual.set_movement(Vector2.RIGHT, PI / (2.0 * visual.WALK_CYCLE_SPEED))
	assert(is_equal_approx(visual.get_stride_offset(), visual.STRIDE_DISTANCE), "quarter-cycle should put the feet at maximum opposing stride")
	assert(visual.get_body_lift() < 0.0, "the body should lift while the feet stride")
	assert(visual.get_tail_sway() > 0.0, "the tail should animate independently during a stride")
	visual.set_movement(Vector2.ZERO, 0.0)
	assert(visual.get_stride_offset() == 0.0 and visual.get_body_lift() == 0.0 and visual.get_tail_sway() == 0.0, "idle should return all walk layers to neutral")
	print("OK: feet, body, and tail expose a deterministic layered walk cycle")

	visual.set_movement(Vector2(0.25, -1.0), 0.1)
	assert(visual.facing == visual.Facing.UP, "vertical-dominant diagonal movement should use the up pose")
	visual.set_movement(Vector2(-1.0, 0.25), 0.1)
	assert(visual.facing == visual.Facing.LEFT, "horizontal-dominant diagonal movement should use the left pose")
	print("OK: diagonal movement resolves to a stable dominant-axis pose")

	print("ALL PLAYER VISUAL TESTS PASSED")
	get_tree().quit()
