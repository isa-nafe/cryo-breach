class_name LootTable
extends Resource
## How many of each loot card are in the deck (GDD "Searching" table).

## Item id -> counts for [3 players, 4-5 players, 6 players].
@export var cards: Dictionary = {
	&"ammo_box": PackedInt32Array([4, 4, 5]),
	&"medkit": PackedInt32Array([2, 2, 2]),
	&"bandage": PackedInt32Array([2, 2, 3]),
	&"chemicals": PackedInt32Array([2, 2, 3]),
	&"rag": PackedInt32Array([1, 2, 2]),
	&"duct_tape": PackedInt32Array([2, 3, 3]),
	&"pipe": PackedInt32Array([1, 2, 2]),
	&"battery": PackedInt32Array([2, 2, 3]),
	&"grenade": PackedInt32Array([1, 1, 1]),
	&"keycard": PackedInt32Array([1, 1, 1]),
	&"toolkit": PackedInt32Array([1, 1, 1]),
	&"extinguisher": PackedInt32Array([1, 2, 2]),
	&"o2_mask": PackedInt32Array([1, 1, 1]),
	&"flashlight": PackedInt32Array([1, 1, 1]),
}


## Column of the table for a player count.
static func column_for(player_count: int) -> int:
	if player_count <= 3:
		return 0
	if player_count <= 5:
		return 1
	return 2
