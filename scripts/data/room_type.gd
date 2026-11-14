class_name RoomType
extends Resource
## One kind of room. One .tres per type in res://data/rooms/.

## Short id, for example &"medbay".
@export var id: StringName = &""
## Name shown to a player who steps inside.
@export var display_name: String = ""
## True for Bridge, Cryo Bay, the three engines and the Pod Bay.
@export var is_fixed: bool = false
## Shuffled rooms only: true if the room is in every match.
@export var is_essential: bool = false
## True for a plain room that fills a shuffled slot once every other room type
## has been placed (the ship has more slots than room types).
@export var is_filler: bool = false
## Search containers in the room (GDD: fixed rooms 1, shuffled 2-3,
## Storage 6).
@export var search_spots: int = 2
## The room's stations and props, authored around the middle of the floor
## (origin) with the ship's orientation. Any wall may have a doorway, so keep
## the lanes from the middle to the walls clear. May be empty.
@export var furnishing: PackedScene
## Colour of the room's light, so each room has a readable mood.
@export var light_color: Color = Color(0.7, 0.85, 1.0)
