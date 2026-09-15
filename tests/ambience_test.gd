extends Node
## Deterministic state-contract checks for procedural music and ambience.
## Run with:
##   godot --headless --path . tests/ambience_test.tscn

const TitleScreenScene := preload("res://scenes/ui/title_screen.tscn")

func _ready() -> void:
	GameState.reset()
	ActOneController.reset()
	Ambience.set_dialogue_ducked(false, true)
	var title_screen := TitleScreenScene.instantiate()
	add_child(title_screen)
	assert(Ambience.get_state() == Ambience.State.TITLE)
	var title_starts := Ambience.get_loop_start_count()
	Ambience.set_state(Ambience.State.TITLE)
	assert(Ambience.get_loop_start_count() == title_starts, "re-entering title setup in the same visit must be idempotent")
	title_screen.free()
	print("OK: the title scene selects its stable ambience state")

	var starts_before := Ambience.get_loop_start_count()
	assert(Ambience.set_state(Ambience.State.DRY_WILLOWBEND, true))
	assert(Ambience.get_loop_start_count() == starts_before + 1)
	assert(not Ambience.set_state(Ambience.State.DRY_WILLOWBEND))
	assert(Ambience.get_loop_start_count() == starts_before + 1, "same-state calls must not restart a loop")
	print("OK: set_state() is idempotent and does not restart the active loop")

	var starts_before_dialogue := Ambience.get_loop_start_count()
	ActOneController.dialogue_started.emit("test_conversation")
	assert(Ambience.is_dialogue_ducked())
	assert(Ambience.get_target_volume_db() == Ambience.DIALOGUE_DB)
	assert(Ambience.get_loop_start_count() == starts_before_dialogue, "ducking must preserve loop playback")
	ActOneController.dialogue_ended.emit("test_conversation")
	assert(not Ambience.is_dialogue_ducked())
	assert(Ambience.get_target_volume_db() == Ambience.NORMAL_DB)
	assert(Ambience.get_loop_start_count() == starts_before_dialogue, "restoring volume must not restart the loop")
	print("OK: dialogue signals duck and restore the current loop without restarting it")

	var stings_before := Ambience.get_transformation_sting_count()
	GameState.dam_completed.emit()
	assert(Ambience.get_state() == Ambience.State.RESTORED_POND)
	assert(Ambience.get_transformation_sting_count() == stings_before + 1)
	GameState.dam_completed.emit()
	assert(Ambience.get_transformation_sting_count() == stings_before + 1, "a repeated completion signal must not replay the sting")
	print("OK: the live dry-to-restored transition plays its payoff exactly once")

	# Reconstruct what Main does after reading a completed save: scalar state
	# loads silently, scene-shaped slot progress follows, then ambience syncs.
	Ambience.set_state(Ambience.State.TITLE, true)
	GameState.reset()
	GameState.register_dam_slot()
	GameState.load_from_save({})
	GameState.restore_dam_progress(1)
	var restore_stings_before := Ambience.get_transformation_sting_count()
	var restore_starts_before := Ambience.get_loop_start_count()
	Ambience.sync_from_game_state(true)
	assert(Ambience.get_state() == Ambience.State.RESTORED_POND)
	assert(Ambience.get_loop_start_count() == restore_starts_before + 1)
	assert(Ambience.get_transformation_sting_count() == restore_stings_before, "restoring a completed save must not replay the live sting")
	Ambience.sync_from_game_state(true)
	assert(Ambience.get_loop_start_count() == restore_starts_before + 1, "repeated restoration sync must remain idempotent")
	assert(Ambience.get_transformation_sting_count() == restore_stings_before)
	print("OK: completed save state selects restored ambience without replaying the transformation")

	print("ALL AMBIENCE TESTS PASSED")
	get_tree().quit()
