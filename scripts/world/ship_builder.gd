class_name ShipBuilder
extends Node3D
## Builds the whole ship out of boxes and prisms from a ShipLayout, the layout
## data (ShipLayoutData) and a room assignment. Runs on every peer with the
## same assignment, so everyone gets the same ship.
##
## Each room is a Node3D named "Room_<slot>" at the middle of the room, in the
## same orientation as the ship (it is not turned). Its shape is a convex
## polygon from the data (a hexagon, a long engine room, the oval Cryo Bay...).
## Each corridor is a Node3D named "Link_<a>_<b>" made of straight pieces that
## meet at bends; it has a door in the middle of its longest piece.

## Walls, floors and furnishings are in this group so the navigation bake
## sees them, and nothing else (doors, pickups and lights are left out).
const NAV_GROUP := &"nav_source"

## Ceilings are in this group so the debug overview camera can hide them.
const CEILING_GROUP := &"ceilings"

## How far from a wall a search container stands, in metres.
const SPOT_WALL_MARGIN := 0.8

## A wall shorter than this does not get a search container.
const MIN_SPOT_WALL := 2.5

## Spare room (metres) a furnishing's top-level parts must have from the walls.
const FURNISHING_MARGIN := 0.3

## Where a corridor's container stands in its longest piece: sideways from the
## middle, and along the piece as a fraction of its length.
const LINK_SPOT_SIDEWAYS := 0.5
const LINK_SPOT_ALONG := 0.25

## The ship's sizes.
@export var layout: ShipLayout

## Slot id -> the Zone built for that room.
var room_zones: Dictionary = {}
## Corridor zones, in the order of ShipLayoutData.LINKS.
var corridor_zones: Array[Zone] = []
## "link_<a>_<b>" -> the Zone of that corridor.
var link_zones: Dictionary = {}
## Slot id -> the furnishing node instanced in that room.
var furnishings: Dictionary = {}

var _wall_material := StandardMaterial3D.new()
var _floor_material := StandardMaterial3D.new()
var _slab_material := StandardMaterial3D.new()


## Builds everything. `assignment` maps slot id -> room type id; a slot
## that is missing from it is sealed, and so are the corridors to it.
func build(assignment: Dictionary) -> void:
	_wall_material.albedo_color = Color(0.55, 0.58, 0.62)
	_wall_material.roughness = 0.85
	_floor_material.albedo_color = Color(0.3, 0.32, 0.36)
	_floor_material.roughness = 0.9
	# Room slabs are drawn from both sides, so triangle winding is moot.
	_slab_material.albedo_color = _floor_material.albedo_color
	_slab_material.roughness = 0.9
	_slab_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var door_walls := _get_door_walls(assignment)
	for slot: Dictionary in ShipLayoutData.SLOTS:
		if assignment.has(slot.id):
			var type := Config.get_room_type(assignment[slot.id])
			_build_room(slot, type, door_walls.get(slot.id, []))
	var number := 0
	for link: Dictionary in ShipLayoutData.LINKS:
		number += 1
		if assignment.has(link.a) and assignment.has(link.b):
			_build_link(link, number)
	_link_neighbours()


## Slot id -> the walls of that room that have a doorway.
func _get_door_walls(assignment: Dictionary) -> Dictionary:
	var walls := {}
	for link: Dictionary in ShipLayoutData.LINKS:
		if not (assignment.has(link.a) and assignment.has(link.b)):
			continue
		_add_door_wall(walls, link.a, link.wall_a)
		_add_door_wall(walls, link.b, link.wall_b)
	return walls


func _add_door_wall(walls: Dictionary, slot_id: StringName, wall: int) -> void:
	var list: Array = walls.get(slot_id, [])
	list.append(wall)
	walls[slot_id] = list


