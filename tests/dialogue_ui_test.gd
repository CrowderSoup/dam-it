extends Node
## Headless regression test for the dialogue presentation/input layer (issue
## #18 - scenes/ui/dialogue_box.gd/.tscn). Companion to tests/story_test.gd
## (proves the data-driven runtime end-to-end with no UI) and
## tests/smoke_test.gd (core gameplay loop) - this one proves the UI that
## sits on top of ActOneController renders correctly, drives Moss's intro
## fixture (data/story/act1/dialogue_moss_intro.tres) end to end including
## its two-choice acknowledgement, and that every supported input path
## (keyboard, mouse, gamepad) reaches it without leaking into gameplay or
## getting double-applied.
##
## Run with:
##   godot --headless --path . tests/dialogue_ui_test.tscn
## It exits 0 and prints ALL DIALOGUE UI TESTS PASSED on success, or hits a
## SCRIPT ERROR: Assertion failed on the first broken behavior.
##
## What this can't prove headlessly (verified by hand instead against a
## running instance at the 640x360 target viewport): that Godot's built-in
## Control focus navigation actually moves between choice buttons when a
## real arrow key/D-pad/left-stick event flows through the engine's
## Viewport GUI input, that a real mouse click hits a choice button's own
## screen rect, and that text/portrait/choices actually fit the panel
## without clipping. Everything this file *can* reach - which input action
## fires which handler, whether the right node gets grab_focus()'d, whether
## effects/flags/objective state end up correct, whether pause/GameMenu
## coordination is correct, and that a keyboard-Space double-fire is
## structurally impossible (dialogue_box.gd's _handle_choice_input skips
## Space because a focused Button already consumes it via the engine's own
## ui_accept handling before _unhandled_input ever sees it) - is asserted
## directly instead, the same way tests/smoke_test.gd calls
## Player._try_interact()/InputSetup._input() directly rather than
## replaying real OS input events.

