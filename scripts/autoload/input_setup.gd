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

func _bind(action_name: String, primary: Key, secondary: Key = KEY_NONE) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var event_primary := InputEventKey.new()
	event_primary.physical_keycode = primary
	InputMap.action_add_event(action_name, event_primary)
	if secondary != KEY_NONE:
		var event_secondary := InputEventKey.new()
		event_secondary.physical_keycode = secondary
		InputMap.action_add_event(action_name, event_secondary)
