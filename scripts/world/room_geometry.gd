class_name RoomGeometry
extends RefCounted
## Maths for rooms that are convex polygons (hexagons, the long engine rooms,
## the big oval Cryo Bay...).
##
## A room is described in its own frame: the origin is the middle of the floor,
## and the polygon is a list of corners (x, z) in clockwise order seen from
## above. Wall `k` runs from corner `k` to corner `k + 1`. The shapes come from
## ShipLayoutData.SHAPES.


## Number of walls (the same as the number of corners).
static func wall_count(points: PackedVector2Array) -> int:
	return points.size()


## The middle of wall `k`.
static func wall_middle(points: PackedVector2Array, k: int) -> Vector2:
	return (points[k] + points[(k + 1) % points.size()]) * 0.5


## Length of wall `k`.
static func wall_length(points: PackedVector2Array, k: int) -> float:
	return points[k].distance_to(points[(k + 1) % points.size()])


## Unit vector along wall `k`, from corner `k` toward corner `k + 1`.
static func wall_tangent(points: PackedVector2Array, k: int) -> Vector2:
	return (points[(k + 1) % points.size()] - points[k]).normalized()


## Unit vector pointing out of the room, at right angles to wall `k`.
static func wall_normal(points: PackedVector2Array, k: int) -> Vector2:
	var tangent := wall_tangent(points, k)
	var normal := Vector2(tangent.y, -tangent.x)
	# The room is centred on the origin, so the outside is away from it.
	if normal.dot(wall_middle(points, k)) < 0.0:
		normal = -normal
	return normal


## How far a wall's end must be lengthened so that two thick walls meeting at
## corner `corner` leave no notch outside the room.
static func corner_overlap(points: PackedVector2Array, corner: int, thickness: float) -> float:
	var count := points.size()
	var incoming := wall_tangent(points, (corner + count - 1) % count)
	var outgoing := wall_tangent(points, corner)
	return thickness * tan(absf(incoming.angle_to(outgoing)) * 0.5)


## True if `point` (floor plane, room frame) is inside the room with at least
## `margin` metres to spare from every wall.
static func is_inside(point: Vector2, points: PackedVector2Array, margin: float = 0.0) -> bool:
	for k in points.size():
		var away := (point - wall_middle(points, k)).dot(wall_normal(points, k))
		if away > -margin:
			return false
	return true


## The farthest a corner is from the middle (for sizing lights).
static func get_radius(points: PackedVector2Array) -> float:
	var radius := 0.0
	for corner in points:
		radius = maxf(radius, corner.length())
	return radius


## The corners of a prism over the room from `y_bottom` to `y_top`, for convex
## collision shapes and zone volumes.
static func get_prism_points(
	points: PackedVector2Array, y_bottom: float, y_top: float
) -> PackedVector3Array:
	var result := PackedVector3Array()
	for corner in points:
		result.append(Vector3(corner.x, y_bottom, corner.y))
		result.append(Vector3(corner.x, y_top, corner.y))
	return result


## A visible prism over the room: top, bottom and the sides. Give it a material
## with `cull_mode` set to disabled so the triangle winding does not matter.
static func make_prism_mesh(
	points: PackedVector2Array, y_bottom: float, y_top: float
) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top_middle := Vector3(0.0, y_top, 0.0)
	var bottom_middle := Vector3(0.0, y_bottom, 0.0)
	var count := points.size()
	for k in count:
		var c0 := points[k]
		var c1 := points[(k + 1) % count]
		var top0 := Vector3(c0.x, y_top, c0.y)
		var top1 := Vector3(c1.x, y_top, c1.y)
		var bottom0 := Vector3(c0.x, y_bottom, c0.y)
		var bottom1 := Vector3(c1.x, y_bottom, c1.y)
		for vertex: Vector3 in [top_middle, top0, top1]:
			surface.add_vertex(vertex)
		for vertex: Vector3 in [bottom_middle, bottom1, bottom0]:
			surface.add_vertex(vertex)
		for vertex: Vector3 in [top0, bottom0, bottom1, top0, bottom1, top1]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()