func _build_room(slot: Dictionary, type: RoomType, door_walls: Array) -> void:
	var thickness := layout.wall_thickness
	var polygon := layout.get_shape(slot)
	var room := Node3D.new()
	room.name = "Room_%s" % slot.id
	room.position = layout.get_slot_center(slot)
	room.add_to_group(NAV_GROUP)
	add_child(room)
	_add_slab(room, polygon, -thickness, 0.0)
	_add_slab(room, polygon, layout.room_height, layout.room_height + thickness)
	for k in RoomGeometry.wall_count(polygon):
		_build_wall(room, polygon, k, k in door_walls)
	var zone := _add_room_zone(room, polygon)
	zone.zone_name = type.display_name
	zone.kind = "Room"
	zone.power_section = slot.section
	zone.slot_id = slot.id
	zone.room_type = type
	room_zones[slot.id] = zone
	_place_room_spots(slot, room, polygon, type.search_spots, door_walls)
	var light_at := Vector3(0.0, layout.room_height - 0.4, 0.0)
	var light_range := RoomGeometry.get_radius(polygon) * 1.6
	_add_light(room, light_at, light_range, type.light_color)
	if type.furnishing:
		var furnishing := type.furnishing.instantiate() as Node3D
		room.add_child(furnishing)
		furnishings[slot.id] = furnishing
		_warn_if_outside(furnishing, polygon)


## One wall of a room, optionally with a doorway in the middle. The wall is
## built in its own frame: along X, with Z pointing out of the room.
func _build_wall(room: Node3D, polygon: PackedVector2Array, k: int, with_door: bool) -> void:
	var thickness := layout.wall_thickness
	var height := layout.room_height
	var middle := RoomGeometry.wall_middle(polygon, k)
	var normal := RoomGeometry.wall_normal(polygon, k)
	var tangent := RoomGeometry.wall_tangent(polygon, k)
	var wall := Node3D.new()
	wall.name = "Wall_%d" % k
	var outward := middle + normal * thickness * 0.5
	wall.position = Vector3(outward.x, 0.0, outward.y)
	wall.rotation.y = atan2(-tangent.y, tangent.x)
	room.add_child(wall)
	# A little longer than the wall so neighbouring walls overlap at corners.
	var half := RoomGeometry.wall_length(polygon, k) * 0.5
	var start := -(half + RoomGeometry.corner_overlap(polygon, k, thickness))
	var corner_after := (k + 1) % polygon.size()
	var end := half + RoomGeometry.corner_overlap(polygon, corner_after, thickness)
	if not with_door:
		var solid_size := Vector3(end - start, height, thickness)
		_box(wall, Vector3((start + end) * 0.5, height * 0.5, 0.0), solid_size, _wall_material)
		return
	var half_door := layout.door_width * 0.5
	var left_size := Vector3(-half_door - start, height, thickness)
	var left_center := Vector3((start - half_door) * 0.5, height * 0.5, 0.0)
	_box(wall, left_center, left_size, _wall_material)
	var right_size := Vector3(end - half_door, height, thickness)
	var right_center := Vector3((end + half_door) * 0.5, height * 0.5, 0.0)
	_box(wall, right_center, right_size, _wall_material)
	var lintel_height := height - layout.door_height
	var lintel_center := Vector3(0.0, layout.door_height + lintel_height * 0.5, 0.0)
	var lintel_size := Vector3(layout.door_width, lintel_height, thickness)
	_box(wall, lintel_center, lintel_size, _wall_material)


