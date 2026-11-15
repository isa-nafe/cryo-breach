class_name ItemUser
extends Node
## Everything a player does with items: the two hand buttons, swapping,
## dropping, reloading and showing what is in each hand.
## Child of the player, named "ItemUser". Needs sibling "Inventory" and
## the Node3Ds "Head/Camera3D/HandMain" and "Head/Camera3D/HandOff".
##
## Hand buttons: left mouse = main hand, right mouse = off hand. A hand
## first tries the item on what you are looking at (a welder on a door),
## then the item's own use (shoot, medkit).

## Emitted when a shot from either hand hits an alien.
signal hit_confirmed(killed: bool)

## Size and place of the grey box shown for items without their own model.
const VIEW_BOX_SIZE := Vector3(0.1, 0.1, 0.25)
const VIEW_OFFSET := Vector3(0.22, -0.2, -0.45)

## Progress from 0 to 1 of a timed item action, for the HUD bar.
var hold_fraction: float = 0.0

var _player: PlayerCharacter
var _inventory: Inventory
var _hand_nodes: Array[Node3D] = []
var _views: Array[Node3D] = [null, null]
var _view_ids: Array[StringName] = [&"", &""]
var _last_fire_msec: Array[int] = [0, 0]
var _holds: Array[HoldAction] = [HoldAction.new(), HoldAction.new()]
var _reload_hold := HoldAction.new()
var _swap_timer := 0.0
var _pending_slot := -1


func _ready() -> void:
	_player = get_parent() as PlayerCharacter
	_inventory = _player.get_node("Inventory") as Inventory
	_hand_nodes = [
		_player.get_node("Head/Camera3D/HandMain") as Node3D,
		_player.get_node("Head/Camera3D/HandOff") as Node3D,
	]
	_inventory.changed.connect(_refresh_views)
	_refresh_views()


## Call every physics frame from the character.
func update(input: InputState, delta: float) -> void:
	hold_fraction = 0.0
	if _swap_timer > 0.0:
		hold_fraction = 1.0 - _swap_timer / Config.tuning.hand_slot_swap_seconds
		_swap_timer -= delta
		if _swap_timer <= 0.0:
			request_swap_hand_slot(Inventory.MAIN_HAND, _pending_slot)
		return
	_handle_buttons(input)
	if _swap_timer > 0.0:
		return
	_update_hand(Inventory.MAIN_HAND, input.fire, delta)
	_update_hand(Inventory.OFF_HAND, input.fire_off, delta)
	_update_reload(input.reload_held, delta)


## The gun in the main hand, or null.
func get_main_weapon() -> HitscanWeapon:
	return _views[Inventory.MAIN_HAND] as HitscanWeapon


## Every request below does its work on the host. On the host (and in solo
## play) it runs at once; on a client it is sent to the host, which checks it
## came from this character's owner and that it makes sense.


## Drops whatever is in a hand onto the floor.
func request_drop(hand: int) -> void:
	if multiplayer.is_server():
		_host_drop(hand)
	else:
		_rpc_drop.rpc_id(1, hand)


## Uses a medkit or bandage on yourself.
func request_use_on_self(hand: int) -> void:
	if multiplayer.is_server():
		_host_use_on_self(hand)
	else:
		_rpc_use_on_self.rpc_id(1, hand)


## Reloads the gun in a hand from an ammo box.
func request_reload(hand: int) -> void:
	if multiplayer.is_server():
		_host_reload(hand)
	else:
		_rpc_reload.rpc_id(1, hand)


## Swaps a hand with a slot.
func request_swap_hand_slot(hand: int, slot: int) -> void:
	if multiplayer.is_server():
		_host_swap_hand_slot(hand, slot)
	else:
		_rpc_swap_hand_slot.rpc_id(1, hand, slot)


## Swaps the main and off hand.
func request_swap_hands() -> void:
	if multiplayer.is_server():
		_host_swap_hands()
	else:
		_rpc_swap_hands.rpc_id(1)


## Fires the gun in a hand along these directions. On a client this is a
## request; the host checks it before it counts.
func request_fire(hand: int, origin: Vector3, directions: PackedVector3Array) -> void:
	if multiplayer.is_server():
		_host_fire(hand, origin, directions)
	else:
		_rpc_fire.rpc_id(1, hand, origin, directions)


