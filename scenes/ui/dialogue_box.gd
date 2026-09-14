extends CanvasLayer
## Presents ActOneController's dialogue runtime (see
## scripts/autoload/act_one_controller.gd and docs/design/dialogue-schema.md):
## speaker name, an expressive portrait, the current line's text, and up to
## three response choices. Purely reactive - this node reads state from
## ActOneController's signals/getters and only ever calls back into it via
## choose()/advance_dialogue(); it never mutates story state itself.
##
## Input (reusing InputSetup's existing action map - see input_setup.gd, not
## a parallel scheme):
## - Advancing a plain line or confirming the focused choice: keyboard E or
##   Space, a mouse click, or gamepad A - all the "interact" action.
## - Moving focus between choices: arrow keys, D-pad, or the left stick -
##   Godot's built-in Control focus navigation already runs on ui_up/ui_down/
##   ui_left/ui_right, which share the same physical keys/buttons as
##   move_up/move_down (see input_setup.gd) without being the same action, so
##   this needs no extra wiring.
##
## Pauses the SceneTree while open, the same pattern game_menu.gd uses, so
## gameplay (movement, gathering, interacting) can't happen underneath an
## open conversation - Player and every world object simply stop receiving
## _physics_process/_unhandled_input while paused, since only this node (and
## GameMenu) opt back in via PROCESS_MODE_ALWAYS. Main additionally disables
## GameMenu's own input while a dialogue is open, so Escape/Start can't pop
## the pause menu on top of a conversation (see main.gd).
##
## Ordinary dialogue never auto-advances (dialogue-style.md) - every
## transition, including reading a choice's acknowledgement, waits for an
## explicit confirm. That also means "review" needs no special handling:
## a line simply stays on screen, exactly as shown, until the player
## chooses to move on.

@onready var portrait: Control = $Margin/VBox/TopRow/PortraitPanel/Portrait
@onready var speaker_label: Label = $Margin/VBox/TopRow/TextColumn/SpeakerNameLabel
@onready var text_label: Label = $Margin/VBox/TopRow/TextColumn/TextLabel
@onready var choices_container: VBoxContainer = $Margin/VBox/BottomArea/ChoicesContainer
@onready var continue_hint: Label = $Margin/VBox/BottomArea/ContinueHint
@onready var choice_buttons: Array[Button] = [
	$Margin/VBox/BottomArea/ChoicesContainer/ChoiceButton1,
	$Margin/VBox/BottomArea/ChoicesContainer/ChoiceButton2,
	$Margin/VBox/BottomArea/ChoicesContainer/ChoiceButton3,
]

var _showing_choices := false
var _current_choice_ids: Array[String] = []

func _ready() -> void:
	hide()
	ActOneController.dialogue_started.connect(_on_dialogue_started)
	ActOneController.dialogue_line_shown.connect(_on_dialogue_line_shown)
	ActOneController.dialogue_choice_made.connect(_on_dialogue_choice_made)
	ActOneController.dialogue_ended.connect(_on_dialogue_ended)
	InputSetup.input_device_changed.connect(_on_input_device_changed)
	for i in choice_buttons.size():
		choice_buttons[i].pressed.connect(_on_choice_button_pressed.bind(i))

func _on_dialogue_started(_id: String) -> void:
	show()
	get_tree().paused = true

func _on_dialogue_line_shown(_id: String, _index: int) -> void:
	_render_current_line()

## A choice's acknowledgement isn't a DialogueLine of its own (see
## StoryEffect/DialogueChoice) - just report it in the same speaker/text
## slots the line above it used, then wait for another confirm before
## calling advance_dialogue().
func _on_dialogue_choice_made(_id: String, _choice_id: String, acknowledgement: String) -> void:
	_showing_choices = false
	choices_container.hide()
	text_label.text = acknowledgement
	continue_hint.show()
	_refresh_continue_hint()

func _on_dialogue_ended(_id: String) -> void:
	hide()
	get_tree().paused = false

func _render_current_line() -> void:
	var line := ActOneController.get_current_line()
	if line == null:
		return
	var speaker_id := ActOneController.get_current_speaker()
	speaker_label.text = speaker_id.capitalize()
	portrait.set_speaker(speaker_id)
	text_label.text = line.text
	_populate_choices(line.choices)

func _populate_choices(choices: Array[DialogueChoice]) -> void:
	_current_choice_ids.clear()
	for i in choice_buttons.size():
		if i < choices.size():
			choice_buttons[i].text = choices[i].text
			choice_buttons[i].show()
			_current_choice_ids.append(choices[i].id)
		else:
			choice_buttons[i].hide()
	_showing_choices = not choices.is_empty()
	choices_container.visible = _showing_choices
	continue_hint.visible = not _showing_choices
	if _showing_choices:
		choice_buttons[0].grab_focus()
	else:
		_refresh_continue_hint()

func _on_choice_button_pressed(index: int) -> void:
	if index >= _current_choice_ids.size():
		return
	ActOneController.choose(_current_choice_ids[index])

func _on_input_device_changed(_is_gamepad: bool) -> void:
	_refresh_continue_hint()

func _refresh_continue_hint() -> void:
	continue_hint.text = "[%s] Continue" % InputSetup.interact_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _showing_choices:
		_handle_choice_input(event)
		return
	if event.is_action_pressed("interact"):
		ActOneController.advance_dialogue()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		ActOneController.advance_dialogue()
		get_viewport().set_input_as_handled()

## Gamepad A has no built-in ui_accept binding in this project (only
## Enter/Kp Enter/Space do - see input_setup.gd's action map), so a focused
## choice button needs an explicit bridge to fire on "interact" too. Skip
## Space specifically: it's already part of ui_accept, so Godot's own
## Control focus system activates the focused Button's "pressed" signal for
## it before this node ever sees the event (a Control's GUI input runs
## ahead of _unhandled_input) - handling it again here would apply the
## choice's effects twice.
func _handle_choice_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if event is InputEventKey and event.physical_keycode == KEY_SPACE:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button and focused in choice_buttons and focused.visible:
		focused.pressed.emit()
		get_viewport().set_input_as_handled()
