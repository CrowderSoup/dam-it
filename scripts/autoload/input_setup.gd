extends Node
## Registers custom input actions in code (rather than as hand-edited
## resource literals in project.godot) so movement/interact bindings stay
## simple to read and change. Autoloaded as "InputSetup".

func _ready() -> void:
	_bind("move_up", KEY_W, KEY_UP)
	_bind("move_down", KEY_S, KEY_DOWN)
	_bind("move_left", KEY_A, KEY_LEFT)
	_bind("move_right", KEY_D, KEY_RIGHT)
	_bind("interact", KEY_E, KEY_SPACE)
	_bind("restart", KEY_R)

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