func _ready() -> void:
	SaveManager.set_storage_root_for_tests("user://automated_tests")
	SaveManager.begin_session(1)
	SaveManager.delete_save(1)
	GameState.reset()
	ActOneController.reset()

	var main_scene: PackedScene = load("res://scenes/main/main.tscn")
	var main: Node = main_scene.instantiate()
	add_child(main)

	var dialogue_box: CanvasLayer = main.get_node("DialogueBox")
	var game_menu: CanvasLayer = main.get_node("GameMenu")
	var journal: CanvasLayer = main.get_node("Journal")
	var hud: CanvasLayer = main.get_node("HUD")
	var player: CharacterBody2D = main.get_node("Player")

	# Main registers the full Willowbend fixture and begins its short arrival
	# conversation on a fresh save. Finish that prologue to reach the resident
	# interaction state this presentation test exercises.
	assert(ActOneController.has_objective("gather_starter_wood"), "Main should have already loaded the Act I fixture on _ready()")
	assert(ActOneController.get_active_dialogue_id() == "willowbend_arrival")
	assert(dialogue_box.visible and get_tree().paused, "the authored arrival should be visible and pause gameplay")
	for i in 4:
		ActOneController.advance_dialogue()
	assert(ActOneController.get_objective_status("meet_moss") == "active")
	assert(ActOneController.get_objective_status("gather_starter_wood") == "inactive")
	assert(hud._current_tutorial_id == hud.TUTORIAL_MOVE, "starting the objective during Main._ready() must not replace the fresh player's movement tutorial")
	assert(hud.TUTORIAL_JOURNAL in hud._pending_tutorial_ids, "the journal tutorial should wait behind movement help")

	assert(not dialogue_box.visible, "the dialogue box should start hidden")
	assert(not get_tree().paused, "the tree should start unpaused")
	assert(game_menu.process_mode == Node.PROCESS_MODE_ALWAYS, "GameMenu should start at its own PROCESS_MODE_ALWAYS (see game_menu.tscn), so it can open while paused")
	assert(player.process_mode == Node.PROCESS_MODE_INHERIT, "Player must not opt out of pausing, or an open dialogue wouldn't actually block movement/interact")
	print("OK: the dialogue box starts hidden, and Player stays pausable so a dialogue can safely block it")

	# --- Starting the dialogue shows the box, pauses gameplay (which stops
	# Player's own _physics_process/_unhandled_input, since it never opted
	# into PROCESS_MODE_ALWAYS - see the process_mode assert above), and
	# locks out the pause menu so Escape/Start reaches dialogue input
	# instead of stacking a pause menu on top of it (see main.gd). ---
	ActOneController.start_dialogue("moss_intro")
	assert(dialogue_box.visible, "starting a dialogue should show the dialogue box")
	assert(get_tree().paused, "starting a dialogue should pause the tree, same as GameMenu")
	assert(game_menu.process_mode == Node.PROCESS_MODE_DISABLED, "GameMenu should be disabled while a dialogue is open")
	assert(journal.process_mode == Node.PROCESS_MODE_DISABLED, "Journal should be disabled while a dialogue is open")
	assert(dialogue_box.speaker_label.text == "Moss", "the speaker label should show the capitalized speaker id")
	assert(dialogue_box.text_label.text.begins_with("So you are Hazel's grandkit"), "the text label should show the current line")
	assert(dialogue_box.continue_hint.visible and not dialogue_box.choices_container.visible, "a plain line should show the continue hint, not choices")
	print("OK: starting a dialogue shows speaker/text, pauses the tree, and disables the pause menu")

	# --- Keyboard E advances a plain line ---
	var key_e := InputEventKey.new()
	key_e.physical_keycode = KEY_E
	key_e.pressed = true
	dialogue_box._unhandled_input(key_e)
	assert(ActOneController.get_current_line().choices.size() == 3, "advancing should reach Moss's three response choices")
	assert(dialogue_box.choices_container.visible and not dialogue_box.continue_hint.visible, "a line with choices should show the choice buttons, not the continue hint")
	assert(dialogue_box.choice_buttons[0].has_focus(), "the first choice should be focused automatically, so gamepad/keyboard navigation never starts with nothing focused")
	print("OK: keyboard E advances a plain line, and a line with choices shows focused choice buttons")

	# --- Gamepad A confirms whichever choice is focused, via the explicit
	# bridge in dialogue_box.gd (this project's InputMap has no gamepad
	# event bound to the built-in ui_accept action, only Enter/Kp Enter/
	# Space) ---
	dialogue_box.choice_buttons[1].grab_focus()
	var choice_events: Array = []
	ActOneController.dialogue_choice_made.connect(func(id, choice_id, ack): choice_events.append([id, choice_id, ack]))
	assert(not ActOneController.get_flag("met_moss"), "met_moss should not be set before a choice is made")
	var joy_a := InputEventJoypadButton.new()
	joy_a.button_index = JOY_BUTTON_A
	joy_a.pressed = true
	dialogue_box._unhandled_input(joy_a)
	assert(choice_events.size() == 1, "gamepad A should confirm exactly the one focused choice, not zero or double-fire")
	assert(choice_events[0][1] == "practical_start_together", "gamepad A should confirm the second (focused) choice")
	assert(ActOneController.get_flag("met_moss"), "choosing a response should set the met_moss flag")
	print("OK: gamepad A confirms the focused choice exactly once")

	# --- The acknowledgement shows before advancing again - choices never
	# auto-advance the plot (dialogue-style.md) ---
	assert(not dialogue_box.choices_container.visible, "choices should hide once one is picked")
	assert(dialogue_box.continue_hint.visible, "the continue hint should return so the player can move past the acknowledgement")
	assert(dialogue_box.text_label.text == "Practical. I can work with practical.", "the acknowledgement should replace the line text")
	print("OK: picking a choice shows its acknowledgement and waits for another confirm, instead of auto-advancing")

	# --- A mouse click advances a plain line/acknowledgement too ---
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	dialogue_box._unhandled_input(click)
	assert(ActOneController.get_current_line().text.begins_with("Fine."), "a mouse click should advance past the acknowledgement to the closing line")
	assert(ActOneController.get_objective_status("meet_moss") == "completed")
	assert(ActOneController.get_objective_status("gather_starter_wood") == "active", "the closing line should start the gathering objective")
	print("OK: a mouse click advances dialogue too")

	# --- Leaving the dialogue: hides the box, unpauses, and re-enables the
	# pause menu - no lingering focus trap or blocked gameplay/menu input ---
	dialogue_box._unhandled_input(key_e)
	assert(not dialogue_box.visible, "the dialogue box should hide once the dialogue ends")
	assert(not get_tree().paused, "ending a dialogue should unpause the tree")
	assert(game_menu.process_mode == Node.PROCESS_MODE_ALWAYS, "GameMenu should be re-enabled (back to PROCESS_MODE_ALWAYS) once the dialogue ends")
	assert(journal.process_mode == Node.PROCESS_MODE_ALWAYS, "Journal should be re-enabled once the dialogue ends")
	assert(ActOneController.get_active_dialogue_id() == "", "the dialogue should have ended in ActOneController too")
	print("OK: leaving the dialogue restores normal gameplay/menu input with nothing left focus-trapped")

	# Signal-free save restoration must reconstruct a post-choice
	# acknowledgement in the DialogueBox instead of leaving the controller
	# active behind a hidden UI or replaying choice effects.
	ActOneController.reset()
	var meet_objective: ObjectiveDefinition = load("res://data/story/act1/objective_meet_moss.tres")
	var objective: ObjectiveDefinition = load("res://data/story/act1/objective_gather_starter_wood.tres")
	var dialogue: DialogueDefinition = load("res://data/story/act1/dialogue_moss_intro.tres")
	var objectives: Array[ObjectiveDefinition] = [meet_objective, objective]
	var dialogues: Array[DialogueDefinition] = [dialogue]
	ActOneController.load_content(objectives, dialogues)
	ActOneController.start_objective("meet_moss")
	ActOneController.start_dialogue("moss_intro")
	ActOneController.advance_dialogue()
	ActOneController.choose("practical_start_together")
	var acknowledgement_save := ActOneController.get_save_data()
	ActOneController.reset()
	ActOneController.load_content(objectives, dialogues)
	ActOneController.load_from_save(acknowledgement_save)
	dialogue_box.restore_from_state()
	assert(dialogue_box.visible and get_tree().paused, "restoring active dialogue state should make its UI visible and pause gameplay")
	assert(dialogue_box.text_label.text == "Practical. I can work with practical.")
	assert(not dialogue_box.choices_container.visible and dialogue_box.continue_hint.visible, "a restored acknowledgement must not offer its choices again")
	dialogue_box._unhandled_input(key_e)
	assert(ActOneController.get_current_line().text.begins_with("Fine."), "the restored acknowledgement should advance normally")
	dialogue_box._unhandled_input(key_e)
	assert(not dialogue_box.visible and not get_tree().paused)
	print("OK: DialogueBox restores the exact saved acknowledgement phase")

	print("ALL DIALOGUE UI TESTS PASSED")
	get_tree().quit()
