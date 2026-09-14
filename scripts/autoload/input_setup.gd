extends Node
## Registers custom input actions in code (rather than as hand-edited
## resource literals in project.godot) so movement/interact bindings stay
## simple to read and change. Also tracks which input device the player is
## actually using, so HUD's action prompt (see hud.gd/interaction_option.gd)
## can show "[E]" or the gamepad button rather than guessing. Autoloaded as
## "InputSetup".

## Emitted whenever the active input device flips between keyboard/mouse and
## gamepad - HUD doesn't need this directly (it just reads uses_gamepad()
## each time it redraws the action prompt), but it's here for anything that
## wants to react live.
signal input_device_changed(is_gamepad: bool)

## Analog stick drift/noise below this shouldn't be enough to flip the
## prompt away from keyboard just because a controller happens to be
## plugged in.
const JOY_AXIS_DEADZONE := 0.5

var _uses_gamepad := false

func _ready() -> void:
	_bind("move_up", KEY_W, KEY_UP)
	_bind("move_down", KEY_S, KEY_DOWN)
	_bind("move_left", KEY_A, KEY_LEFT)
	_bind("move_right", KEY_D, KEY_RIGHT)
	_bind("interact", KEY_E, KEY_SPACE)
	_bind("restart", KEY_R)
	_bind("menu", KEY_ESCAPE)

	_add_joy_button("move_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("move_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_button("interact", JOY_BUTTON_A)
	_add_joy_button("restart", JOY_BUTTON_START)
	_add_joy_button("menu", JOY_BUTTON_BACK)

	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)

func _bind(action_name: String, primary: Key, secondary: Key = KEY_NONE) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	_add_key(action_name, primary)
	if secondary != KEY_NONE:
		_add_key(action_name, secondary)

## Binds by physical position (layout-independent - what a real keypress
## reports) AND by logical keycode, so the action also responds to
## synthetic input tools that only set one of the two fields.
func _add_key(action_name: String, key: Key) -> void:
	var physical_event := InputEventKey.new()
	physical_event.physical_keycode = key
	InputMap.action_add_event(action_name, physical_event)

	var logical_event := InputEventKey.new()
	logical_event.keycode = key
	InputMap.action_add_event(action_name, logical_event)

func _add_joy_button(action_name: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)

func _add_joy_axis(action_name: String, axis: JoyAxis, axis_sign: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_sign
	InputMap.action_add_event(action_name, event)

## Whichever device last produced a real (non-noise) input event - used to
## pick which glyph HUD's action prompt shows for "interact".
func uses_gamepad() -> bool:
	return _uses_gamepad

## The player-facing label for the "interact" action under the currently
## active input device. Text-only (no button glyph assets in this project),
## matching the actual bindings in _ready() above.
func interact_prompt() -> String:
	return "A" if _uses_gamepad else "E"

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_set_uses_gamepad(true)
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) >= JOY_AXIS_DEADZONE:
			_set_uses_gamepad(true)
	elif event is InputEventKey:
		_set_uses_gamepad(false)

func _set_uses_gamepad(value: bool) -> void:
	if _uses_gamepad == value:
		return
	_uses_gamepad = value
	input_device_changed.emit(value)
