class_name ShipLayout
extends Resource
## The sizes of the Meridian's walls, doors and corridors, plus helpers for
## reading the layout data (ShipLayoutData): 21 rooms of different shapes
## joined by 28 corridors, laid out like the owner's ship diagram (decision
## D22). Fore is -X.

## Height of a room.
@export var room_height: float = 3.5
@export var wall_thickness: float = 0.2
## Width of a doorway and of the corridors.
@export var door_width: float = 2.0
## Height of a doorway and of the corridors.
@export var door_height: float = 2.4
## Brightness of the one light in each room and corridor.
@export var light_energy: float = 1.0


## The slot with this id, or an empty dictionary.
func get_slot(slot_id: StringName) -> Dictionary:
	for slot: Dictionary in ShipLayoutData.SLOTS:
		if slot.id == slot_id:
			return slot
	return {}


## Middle of a slot's floor.
func get_slot_center(slot: Dictionary) -> Vector3:
	var pos: Vector2 = slot.pos
	return Vector3(pos.x, 0.0, pos.y)


## The corners of a slot's room (clockwise seen from above), around its middle.
func get_shape(slot: Dictionary) -> PackedVector2Array:
	return PackedVector2Array(ShipLayoutData.SHAPES[slot.shape])


## Power section of a corridor: the section of both ends if they match,
## otherwise the section of the end nearer the front of the ship.
func get_link_section(a_id: StringName, b_id: StringName) -> String:
	var a := get_slot(a_id)
	var b := get_slot(b_id)
	var a_pos: Vector2 = a.pos
	var b_pos: Vector2 = b.pos
	var section: String = a.section
	if a.section != b.section and b_pos.x < a_pos.x:
		section = b.section
	return section
