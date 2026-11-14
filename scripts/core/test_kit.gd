class_name TestKit
extends RefCounted
## Temporary gear for testing before roles exist (M5.1 removes this).


## Gives the player a pistol.
static func give(player: PlayerCharacter) -> void:
	player.inventory.add(ItemStack.create(Config.get_item(&"pistol")))


## Drops a row of items on the floor around `center` (a point on the floor).
static func scatter(tree: SceneTree, center: Vector3) -> void:
	var ids: Array[StringName] = [
		&"ammo_box", &"ammo_box", &"medkit", &"bandage", &"bandage", &"bandage",
		&"keycard", &"welder",
	]
	for i in ids.size():
		var stack := ItemStack.create(Config.get_item(ids[i]))
		Pickup.spawn(tree, stack, center + Vector3(-1.8 + 0.45 * i, 0.0, -1.5))
