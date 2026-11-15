class_name GunRack
extends Interactable
## Armory gun rack: holds one gun, taken once. For now it is always a
## pistol; M4.6 makes it a pistol or a shotgun at random.

var _taken := false


func _ready() -> void:
	super._ready()
	prompt = "Take the gun"
	hold_seconds = Config.tuning.gun_rack_seconds


func can_interact(_player: PlayerCharacter) -> bool:
	return enabled and not _taken


func get_blocked_prompt(_player: PlayerCharacter) -> String:
	return "The rack is empty"


func _on_interact(player: PlayerCharacter) -> void:
	_taken = true
	if Net.is_networked():
		_rpc_taken.rpc()
	var stack := ItemStack.create(Config.get_item(&"pistol"))
	if player.inventory.add(stack):
		player.show_message("Took the pistol")
	else:
		Pickup.spawn(get_tree(), stack, global_position)
		player.show_message("No room: the pistol is on the floor")


@rpc("authority", "call_remote", "reliable")
func _rpc_taken() -> void:
	_taken = true
