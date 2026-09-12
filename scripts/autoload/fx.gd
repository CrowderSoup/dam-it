extends Node
## Spawns small one-shot particle bursts (wood chips, dust) for feedback.
## Autoloaded as "Fx". No texture assets needed — CPUParticles2D renders
## flat-colored squares when given no texture.

func burst(global_pos: Vector2, color: Color, amount: int = 10) -> void:
	var particles := CPUParticles2D.new()
	particles.global_position = global_pos
	particles.z_index = 10
	particles.amount = amount
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 60.0
	particles.gravity = Vector2(0, 300)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 130.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 4.5
	particles.color = color

	get_tree().current_scene.add_child(particles)
	particles.emitting = true

	await get_tree().create_timer(particles.lifetime + 0.2).timeout
	if is_instance_valid(particles):
		particles.queue_free()