## Host only: puts a stack on the floor in front of the player.
func drop_stack(stack: ItemStack) -> void:
	var forward := -_player.global_basis.z
	forward.y = 0.0
	var at := _player.global_position + forward.normalized() * Config.tuning.drop_distance
	Pickup.spawn(get_tree(), stack, at)


func _host_drop(hand: int) -> void:
	if _player.is_dead or not _is_hand(hand):
		return
	var stack := _inventory.take_from_hand(hand)
	if stack:
		drop_stack(stack)


func _host_use_on_self(hand: int) -> void:
	if _player.is_dead or not _is_hand(hand):
		return
	var stack := _inventory.hands[hand]
	if stack == null:
		return
	var used := false
	match stack.data.use_kind:
		ItemData.UseKind.HEAL_LIGHT:
			if _player.wounds.light_wounds > 0:
				_player.wounds.heal_light()
				used = true
		ItemData.UseKind.DRESS_WOUND:
			used = _player.wounds.dress_one()
	if used and stack.data.consumed_on_use:
		_inventory.consume_from_hand(hand)


func _host_reload(hand: int) -> void:
	if _player.is_dead or not _is_hand(hand) or _find_reloadable_hand() != hand:
		return
	var stack := _inventory.hands[hand]
	stack.charges = stack.data.weapon.capacity
	# Using the box up changes the inventory, which refreshes the gun view.
	_inventory.consume(&"ammo_box")


func _host_swap_hand_slot(hand: int, slot: int) -> void:
	if _player.is_dead or not _is_hand(hand) or slot < 0 or slot >= _inventory.slots.size():
		return
	_inventory.swap_hand_slot(hand, slot)


func _host_swap_hands() -> void:
	if not _player.is_dead:
		_inventory.swap_hands()


func _host_fire(hand: int, origin: Vector3, directions: PackedVector3Array) -> void:
	if _player.is_dead or not _is_hand(hand):
		return
	var stack := _inventory.hands[hand]
	var weapon := _views[hand] as HitscanWeapon
	if stack == null or weapon == null or stack.charges <= 0:
		return
	if stack.data.use_kind != ItemData.UseKind.HITSCAN:
		return
	var tuning := Config.tuning
	# Do not trust the client blindly: right rate, right place, right pellets.
	var now := Time.get_ticks_msec()
	var min_gap := int(weapon.data.fire_interval * tuning.fire_rate_tolerance * 1000.0)
	if now - _last_fire_msec[hand] < min_gap:
		return
	if origin.distance_to(_player.camera.global_position) > tuning.fire_origin_tolerance:
		return
	if directions.size() != weapon.data.pellets:
		return
	_last_fire_msec[hand] = now
	weapon.apply_shot(_player, origin, directions)
	# Ammo is not an inventory "change" by itself; tell the owner the new count.
	_inventory.changed.emit()
	_player.broadcast_shot_effects()


## Host only: a shot fired from this machine's own gun.
func _fire_local(hand: int, weapon: HitscanWeapon, directions: PackedVector3Array) -> void:
	var origin := _player.camera.global_position
	if multiplayer.is_server():
		weapon.apply_shot(_player, origin, directions)
		weapon.show_effects()
		_player.broadcast_shot_effects()
	else:
		request_fire(hand, origin, directions)


func _is_hand(hand: int) -> bool:
	return hand >= Inventory.MAIN_HAND and hand <= Inventory.OFF_HAND


## True when an RPC on this node came from the owner of this character and
## arrived at the host.
func _is_owner_request() -> bool:
	return multiplayer.is_server() and multiplayer.get_remote_sender_id() == _player.peer_id


@rpc("any_peer", "call_remote", "reliable")
func _rpc_drop(hand: int) -> void:
	if _is_owner_request():
		_host_drop(hand)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_use_on_self(hand: int) -> void:
	if _is_owner_request():
		_host_use_on_self(hand)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_reload(hand: int) -> void:
	if _is_owner_request():
		_host_reload(hand)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_swap_hand_slot(hand: int, slot: int) -> void:
	if _is_owner_request():
		_host_swap_hand_slot(hand, slot)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_swap_hands() -> void:
	if _is_owner_request():
		_host_swap_hands()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_fire(hand: int, origin: Vector3, directions: PackedVector3Array) -> void:
	if _is_owner_request():
		_host_fire(hand, origin, directions)