## One corridor between two rooms: straight pieces joined at bends, each with a
## floor, ceiling and two walls; one zone; a door in the middle of its longest
## piece; a search container and a light.
func _build_link(link: Dictionary, number: int) -> void:
	var thickness := layout.wall_thickness
	var width := layout.door_width
	var height := layout.door_height
	# Walls stand just outside the passage, so the bends are cut from there.
	var wall_offset := width * 0.5 + thickness * 0.5
	var path := _get_link_path(link)
	var piece_count := path.size() - 1
	var link_node := Node3D.new()
	link_node.name = "Link_%s_%s" % [link.a, link.b]
	link_node.add_to_group(NAV_GROUP)
	add_child(link_node)
	var zone := Zone.new()
	zone.collision_layer = 0
	zone.collision_mask = Layers.PLAYERS | Layers.ALIENS
	add_child(zone)
	var longest := 0
	var longest_length := 0.0
	for i in piece_count:
		var direction := (path[i + 1] - path[i]).normalized()
		var piece_length := path[i].distance_to(path[i + 1])
		if piece_length > longest_length:
			longest = i
			longest_length = piece_length
		# A bend cuts the inner walls short and pushes the outer ones past the
		# joint, so the two pieces' walls meet in a clean corner.
		var left_start := 0.0
		var right_start := 0.0
		var left_end := piece_length
		var right_end := piece_length
		var floor_start := 0.0
		var floor_end := 0.0
		if i > 0:
			var turn := (path[i] - path[i - 1]).normalized().signed_angle_to(direction, Vector3.UP)
			var cut := wall_offset * tan(absf(turn) * 0.5)
			left_start = cut if turn > 0.0 else -cut
			right_start = -left_start
			floor_start = wall_offset
		if i < piece_count - 1:
			var next_direction := (path[i + 2] - path[i + 1]).normalized()
			var turn_after := direction.signed_angle_to(next_direction, Vector3.UP)
			var cut_after := wall_offset * tan(absf(turn_after) * 0.5)
			left_end = piece_length - cut_after if turn_after > 0.0 else piece_length + cut_after
			right_end = piece_length + piece_length - left_end
			floor_end = wall_offset
		var yaw := atan2(direction.x, direction.z)
		var piece := Node3D.new()
		piece.name = "Piece_%d" % i
		piece.position = path[i]
		piece.rotation.y = yaw
		link_node.add_child(piece)
		# Local +Z runs along the piece and local +X is to the traveller's left.
		var slab_length := piece_length + floor_start + floor_end
		var slab_middle := (piece_length + floor_end - floor_start) * 0.5
		var slab_size := Vector3(width + 2.0 * thickness, thickness, slab_length)
		_box(piece, Vector3(0.0, -thickness * 0.5, slab_middle), slab_size, _floor_material)
		var ceiling_at := Vector3(0.0, height + thickness * 0.5, slab_middle)
		_box(piece, ceiling_at, slab_size, _wall_material).add_to_group(CEILING_GROUP)
		_add_corridor_wall(piece, wall_offset, left_start, left_end, height)
		_add_corridor_wall(piece, -wall_offset, right_start, right_end, height)
		var piece_basis := Basis(Vector3.UP, yaw)
		var shape := BoxShape3D.new()
		shape.size = Vector3(width, height, slab_length)
		var collider := CollisionShape3D.new()
		collider.shape = shape
		var local_middle := Vector3(0.0, height * 0.5, slab_middle)
		collider.transform = Transform3D(piece_basis, path[i] + piece_basis * local_middle)
		zone.add_child(collider)
	GameState.register_zone(zone)
	zone.zone_name = "Corridor %d" % number
	zone.kind = "Corridor"
	zone.power_section = layout.get_link_section(link.a, link.b)
	zone.slot_id = StringName("link_%s_%s" % [link.a, link.b])
	link_zones[zone.slot_id] = zone
	corridor_zones.append(zone)
	# The door goes in the middle of the longest piece.
	var long_direction := (path[longest + 1] - path[longest]).normalized()
	var long_yaw := atan2(long_direction.x, long_direction.z)
	var middle := path[longest] + long_direction * longest_length * 0.5
	var door := Door.create(layout.door_width, layout.door_height, thickness, true)
	# A fixed name, so the same door has the same path on every machine.
	door.name = "Door_%s_%s" % [link.a, link.b]
	door.position = middle
	door.rotation.y = long_yaw
	add_child(door)
	zone.door = door
	var long_piece := link_node.get_child(longest) as Node3D
	var spot_at := Vector3(LINK_SPOT_SIDEWAYS, 0.0, longest_length * LINK_SPOT_ALONG)
	_add_spot(long_piece, "Search_%s" % link_node.name, spot_at)
	var light_at := Vector3(0.0, height - 0.3, longest_length * 0.5)
	_add_light(long_piece, light_at, maxf(longest_length * 1.5, 4.0), Color(0.6, 0.7, 0.85))


## The points a corridor passes through: the door of its first room, the
## bends, then the door of its second room (all on the floor).
func _get_link_path(link: Dictionary) -> Array[Vector3]:
	var a := layout.get_slot(link.a)
	var b := layout.get_slot(link.b)
	var path: Array[Vector3] = []
	path.append(_get_door_point(a, link.wall_a))
	for bend: Vector2 in link.via:
		path.append(Vector3(bend.x, 0.0, bend.y))
	path.append(_get_door_point(b, link.wall_b))
	return path


## The middle of a room's wall, in ship coordinates, on the room's inner face.
func _get_door_point(slot: Dictionary, wall: int) -> Vector3:
	var middle := RoomGeometry.wall_middle(layout.get_shape(slot), wall)
	return layout.get_slot_center(slot) + Vector3(middle.x, 0.0, middle.y)


