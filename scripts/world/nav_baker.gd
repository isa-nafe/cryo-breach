class_name NavBaker
extends NavigationRegion3D
## Builds the navigation mesh when the level starts, from every collider on
## the "world" layer below this node. Put the level under this node.
## Wait for the built-in `bake_finished` signal before spawning aliens.

## Bake as soon as the node is ready. Turn off to call `bake()` yourself
## once the level has been built in code.
@export var bake_on_ready := true
## If set, only nodes in this group (and their children) are baked. The ship
## uses it so doors, pickups and lights do not cut holes in the floor.
@export var source_group: StringName = &""


func _ready() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH
	mesh.geometry_collision_mask = Layers.WORLD
	if source_group != &"":
		mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
		mesh.geometry_source_group_name = source_group
	navigation_mesh = mesh
	if bake_on_ready:
		bake()


## Builds the navigation mesh now (after a short wait for collision shapes).
func bake() -> void:
	# BOTH reads CSG meshes as well as colliders; CSG shapes are not always
	# seen as static colliders.
	# CSG shapes create their collision a frame late, so wait before baking.
	await get_tree().physics_frame
	await get_tree().physics_frame
	bake_navigation_mesh()
