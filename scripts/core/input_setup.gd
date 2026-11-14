class_name InputSetup
extends RefCounted
## Creates the default key bindings when the game starts.
##
## Any action you define yourself in Project Settings > Input Map is left
## alone, so you can rebind keys there and those bindings win.

## Action name -> physical keys (positions on the keyboard, so AZERTY works).
const KEY_ACTIONS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_CTRL, KEY_C],
	"jump": [KEY_SPACE],
	"interact": [KEY_E],
	"toggle_lamp": [KEY_F],
	"toggle_debug": [KEY_F3],
	"pause": [KEY_ESCAPE],
	"restart": [KEY_R],
	"reload": [KEY_R],
	"slot_1": [KEY_1],
	"slot_2": [KEY_2],
	"slot_3": [KEY_3],
	"slot_4": [KEY_4],
	"swap_hands": [KEY_X],
	"drop": [KEY_G],
}

## Action name -> mouse button.
const MOUSE_ACTIONS := {
	"fire": MOUSE_BUTTON_LEFT,
	"use_off_hand": MOUSE_BUTTON_RIGHT,
}


static func ensure_default_actions() -> void:
	for action: String in KEY_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in KEY_ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

	for action: String in MOUSE_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_ACTIONS[action]
		InputMap.action_add_event(action, event)
