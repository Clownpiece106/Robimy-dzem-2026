class_name InputSetup
extends RefCounted

static func configure() -> void:
	_bind("p1_move_left", KEY_A)
	_bind("p1_move_right", KEY_D)
	_bind("p1_move_background", KEY_W)
	_bind("p1_move_foreground", KEY_S)
	_bind("p2_move_left", KEY_LEFT)
	_bind("p2_move_right", KEY_RIGHT)
	_bind("p2_move_background", KEY_UP)
	_bind("p2_move_foreground", KEY_DOWN)

static func _bind(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	else:
		InputMap.action_erase_events(action_name)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, key_event)