## Host to owner: your shot hit something (for the hit marker).
@rpc("authority", "call_remote", "reliable")
func _rpc_hit_confirmed(killed: bool) -> void:
	hit_confirmed.emit(killed)


func _handle_buttons(input: InputState) -> void:
	if input.slot_press > 0 and input.slot_press <= _inventory.slots.size():
		_pending_slot = input.slot_press - 1
		_swap_timer = Config.tuning.hand_slot_swap_seconds
	elif input.swap_hands:
		request_swap_hands()
	elif input.drop:
		request_drop(Inventory.MAIN_HAND)


func _update_hand(hand: int, held: bool, delta: float) -> void:
	var stack := _inventory.hands[hand]
	var hold := _holds[hand]
	if stack == null:
		hold.update(false, null, 0.0, delta)
		return
	var item := stack.data
	var focus := _player.interactor.focused
	if focus != null and not focus.get_item_prompt(_player, item).is_empty():
		var seconds := focus.get_item_seconds(_player, item)
		if hold.update(held, focus, seconds, delta):
			focus.request_use_item(_player, hand)
		_show_progress(hold, seconds)
		return
	match item.use_kind:
		ItemData.UseKind.HITSCAN:
			hold.update(false, null, 0.0, delta)
			var weapon := _views[hand] as HitscanWeapon
			if weapon:
				var directions := weapon.update_trigger(held, _player, delta)
				if not directions.is_empty():
					_fire_local(hand, weapon, directions)
		ItemData.UseKind.HEAL_LIGHT, ItemData.UseKind.DRESS_WOUND:
			if hold.update(held, stack, item.use_seconds, delta):
				request_use_on_self(hand)
			_show_progress(hold, item.use_seconds)
		_:
			hold.update(false, null, 0.0, delta)


func _update_reload(held: bool, delta: float) -> void:
	var hand := _find_reloadable_hand()
	var target: Variant = hand if hand != -1 else null
	var seconds := Config.tuning.ammo_reload_seconds
	if _reload_hold.update(held, target, seconds, delta):
		request_reload(hand)
	_show_progress(_reload_hold, seconds)


## The hand holding a gun that is not full, if an ammo box is carried.
func _find_reloadable_hand() -> int:
	if _inventory.count_of(&"ammo_box") <= 0:
		return -1
	for hand in 2:
		var stack := _inventory.hands[hand]
		if stack == null or stack.data.weapon == null:
			continue
		if stack.data.use_kind == ItemData.UseKind.HITSCAN:
			if stack.charges < stack.data.weapon.capacity:
				return hand
	return -1


func _show_progress(hold: HoldAction, seconds: float) -> void:
	if hold.progress > 0.0:
		hold_fraction = maxf(hold_fraction, hold.get_fraction(seconds))


## Updates what is shown in the hands after any inventory change. A hand that
## still holds the same kind of item keeps its view (so a gun keeps its trigger
## state); it only reloads the item's numbers.
func _refresh_views() -> void:
	for hand in 2:
		var stack := _inventory.hands[hand]
		var old := _views[hand]
		if stack != null and old != null and _view_ids[hand] == stack.data.id:
			var kept := old as HitscanWeapon
			if kept:
				kept.bind_stack(stack)
			continue
		if old:
			old.visible = false
			old.queue_free()
			_views[hand] = null
		_view_ids[hand] = &""
		if stack == null:
			continue
		var view := _make_view(stack)
		_hand_nodes[hand].add_child(view)
		_views[hand] = view
		_view_ids[hand] = stack.data.id
		var weapon := view as HitscanWeapon
		if weapon:
			weapon.bind_stack(stack)
			weapon.hit_confirmed.connect(_on_weapon_hit)


func _make_view(stack: ItemStack) -> Node3D:
	if stack.data.view_scene:
		return stack.data.view_scene.instantiate() as Node3D
	var holder := Node3D.new()
	var mesh := BoxMesh.new()
	mesh.size = VIEW_BOX_SIZE
	var material := StandardMaterial3D.new()
	material.albedo_color = stack.data.color
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = VIEW_OFFSET
	holder.add_child(visual)
	return holder


func _on_weapon_hit(killed: bool) -> void:
	if _player.is_local():
		hit_confirmed.emit(killed)
	elif multiplayer.is_server():
		# The shooter is on another machine: tell them for the hit marker.
		_rpc_hit_confirmed.rpc_id(_player.peer_id, killed)
