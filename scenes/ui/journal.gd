extends CanvasLayer
## Compact objective journal: lists every objective ActOneController has
## started, in plain language, as a master (title) / detail (description +
## status) pair - see docs/design/dialogue-schema.md for the objective data
## this reads. Toggled by the "journal" action (keyboard J / gamepad Y), or
## by clicking HUD's current-objective banner (see hud.gd's
## journal_requested signal, wired up by Main).
##
## Pauses the SceneTree while open, like GameMenu, so nothing keeps moving
## behind it while the player reads - but stays PROCESS_MODE_ALWAYS so it
## keeps responding while paused. Mutually exclusive with GameMenu (see
## set_game_menu() and _unhandled_input()) so the two never stack open.
##
## Navigation is deliberately built on Godot's built-in Control focus system
## (ItemList responds to the default ui_up/ui_down/ui_cancel actions, which
## are bound to arrow keys and gamepad d-pad/B out of the box - see
## InputMap's project-independent defaults) rather than hand-rolled input
## handling, the same free ride GameMenu's buttons already take via
## grab_focus().

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var list: ItemList = $Panel/VBoxContainer/Content/ObjectiveList
@onready var description_label: Label = $Panel/VBoxContainer/Content/DetailPanel/DescriptionLabel

## Set by Main so GameMenu and the journal never stack open on top of each
## other - see game_menu.gd's matching _journal field.
var _game_menu: CanvasLayer = null

## Objective ids in the same order as `list`'s items, so a selection index
## can be mapped back to the objective it describes.
var _ids: Array[String] = []

func _ready() -> void:
	hide()
	list.item_selected.connect(_on_item_selected)
	# CloseButton's "pressed" -> close() connection is wired in journal.tscn,
	# matching game_menu.tscn's convention for its own buttons.
	ActOneController.objective_started.connect(func(_id): _refresh())
	ActOneController.objective_progress_changed.connect(func(_id, _current, _target): _refresh())
	ActOneController.objective_completed.connect(func(_id): _refresh())

func set_game_menu(game_menu: CanvasLayer) -> void:
	_game_menu = game_menu

## Closing responds to "journal" (the same action that opened it) and to
## ui_cancel (Escape/gamepad B by default) - deliberately NOT to the custom
## "menu" action, which is GameMenu's alone, so the two never race to
## interpret the same Escape press differently (see game_menu.gd's own
## "menu"-only guard for the matching half of this).
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("journal"):
		if visible:
			close()
		elif _game_menu == null or not _game_menu.visible:
			open()
		get_viewport().set_input_as_handled()

func open() -> void:
	_refresh()
	show()
	get_tree().paused = true
	if not _ids.is_empty():
		list.grab_focus()
	else:
		close_button.grab_focus()

func close() -> void:
	hide()
	get_tree().paused = false

## Rebuilds the list from ActOneController's current state, trying to keep
## the same objective selected across a refresh (progress ticking up
## shouldn't visibly reset what the player was looking at).
func _refresh() -> void:
	var previously_selected := ""
	if not _ids.is_empty() and not list.get_selected_items().is_empty():
		previously_selected = _ids[list.get_selected_items()[0]]

	list.clear()
	_ids.clear()
	for summary in ActOneController.get_objective_summaries():
		# "inactive" objectives haven't started yet - nothing to show the
		# player about a goal they don't have yet.
		if summary["status"] == "inactive":
			continue
		# Godot's Web export does not have the desktop system-font fallback
		# that happened to supply these Unicode glyphs locally. Keep status
		# markers in the guaranteed ASCII range so the journal is identical in
		# native and browser builds.
		var prefix := "[Done] " if summary["status"] == "completed" else "> "
		list.add_item(prefix + String(summary["title"]))
		_ids.append(summary["id"])

	list.visible = not _ids.is_empty()
	if _ids.is_empty():
		description_label.text = "No objectives yet - explore a little and one will turn up."
		return

	var reselect_index := _ids.find(previously_selected)
	if reselect_index == -1:
		reselect_index = _ids.size() - 1
	list.select(reselect_index)
	_on_item_selected(reselect_index)

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _ids.size():
		return
	var id: String = _ids[index]
	var objective: ObjectiveDefinition = ActOneController.get_objective(id)
	var status := ActOneController.get_objective_status(id)
	var status_text := "Completed" if status == "completed" else "In progress"
	if status == "active" and objective.completion_type == ObjectiveDefinition.CompletionType.RESOURCE_AT_LEAST:
		status_text += " (%d/%d)" % [ActOneController.get_objective_progress(id), objective.target_amount]
	description_label.text = "%s\n\n%s" % [objective.description, status_text]
