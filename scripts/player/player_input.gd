class_name PlayerInput
extends Node
## Reads the local keyboard and mouse into an InputState.
##
## The character never reads Input directly; it asks this node for an
## InputState once per physics frame. A bot or a network peer can later
## replace this node with another source of InputState.

## The input for this frame. The character reads it and clears one-shots.
var state := InputState.new()
## When false (menus, remote players), this node produces no input.
var enabled := true


func _ready() -> void:
	# Characters controlled from another machine read no keyboard here.
	var character := get_parent() as PlayerCharacter
	if character != null and not character.is_local():
		enabled = false
		set_process_unhandled_input(false)
		return
	_capture_mouse(true)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return

	if event.is_action_pressed("pause"):
		_capture_mouse(false)
		return

	if not _is_mouse_captured():
		# Click back into the window to resume.
		if event is InputEventMouseButton and event.is_pressed():
			_capture_mouse(true)
			get_viewport().set_input_as_handled()
		return

	var motion := event as InputEventMouseMotion
	if motion:
		state.look_delta -= motion.relative * Config.tuning.mouse_sensitivity
	elif event.is_action_pressed("toggle_lamp"):
		state.toggle_lamp = true
	elif event.is_action_pressed("interact"):
		state.interact = true


## Returns this frame's input. Called by the character every physics frame.
func poll() -> InputState:
	if enabled and _is_mouse_captured():
		state.move = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		state.sprint = Input.is_action_pressed("sprint")
		state.crouch = Input.is_action_pressed("crouch")
		state.fire = Input.is_action_pressed("fire")
		state.interact_held = Input.is_action_pressed("interact")
		state.fire_off = Input.is_action_pressed("use_off_hand")
		state.reload_held = Input.is_action_pressed("reload")
		for slot in 4:
			if Input.is_action_just_pressed("slot_%d" % (slot + 1)):
				state.slot_press = slot + 1
		if Input.is_action_just_pressed("swap_hands"):
			state.swap_hands = true
		if Input.is_action_just_pressed("drop"):
			state.drop = true
		if Input.is_action_just_pressed("jump"):
			state.jump = true
	else:
		state.release_all()
	return state


func _capture_mouse(capture: bool) -> void:
	if capture:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		state.release_all()


func _is_mouse_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
