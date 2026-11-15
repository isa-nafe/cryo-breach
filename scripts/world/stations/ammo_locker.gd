class_name AmmoLocker
extends Interactable
## Armory ammo locker: refills the gun in your hand. The whole crew shares
## a few refills (GDD "Armory").

## Refills left for the whole crew.
var refills_left: int = 0


func _ready() -> void:
	super._ready()
	prompt = "Refill your gun"
	hold_seconds = Config.tuning.ammo_locker_seconds
	refills_left = Config.tuning.armory_refills


func can_interact(player: PlayerCharacter) -> bool:
	return enabled and refills_left > 0 and _find_gun_hand(player) != -1


func get_blocked_prompt(_player: PlayerCharacter) -> String:
	if refills_left <= 0:
		return "Ammo locker empty"
	return "Hold a gun that needs ammo"


func _on_interact(player: PlayerCharacter) -> void:
	var hand := _find_gun_hand(player)
	if hand == -1 or refills_left <= 0:
		return
	var stack := player.inventory.hands[hand]
	stack.charges = stack.data.weapon.capacity
	refills_left -= 1
	if Net.is_networked():
		_rpc_refills.rpc(refills_left)
	# Telling the inventory it changed rebuilds the gun in the player's hand.
	player.inventory.changed.emit()
	player.show_message("Gun refilled (%d refills left)" % refills_left)


## The hand holding a gun that is not full, or -1.
func _find_gun_hand(player: PlayerCharacter) -> int:
	for hand in 2:
		var stack := player.inventory.hands[hand]
		if stack == null or stack.data.weapon == null:
			continue
		if stack.charges < stack.data.weapon.capacity:
			return hand
	return -1


@rpc("authority", "call_remote", "reliable")
func _rpc_refills(count: int) -> void:
	refills_left = count