## One side wall of a straight corridor piece, from `start` to `end` along it.
func _add_corridor_wall(
	piece: Node3D, offset: float, start: float, end: float, height: float
) -> void:
	if end - start < 0.05:
		return
	var size := Vector3(layout.wall_thickness, height, end - start)
	_box(piece, Vector3(offset, height * 0.5, (start + end) * 0.5), size, _wall_material)


## A floor or ceiling slab over a room, with convex collision.
func _add_slab(
	room: Node3D, polygon: PackedVector2Array, y_bottom: float, y_top: float
) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	if y_bottom >= layout.room_height:
		body.add_to_group(CEILING_GROUP)
	var shape := ConvexPolygonShape3D.new()
	shape.points = RoomGeometry.get_prism_points(polygon, y_bottom, y_top)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	var visual := MeshInstance3D.new()
	visual.mesh = RoomGeometry.make_prism_mesh(polygon, y_bottom, y_top)
	visual.material_override = _slab_material
	body.add_child(visual)
	room.add_child(body)


## The zone of a room: a prism over its shape.
func _add_room_zone(room: Node3D, polygon: PackedVector2Array) -> Zone:
	var zone := Zone.new()
	zone.collision_layer = 0
	zone.collision_mask = Layers.PLAYERS | Layers.ALIENS
	var shape := ConvexPolygonShape3D.new()
	shape.points = RoomGeometry.get_prism_points(polygon, 0.0, layout.room_height)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	zone.add_child(collider)
	room.add_child(zone)
	GameState.register_zone(zone)
	return zone


## One solid box: something to stand on or bump into, plus what you see.
## `center` is in the parent's frame.
func _box(
	parent: Node3D, center: Vector3, size: Vector3, material: Material
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	body.add_child(visual)
	parent.add_child(body)
	return body


func _add_light(parent: Node3D, at: Vector3, light_range: float, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.omni_range = light_range
	light.light_color = color
	light.light_energy = layout.light_energy
	parent.add_child(light)


## Rooms neighbour the corridors that touch them, and the other way round.
func _link_neighbours() -> void:
	for link: Dictionary in ShipLayoutData.LINKS:
		var key := StringName("link_%s_%s" % [link.a, link.b])
		if not link_zones.has(key):
			continue
		var corridor: Zone = link_zones[key]
		for slot_id: StringName in [link.a, link.b]:
			var room: Zone = room_zones[slot_id]
			room.neighbours.append(corridor)
			corridor.neighbours.append(room)


## Search containers against the longest walls that have no doorway.
func _place_room_spots(
	slot: Dictionary,
	room: Node3D,
	polygon: PackedVector2Array,
	count: int,
	door_walls: Array
) -> void:
	var candidates: Array[int] = []
	for k in RoomGeometry.wall_count(polygon):
		if k not in door_walls and RoomGeometry.wall_length(polygon, k) >= MIN_SPOT_WALL:
			candidates.append(k)
	# Longest first; walls of equal length keep their order.
	candidates.sort_custom(
		func(a: int, b: int) -> bool:
			var length_a := RoomGeometry.wall_length(polygon, a)
			var length_b := RoomGeometry.wall_length(polygon, b)
			if not is_equal_approx(length_a, length_b):
				return length_a > length_b
			return a < b
	)
	for i in mini(count, candidates.size()):
		var k := candidates[i]
		var spot_at := RoomGeometry.wall_middle(polygon, k)
		spot_at -= RoomGeometry.wall_normal(polygon, k) * SPOT_WALL_MARGIN
		_add_spot(room, "Search_%s_%d" % [slot.id, i], Vector3(spot_at.x, 0.0, spot_at.y))


func _add_spot(parent: Node3D, spot_name: String, at: Vector3) -> void:
	var spot := SearchSpot.new()
	spot.name = spot_name
	spot.position = at
	parent.add_child(spot)


## Debug builds only: warns about furnishing parts that stick out of the room.
func _warn_if_outside(furnishing: Node3D, polygon: PackedVector2Array) -> void:
	if not OS.is_debug_build():
		return
	for child: Node in furnishing.get_children():
		var part := child as Node3D
		if part == null:
			continue
		var flat := Vector2(part.position.x, part.position.z)
		if not RoomGeometry.is_inside(flat, polygon, FURNISHING_MARGIN):
			push_warning("%s sticks out of its room" % part.name)
