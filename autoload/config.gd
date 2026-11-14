extends Node
## Global game configuration, available everywhere as `Config`.
##
## Example: `Config.tuning.walk_speed`
## Registered as an autoload in Project Settings > Globals.

const TUNING_PATH := "res://data/tuning.tres"

## All gameplay numbers. See res://scripts/data/tuning.gd.
var tuning: Tuning
## Room type id -> RoomType.
var room_types: Dictionary = {}
## Item id -> ItemData.
var items: Dictionary = {}


func _enter_tree() -> void:
	tuning = load(TUNING_PATH) as Tuning
	if tuning == null:
		push_error("Could not load %s; using default values." % TUNING_PATH)
		tuning = Tuning.new()
	room_types = load_by_id("res://data/rooms")
	items = load_by_id("res://data/items")
	InputSetup.ensure_default_actions()


## Loads every .tres in a folder into a dictionary keyed by its `id`.
func load_by_id(folder: String) -> Dictionary:
	var found := {}
	for file: String in ResourceLoader.list_directory(folder):
		if not file.ends_with(".tres"):
			continue
		var resource := load(folder.path_join(file))
		if resource and resource.get("id"):
			found[resource.get("id")] = resource
	return found


func get_room_type(id: StringName) -> RoomType:
	return room_types.get(id) as RoomType


func get_item(id: StringName) -> ItemData:
	return items.get(id) as ItemData
