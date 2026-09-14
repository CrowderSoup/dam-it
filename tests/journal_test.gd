extends Node
## Headless regression test for issue #16 (the current-objective HUD
## display, the Journal, and staged tutorials that persist their "seen"
## state). Companion to tests/smoke_test.gd and tests/story_test.gd - same
## conventions, separate file because this exercises the objective/tutorial
## UI layer rather than the moment-to-moment gameplay loop or the story data
## foundation itself.
##
## Run with:
##   godot --headless --path . tests/journal_test.tscn
## It exits 0 and prints ALL JOURNAL TESTS PASSED on success, or hits a
## SCRIPT ERROR: Assertion failed on the first broken behavior.

func _ready() -> void:
	GameState.reset()
	ActOneController.reset()

	# --- ActOneController: current-objective tracking + plain-language summaries ---
	var gather := ObjectiveDefinition.new()
	gather.id = "test_gather_wood"
	gather.title = "Gather Some Wood"
	gather.description = "A test objective that completes once enough wood is held."
	gather.completion_type = ObjectiveDefinition.CompletionType.RESOURCE_AT_LEAST
	gather.resource = "wood"
	gather.target_amount = 3

	var build := ObjectiveDefinition.new()
	build.id = "test_build_something"
	build.title = "Build Something"
	build.description = "A test objective completed manually rather than by a resource count."
	build.completion_type = ObjectiveDefinition.CompletionType.MANUAL

	var objectives: Array[ObjectiveDefinition] = [gather, build]
	ActOneController.load_content(objectives, [])

	assert(ActOneController.get_current_objective_id() == "", "no objective should be current before anything starts")
	print("OK: get_current_objective_id() is empty before any objective starts")

	var summaries := ActOneController.get_objective_summaries()
	assert(summaries.size() == 2, "expected both registered objectives in the summary list, got %d" % summaries.size())
	assert(summaries[0]["id"] == "test_gather_wood" and summaries[0]["status"] == "inactive")
	assert(summaries[1]["id"] == "test_build_something" and summaries[1]["status"] == "inactive")
	print("OK: get_objective_summaries() lists every registered objective, in registration order, before any start")

	ActOneController.start_objective("test_gather_wood")
	assert(ActOneController.get_current_objective_id() == "test_gather_wood", "starting an objective should make it current")
	print("OK: start_objective() sets get_current_objective_id()")

	GameState.add_wood(3)
	assert(ActOneController.get_objective_status("test_gather_wood") == "completed")
	assert(ActOneController.get_current_objective_id() == "test_gather_wood", "completing the current objective should not clear it - it stays current until something new starts")
	print("OK: completing the current objective keeps it current until a new one starts")

	ActOneController.start_objective("test_build_something")
	assert(ActOneController.get_current_objective_id() == "test_build_something", "starting a second objective should replace the current one")
	print("OK: starting a new objective replaces the previous current objective")

	var completed_summaries := ActOneController.get_objective_summaries()
	assert(completed_summaries[0]["status"] == "completed" and completed_summaries[0]["current"] == 3 and completed_summaries[0]["target"] == 3)
	assert(completed_summaries[1]["status"] == "active")
	print("OK: get_objective_summaries() reflects each objective's own status/progress independently")

	# --- HUD: current-objective display sourced from ActOneController ---
	var hud: CanvasLayer = load("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	assert(hud.objective_label.visible, "HUD should show the objective banner immediately if one is already current when it's created")
	assert(hud.objective_label.text == "Build Something", "a MANUAL objective with no progress target should just show its title, got: %s" % hud.objective_label.text)
	print("OK: HUD picks up an already-active objective as soon as it's created")

	GameState.wood = 0
	ActOneController.reset()
	GameState.reset()
	var gather2 := ObjectiveDefinition.new()
	gather2.id = "test_gather_wood_2"
	gather2.title = "Gather More Wood"
	gather2.description = "A second fixture, started fresh so progress ticks up from zero."
	gather2.completion_type = ObjectiveDefinition.CompletionType.RESOURCE_AT_LEAST
	gather2.resource = "wood"
	gather2.target_amount = 5
	var objectives2: Array[ObjectiveDefinition] = [gather2]
	ActOneController.load_content(objectives2, [])
	ActOneController.start_objective("test_gather_wood_2")
	assert(hud.objective_label.text == "Gather More Wood (0/5)", "an active resource objective should show its live progress, got: %s" % hud.objective_label.text)
	GameState.add_wood(2)
	assert(hud.objective_label.text == "Gather More Wood (2/5)", "objective_progress_changed should refresh the HUD label, got: %s" % hud.objective_label.text)
	GameState.add_wood(3)
	assert(hud.objective_label.text == "[Done] Gather More Wood", "a completed objective should use the Web-safe done marker and drop its progress numbers, got: %s" % hud.objective_label.text)
	print("OK: HUD's objective label tracks live progress and uses a Web-safe completion marker")

	ActOneController.reset()
	hud._refresh_objective_display()
	assert(not hud.objective_label.visible, "HUD should hide the objective banner once nothing is current (e.g. after a reset)")
	print("OK: HUD hides the objective banner when there is no current objective")

	# --- Journal: lists active/completed objectives in plain language, skips ones that never started ---
	GameState.reset()
	ActOneController.reset()
	var journal: CanvasLayer = load("res://scenes/ui/journal.tscn").instantiate()
	add_child(journal)

	var never_started := ObjectiveDefinition.new()
	never_started.id = "test_never_started"
	never_started.title = "Not Started Yet"
	never_started.description = "Should never show up in the journal."
	var active_obj := ObjectiveDefinition.new()
	active_obj.id = "test_active"
	active_obj.title = "Currently Active"
	active_obj.description = "An in-progress test objective."
	var completed_obj := ObjectiveDefinition.new()
	completed_obj.id = "test_completed"
	completed_obj.title = "Already Done"
	completed_obj.description = "A finished test objective."
	var journal_objectives: Array[ObjectiveDefinition] = [never_started, active_obj, completed_obj]
	ActOneController.load_content(journal_objectives, [])
	ActOneController.start_objective("test_active")
	ActOneController.start_objective("test_completed")
	ActOneController.complete_objective("test_completed")

	journal.open()
	assert(get_tree().paused, "opening the journal should pause the tree")
	assert(journal.list.item_count == 2, "the journal should list the active and completed objectives but skip the one that never started, got %d items" % journal.list.item_count)
	assert(journal.list.get_item_text(0).ends_with("Currently Active"), "got: %s" % journal.list.get_item_text(0))
	assert(journal.list.get_item_text(0).begins_with("> "), "an active objective's entry should have an ASCII marker")
	assert(journal.list.get_item_text(1).ends_with("Already Done"), "got: %s" % journal.list.get_item_text(1))
	assert(journal.list.get_item_text(1).begins_with("[Done] "), "a completed objective's entry should have an ASCII done marker")
	print("OK: the journal uses Web-safe ASCII markers and skips objectives that never started")

	journal.list.select(1)
	journal._on_item_selected(1)
	assert(journal.description_label.text.begins_with(completed_obj.description), "got: %s" % journal.description_label.text)
	assert(journal.description_label.text.ends_with("Completed"), "got: %s" % journal.description_label.text)
	print("OK: selecting a journal entry shows its description and status in plain language")

	journal.close()
	assert(not get_tree().paused, "closing the journal should unpause the tree")
	print("OK: journal.open()/close() pause and unpause the tree")

	# --- Journal / GameMenu mutual exclusion (a bare CanvasLayer stands in
	# for GameMenu here - journal.gd only ever reads its `visible` property) ---
	var fake_menu := CanvasLayer.new()
	add_child(fake_menu)
	journal.set_game_menu(fake_menu)

	var journal_action := InputEventAction.new()
	journal_action.action = "journal"
	journal_action.pressed = true

	fake_menu.show()
	journal._unhandled_input(journal_action)
	assert(not journal.visible, "the journal should not open while the game menu is visible")
	print("OK: the journal refuses to open while the game menu is open")

	fake_menu.hide()
	journal._unhandled_input(journal_action)
	assert(journal.visible, "the journal should open once the game menu is closed")
	journal._unhandled_input(journal_action)
	assert(not journal.visible, "pressing the journal action again should close it")
	print("OK: the \"journal\" action toggles the journal open/closed once the game menu is out of the way")

	journal._unhandled_input(journal_action)
	assert(journal.visible)
	var cancel_action := InputEventAction.new()
	cancel_action.action = "ui_cancel"
	cancel_action.pressed = true
	journal._unhandled_input(cancel_action)
	assert(not journal.visible, "ui_cancel (Escape/gamepad B by default) should close an open journal")
	print("OK: ui_cancel closes an open journal")

	# --- GameState: tutorial-seen tracking + persistence ---
	GameState.reset()
	assert(not GameState.has_seen_tutorial("move"), "a fresh GameState should not have seen any tutorial")
	GameState.mark_tutorial_seen("move")
	assert(GameState.has_seen_tutorial("move"))
	assert(not GameState.has_seen_tutorial("interact"), "marking one tutorial seen should not affect another")
	print("OK: GameState tracks tutorial-seen state per id")

	GameState.load_from_save({"seen_tutorials": {"move": true, "interact": true, "bogus": "not a bool"}})
	assert(GameState.has_seen_tutorial("move") and GameState.has_seen_tutorial("interact"))
	assert(not GameState.has_seen_tutorial("bogus"), "a non-true value for a tutorial id should not count as seen")
	print("OK: load_from_save() restores tutorial-seen state from a save, ignoring malformed entries")

	GameState.load_from_save({})
	assert(not GameState.has_seen_tutorial("move"), "a save with no seen_tutorials field (e.g. an old save) should default to nothing seen")
	print("OK: load_from_save() defaults to no tutorials seen when the field is missing")

	GameState.reset()
	assert(not GameState.has_seen_tutorial("move"), "reset() should clear tutorial-seen state")
	print("OK: GameState.reset() clears tutorial-seen state")

	# --- HUD: staged tutorials appear once, can be dismissed, and stay seen ---
	GameState.reset()
	ActOneController.reset()
	var hud2: CanvasLayer = load("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud2)
	assert(hud2.tutorial_label.visible, "the move tutorial should show immediately for a player who hasn't seen it")
	assert(not GameState.has_seen_tutorial(hud2.TUTORIAL_MOVE), "showing a tutorial should not itself mark it seen")
	hud2._dismiss_tutorial()
	assert(not hud2.tutorial_label.visible, "dismissing should hide the tutorial banner")
	assert(GameState.has_seen_tutorial(hud2.TUTORIAL_MOVE), "dismissing should mark the tutorial seen")
	print("OK: dismissing a tutorial hides it and marks it seen")

	var hud3: CanvasLayer = load("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud3)
	assert(not hud3.tutorial_label.visible, "a tutorial already marked seen should not show again on a fresh HUD (e.g. after loading a save)")
	print("OK: a fresh HUD does not re-show a tutorial GameState already has marked seen")

	# The interact tutorial appears the moment an interaction option becomes
	# available, and performing the taught action (without it being
	# consumed) both dismisses and marks it seen.
	var demo_option := InteractionOption.new("Chop", func(): pass, true)
	hud3.set_action_prompt(demo_option)
	assert(hud3.tutorial_label.visible and hud3.tutorial_label.text.findn("chop") != -1, "the interact tutorial should appear once an interaction option is offered, got: %s" % hud3.tutorial_label.text)
	assert(not GameState.has_seen_tutorial(hud3.TUTORIAL_INTERACT))
	var interact_action := InputEventAction.new()
	interact_action.action = "interact"
	interact_action.pressed = true
	hud3._unhandled_input(interact_action)
	assert(not hud3.tutorial_label.visible, "pressing interact while its tutorial shows should dismiss it")
	assert(GameState.has_seen_tutorial(hud3.TUTORIAL_INTERACT))
	print("OK: performing the taught action dismisses its tutorial (without consuming the input) and marks it seen")

	# The longest current interaction reason must wrap inside its panel rather
	# than escaping the 640px viewport (issue #32's second screenshot).
	var long_option := InteractionOption.new("Chop", func(): pass, false, GameState.pouch_full_message("wood"))
	hud3.set_action_prompt(long_option)
	await get_tree().process_frame
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(640, 360))
	assert(viewport_rect.encloses(hud3.action_prompt_background.get_rect()), "the action-prompt panel must stay inside the base viewport")
	assert(viewport_rect.encloses(hud3.action_prompt_label.get_rect()), "the wrapped action-prompt label must stay inside the base viewport")
	assert(hud3.action_prompt_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "longer future prompts must wrap instead of drawing beyond their panel")
	print("OK: long action prompts stay inside a bounded, wrapping panel")

	# The journal tutorial appears the moment the player's first objective starts.
	assert(not GameState.has_seen_tutorial(hud3.TUTORIAL_JOURNAL))
	var trigger_objective := ObjectiveDefinition.new()
	trigger_objective.id = "test_journal_tutorial_trigger"
	trigger_objective.title = "Trigger"
	trigger_objective.description = "Exists only to fire objective_started."
	var trigger_objectives: Array[ObjectiveDefinition] = [trigger_objective]
	ActOneController.load_content(trigger_objectives, [])
	ActOneController.start_objective("test_journal_tutorial_trigger")
	assert(hud3.tutorial_label.visible and hud3.tutorial_label.text.findn("journal") != -1, "starting the first objective should surface the journal tutorial, got: %s" % hud3.tutorial_label.text)
	print("OK: the journal tutorial appears the moment the first objective starts")

	# A second tutorial becoming relevant cannot replace the one being read.
	var queued_test_tutorial := "queued_test"
	hud3._show_tutorial(queued_test_tutorial)
	assert(hud3._current_tutorial_id == hud3.TUTORIAL_JOURNAL, "a visible tutorial should remain on screen until dismissed")
	assert(queued_test_tutorial in hud3._pending_tutorial_ids, "the later tutorial should wait in sequence")
	print("OK: simultaneous tutorial triggers queue instead of overwriting fresh-player guidance")

	print("ALL JOURNAL TESTS PASSED")
	get_tree().quit()
