class_name Interactable
extends Area3D
## Something a player can look at and use. Give it a CollisionShape3D.
##
## Simple cases: set the exports and connect to `interacted`.
## Complex cases (doors, stations): extend this class and override
## `get_prompt`, `get_hold_seconds`, `can_interact` and `_on_interact`.

## Emitted on the host when a player completes the interaction.
signal interacted(player: PlayerCharacter)
## Emitted on the host when a player uses a held item on this.
signal item_used(player: PlayerCharacter, item: ItemData)

## Text after the key, for example "Search". Empty hides the prompt.
@export var prompt: String = "Use"
## Seconds the key must be held. 0 = instant.
@export var hold_seconds: float = 0.0
## Noise added to the player's zone on completion.
@export var noise: float = 0.0

## When false the interactable cannot be used and shows no prompt.
var enabled := true


func _ready() -> void:
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	monitoring = false


## Prompt for this player right now. Override for changing prompts.
func get_prompt(_player: PlayerCharacter) -> String:
	return prompt


## Shown without a key when `can_interact` is false (for example "Welded
## shut"). Empty shows nothing.
func get_blocked_prompt(_player: PlayerCharacter) -> String:
	return ""


## Hold time for this player right now.
func get_hold_seconds(_player: PlayerCharacter) -> float:
	return hold_seconds


## Whether this player may use it right now.
func can_interact(_player: PlayerCharacter) -> bool:
	return enabled


## Prompt for using `item` on this, or "" if the item does nothing here.
func get_item_prompt(_player: PlayerCharacter, _item: ItemData) -> String:
	return ""


## Hold time for using `item` on this.
func get_item_seconds(_player: PlayerCharacter, _item: ItemData) -> float:
	return 0.0


## Called on the acting player's machine when the item hold completes. The
## host does it at once; a client asks the host (the node has the same path on
## every machine, so the RPC finds it).
func request_use_item(player: PlayerCharacter, hand: int) -> void:
	if multiplayer.is_server():
		_host_use_item(player, hand)
	else:
		_rpc_use_item.rpc_id(1, hand)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_use_item(hand: int) -> void:
	if not multiplayer.is_server():
		return
	var player := GameState.get_player_by_peer(multiplayer.get_remote_sender_id())
	if player != null and hand >= Inventory.MAIN_HAND and hand <= Inventory.OFF_HAND:
		_host_use_item(player, hand)


## Host only: checks the request and applies it.
func _host_use_item(player: PlayerCharacter, hand: int) -> void:
	var stack := player.inventory.hands[hand]
	if stack == null or player.is_dead or not _is_in_reach(player):
		return
	if get_item_prompt(player, stack.data).is_empty():
		return
	_on_item_used(player, stack.data, hand)
	item_used.emit(player, stack.data)


## Override in subclasses: what using the item here does.
func _on_item_used(_player: PlayerCharacter, _item: ItemData, _hand: int) -> void:
	pass


## Called on the acting player's machine when the hold completes.
func request_interact(player: PlayerCharacter) -> void:
	if multiplayer.is_server():
		_host_interact(player)
	else:
		_rpc_interact.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_interact() -> void:
	if not multiplayer.is_server():
		return
	var player := GameState.get_player_by_peer(multiplayer.get_remote_sender_id())
	if player != null:
		_host_interact(player)


## Host only: checks the request and applies it.
func _host_interact(player: PlayerCharacter) -> void:
	if player.is_dead or not can_interact(player) or not _is_in_reach(player):
		return
	if noise > 0.0:
		player.emit_noise(noise)
	_on_interact(player)
	interacted.emit(player)


## Override in subclasses: what the interaction does.
func _on_interact(_player: PlayerCharacter) -> void:
	pass


## Host only: turns this on or off for everyone.
func set_enabled_everywhere(value: bool) -> void:
	enabled = value
	if Net.is_networked():
		_rpc_set_enabled.rpc(value)


@rpc("authority", "call_remote", "reliable")
func _rpc_set_enabled(value: bool) -> void:
	enabled = value


func _is_in_reach(player: PlayerCharacter) -> bool:
	var reach := Config.tuning.interact_range + Config.tuning.interact_range_slack
	return player.head.global_position.distance_to(global_position) <= reach + _get_radius()


## Rough size of the interactable, so big ones can be used from their edge.
func _get_radius() -> float:
	for child: Node in get_children():
		var collider := child as CollisionShape3D
		if collider and collider.shape is BoxShape3D:
			return (collider.shape as BoxShape3D).size.length() * 0.5
	return 0.0
