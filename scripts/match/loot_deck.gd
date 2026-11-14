class_name LootDeck
extends RefCounted
## The shared, hidden deck that search containers draw from. Host only.

var _cards: Array[StringName] = []


## Fills and shuffles the deck. `extra` holds cards added by the GDD's
## "missing role" rules (keycard, toolkit, radio). Items that do not exist
## yet in res://data/items are left out.
func setup(table: LootTable, player_count: int, extra: Array[StringName] = []) -> void:
	_cards.clear()
	var column := LootTable.column_for(player_count)
	for id: StringName in table.cards:
		var counts: PackedInt32Array = table.cards[id]
		for _i in counts[column]:
			_add_card(id)
	for id: StringName in extra:
		_add_card(id)
	_cards.shuffle()


## Takes the top card. Returns &"" when the deck is empty.
func draw() -> StringName:
	if _cards.is_empty():
		return &""
	return _cards.pop_back()


func get_size() -> int:
	return _cards.size()


func _add_card(id: StringName) -> void:
	if Config.get_item(id) != null:
		_cards.append(id)
