class_name ItemStack
extends RefCounted
## One hand or slot's contents: an item type, how many, and its charges.

var data: ItemData
var count: int = 1
## Rounds, charges or uses left (weapons, scanner, extinguisher...).
var charges: int = 0


static func create(item: ItemData, amount: int = 1) -> ItemStack:
	var stack := ItemStack.new()
	stack.data = item
	stack.count = amount
	stack.charges = item.max_charges
	return stack


## For sending over the network (Phase 3).
func to_dict() -> Dictionary:
	return {"id": data.id, "count": count, "charges": charges}


static func from_dict(dict: Dictionary) -> ItemStack:
	var stack := ItemStack.new()
	stack.data = Config.get_item(StringName(dict.id))
	stack.count = dict.count
	stack.charges = dict.charges
	return stack
