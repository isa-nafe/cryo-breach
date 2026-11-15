class_name Inventory
extends Node
## What a player carries: 2 hands and a few slots (GDD "Inventory").
##
## A two-handed item sits in hand 0 and blocks hand 1. Only the host
## changes an inventory; the owner gets a copy (Phase 3).

## Emitted after any change.
signal changed

const MAIN_HAND := 0
const OFF_HAND := 1

## Hand contents; null = empty.
var hands: Array[ItemStack] = [null, null]
## Slot contents; null = empty.
var slots: Array[ItemStack] = []
## 1 with a broken arm, otherwise 2 (set from PlayerWounds).
var usable_hands: int = 2


func _ready() -> void:
	slots.resize(Config.tuning.inventory_slots)


## True if nothing is in the hand and nothing blocks it.
func is_hand_free(hand: int) -> bool:
	if hand >= usable_hands or hands[hand] != null:
		return false
	return not (hand == OFF_HAND and _holds_two_handed())


## True if `add` would take at least part of this stack.
func can_accept(stack: ItemStack) -> bool:
	if stack.data.stack_limit > 1:
		for existing: ItemStack in get_all_stacks():
			if existing.data.id == stack.data.id and existing.count < existing.data.stack_limit:
				return true
	if stack.data.two_handed:
		return is_hand_free(MAIN_HAND) and is_hand_free(OFF_HAND)
	for hand in hands.size():
		if is_hand_free(hand):
			return true
	return slots.has(null)


## Puts a stack into the inventory: tops up matching stacks first, then a
## free hand, then a free slot. Returns true if all of it fitted. If only
## part fitted, `stack.count` is what is left over.
func add(stack: ItemStack) -> bool:
	if stack.data.stack_limit > 1:
		_merge_into_existing(stack)
		if stack.count <= 0:
			changed.emit()
			return true
	if stack.data.two_handed:
		if not (is_hand_free(MAIN_HAND) and is_hand_free(OFF_HAND)):
			return false
		hands[MAIN_HAND] = stack
		changed.emit()
		return true
	for hand in hands.size():
		if is_hand_free(hand):
			hands[hand] = stack
			changed.emit()
			return true
	var slot := slots.find(null)
	if slot == -1:
		changed.emit()
		return false
	slots[slot] = stack
	changed.emit()
	return true


## Swaps a hand with a slot. Two-handed items cannot be stowed.
func swap_hand_slot(hand: int, slot: int) -> bool:
	if hand >= usable_hands or (hand == OFF_HAND and _holds_two_handed()):
		return false
	if hands[hand] != null and hands[hand].data.two_handed:
		return false
	var from_slot := slots[slot]
	slots[slot] = hands[hand]
	hands[hand] = from_slot
	changed.emit()
	return true


func swap_hands() -> bool:
	if usable_hands < 2 or _holds_two_handed():
		return false
	var main := hands[MAIN_HAND]
	hands[MAIN_HAND] = hands[OFF_HAND]
	hands[OFF_HAND] = main
	changed.emit()
	return true


## Empties a hand and returns what was in it (for dropping).
func take_from_hand(hand: int) -> ItemStack:
	var stack := hands[hand]
	hands[hand] = null
	if stack:
		changed.emit()
	return stack


## Uses up one item from a hand's stack.
func consume_from_hand(hand: int) -> void:
	var stack := hands[hand]
	if stack == null:
		return
	stack.count -= 1
	if stack.count <= 0:
		hands[hand] = null
	changed.emit()


## True if a hand holds this item (keycard, welder, toolkit checks).
func holds(id: StringName) -> bool:
	for stack: ItemStack in hands:
		if stack != null and stack.data.id == id:
			return true
	return false


## How many of an item are carried anywhere.
func count_of(id: StringName) -> int:
	var total := 0
	for stack: ItemStack in get_all_stacks():
		if stack.data.id == id:
			total += stack.count
	return total


## Removes `amount` of an item from anywhere. False if there are too few.
func consume(id: StringName, amount: int = 1) -> bool:
	if count_of(id) < amount:
		return false
	var left := amount
	for list: Array[ItemStack] in [hands, slots]:
		for i in list.size():
			var stack := list[i]
			if stack == null or stack.data.id != id or left <= 0:
				continue
			var used := mini(stack.count, left)
			stack.count -= used
			left -= used
			if stack.count <= 0:
				list[i] = null
	changed.emit()
	return true


## Every stack carried, hands first.
func get_all_stacks() -> Array[ItemStack]:
	var all: Array[ItemStack] = []
	for stack: ItemStack in hands + slots:
		if stack != null:
			all.append(stack)
	return all


## Broken arm: sets the usable hands and returns what must be dropped.
func set_usable_hands(count: int) -> Array[ItemStack]:
	usable_hands = count
	var dropped: Array[ItemStack] = []
	if count < 2:
		if _holds_two_handed():
			dropped.append(take_from_hand(MAIN_HAND))
		elif hands[OFF_HAND] != null:
			dropped.append(take_from_hand(OFF_HAND))
	return dropped


func _holds_two_handed() -> bool:
	return hands[MAIN_HAND] != null and hands[MAIN_HAND].data.two_handed


func _merge_into_existing(stack: ItemStack) -> void:
	for existing: ItemStack in get_all_stacks():
		if existing.data.id != stack.data.id:
			continue
		var room := existing.data.stack_limit - existing.count
		var moved := mini(room, stack.count)
		existing.count += moved
		stack.count -= moved
		if stack.count <= 0:
			return


## A copy of everything carried, for sending to the owner (Phase 3).
func to_dict() -> Dictionary:
	var hand_list: Array = []
	for stack: ItemStack in hands:
		hand_list.append(stack.to_dict() if stack != null else null)
	var slot_list: Array = []
	for stack: ItemStack in slots:
		slot_list.append(stack.to_dict() if stack != null else null)
	return {"hands": hand_list, "slots": slot_list, "usable_hands": usable_hands}


## Replaces everything carried with a copy from the host.
func apply_dict(state: Dictionary) -> void:
	usable_hands = state["usable_hands"]
	for i in hands.size():
		hands[i] = _stack_from(state["hands"][i])
	for i in slots.size():
		slots[i] = _stack_from(state["slots"][i])
	changed.emit()


func _stack_from(entry: Variant) -> ItemStack:
	if entry == null:
		return null
	return ItemStack.from_dict(entry)
