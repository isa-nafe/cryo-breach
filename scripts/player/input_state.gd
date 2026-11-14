class_name InputState
extends RefCounted
## What a player wants to do this frame, independent of where it came from.
##
## The local keyboard and mouse fill this in today (see PlayerInput). Later a
## network peer or a bot will fill in the same object, so the character code
## never has to change.

## Movement wish: x = right (+) / left (-), y = forward (+) / back (-).
var move := Vector2.ZERO
## Look change since it was last applied, in radians: x = yaw, y = pitch.
var look_delta := Vector2.ZERO
## Held buttons.
var sprint := false
var crouch := false
var fire := false
## Right mouse button: use the item in the off hand.
var fire_off := false
## Reload key held.
var reload_held := false
## One-shot presses: true for one physics frame, then cleared.
var jump := false
var interact := false
## True while the interact key is held (for hold-to-use actions).
var interact_held := false
var toggle_lamp := false
## Slot key pressed: 1 to 4, or 0 for none.
var slot_press := 0
var swap_hands := false
var drop := false


## Clears the one-shot presses after the character has used them.
func clear_one_shots() -> void:
	jump = false
	interact = false
	toggle_lamp = false
	slot_press = 0
	swap_hands = false
	drop = false


## Lets go of everything (used when the mouse is freed or input is disabled).
func release_all() -> void:
	move = Vector2.ZERO
	look_delta = Vector2.ZERO
	sprint = false
	crouch = false
	fire = false
	fire_off = false
	reload_held = false
	interact_held = false
	clear_one_shots()
