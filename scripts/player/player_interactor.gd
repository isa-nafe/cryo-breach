class_name PlayerInteractor
extends Node
## Finds what the player is looking at and runs the hold-to-use timer.
## Child of the player, named "Interactor". Only runs for the local player.

## The interactable under the crosshair, or null.
var focused: Interactable = null
## The hold timer for the interact key (the HUD reads its progress).
var hold := HoldAction.new()


## Call every physics frame from the character.
func update(player: PlayerCharacter, interact_held: bool, delta: float) -> void:
	focused = _find_focus(player)
	var usable := focused != null and focused.can_interact(player)
	var target: Variant = focused if usable else null
	var seconds := focused.get_hold_seconds(player) if usable else 0.0
	if hold.update(interact_held, target, seconds, delta):
		focused.request_interact(player)


## Text for the HUD, for example "[E] Search (hold)". Empty if nothing.
func get_prompt_text(player: PlayerCharacter) -> String:
	if focused == null:
		return ""
	if not focused.can_interact(player):
		return focused.get_blocked_prompt(player)
	var text := focused.get_prompt(player)
	if text.is_empty():
		return ""
	if focused.get_hold_seconds(player) > 0.0:
		return "[E] %s (hold)" % text
	return "[E] %s" % text


func _find_focus(player: PlayerCharacter) -> Interactable:
	var from := player.camera.global_position
	var to := from - player.camera.global_basis.z * Config.tuning.interact_range
	var mask := Layers.WORLD | Layers.DOORS | Layers.INTERACTABLES
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	query.collide_with_areas = true
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.collider as Interactable
