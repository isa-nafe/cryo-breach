class_name PodSocket
extends Interactable
## The power socket in the Pod Bay. A power cell in a hand unlocks the escape
## pods for good (GDD "Escape pods").


func _ready() -> void:
	super._ready()
	add_to_group(&"pod_socket")


## Nothing happens on E; the socket is used with an item.
func can_interact(_player: PlayerCharacter) -> bool:
	return false


func get_blocked_prompt(_player: PlayerCharacter) -> String:
	if GameState.ship_state.pods_unlocked:
		return "Pod power is on"
	return "Pod power is off: needs a power cell"


func get_item_prompt(_player: PlayerCharacter, item: ItemData) -> String:
	if item.id == &"power_cell" and not GameState.ship_state.pods_unlocked:
		return "Insert power cell"
	return ""


func get_item_seconds(_player: PlayerCharacter, _item: ItemData) -> float:
	return Config.tuning.pod_socket_seconds


func _on_item_used(player: PlayerCharacter, _item: ItemData, hand: int) -> void:
	player.inventory.consume_from_hand(hand)
	_unlock_pods()
	# Pods being unlocked is public, so every machine hears about it.
	if Net.is_networked():
		_rpc_unlocked.rpc()
	player.show_message("Escape pods unlocked")


func _unlock_pods() -> void:
	GameState.ship_state.pods_unlocked = true
	get_tree().call_group(&"escape_pods", &"on_unlocked")


@rpc("authority", "call_remote", "reliable")
func _rpc_unlocked() -> void:
	_unlock_pods()
