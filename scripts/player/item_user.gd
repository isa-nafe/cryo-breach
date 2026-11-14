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
			_inventory.swap_hand_slot(Inventory.MAIN_HAND, _pending_slot)
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


## Drops whatever is in a hand onto the floor.
func request_drop(hand: int) -> void:
	# Phase 3: send an RPC to the host instead when not the server.
	_host_drop(hand)


## Uses a medkit or bandage on yourself.
func request_use_on_self(hand: int) -> void:
	# Phase 3: send an RPC to the host instead when not the server.
	_host_use_on_self(hand)


## Reloads the gun in a hand from an ammo box.
func request_reload(hand: int) -> void:
	# Phase 3: send an RPC to the host instead when not the server.
	_host_reload(hand)


## Host only: puts a stack on the floor in front of the player.
func drop_stack(stack: ItemStack) -> void:
	var forward := -_player.global_basis.z
	forward.y = 0.0
	var at := _player.global_position + forward.normalized() * Config.tuning.drop_distance
	Pickup.spawn(get_tree(), stack, at)


func _host_drop(hand: int) -> void:
	if _player.is_dead:
		return
	var stack := _inventory.take_from_hand(hand)
	if stack:
		drop_stack(stack)


func _host_use_on_self(hand: int) -> void:
	var stack := _inventory.hands[hand]
	if stack == null or _player.is_dead:
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
	if _player.is_dead or _find_reloadable_hand() != hand:
		return
	var stack := _inventory.hands[hand]
	stack.charges = stack.data.weapon.capacity
	# Using the box up changes the inventory, which refreshes the gun view.
	_inventory.consume(&"ammo_box")


func _handle_buttons(input: InputState) -> void:
	if input.slot_press > 0 and input.slot_press <= _inventory.slots.size():
		_pending_slot = input.slot_press - 1
		_swap_timer = Config.tuning.hand_slot_swap_seconds
	elif input.swap_hands:
		_inventory.swap_hands()
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
				weapon.update_trigger(held, _player, delta)
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


## Rebuilds what is shown in the hands after any inventory change.
func _refresh_views() -> void:
	for hand in 2:
		var old := _views[hand]
		if old:
			old.visible = false
			old.queue_free()
			_views[hand] = null
		var stack := _inventory.hands[hand]
		if stack == null:
			continue
		var view := _make_view(stack)
		_hand_nodes[hand].add_child(view)
		_views[hand] = view
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
	hit_confirmed.emit(killed)
