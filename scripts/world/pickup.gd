class_name Pickup
extends Interactable
## An item lying on the floor. Look at it and hold E to take it.
##
## Make one with `Pickup.spawn(tree, stack, floor_position)`. It builds its
## own grey box and collision shape from the item's colour.

## What this pickup holds. If only part of it fits, the rest stays here.
var stack: ItemStack


## Creates a pickup (not yet in the scene).
static func create(item_stack: ItemStack) -> Pickup:
	var pickup := Pickup.new()
	pickup.stack = item_stack
	return pickup


## Puts a pickup on the floor at `at`, in the scene's "Items" node if it
## has one.
static func spawn(tree: SceneTree, item_stack: ItemStack, at: Vector3) -> Pickup:
	# In a network game the match's ItemSpawner makes the pickup on every machine.
	var spawner := tree.current_scene.get_node_or_null(^"ItemSpawner") as MultiplayerSpawner
	if spawner != null and Net.is_networked():
		return spawner.spawn({"stack": item_stack.to_dict(), "position": at}) as Pickup
	var pickup := create(item_stack)
	var parent: Node = tree.current_scene.get_node_or_null(^"Items")
	if parent == null:
		parent = tree.current_scene
	parent.add_child(pickup)
	pickup.global_position = at
	return pickup


func _ready() -> void:
	super._ready()
	var size := Config.tuning.pickup_size
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = size * 0.5
	add_child(collider)
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * size
	var material := StandardMaterial3D.new()
	material.albedo_color = stack.data.color
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position.y = size * 0.5
	add_child(visual)


func get_prompt(player: PlayerCharacter) -> String:
	var text := stack.data.display_name
	if stack.count > 1:
		text += " x%d" % stack.count
	if not player.inventory.can_accept(stack):
		return "No room for %s" % text
	return "Take %s" % text


func get_hold_seconds(player: PlayerCharacter) -> float:
	if not player.inventory.can_accept(stack):
		return 0.0
	return Config.tuning.pickup_seconds


func _on_interact(player: PlayerCharacter) -> void:
	if not player.inventory.can_accept(stack):
		return
	# `add` puts the whole stack in (true) or tops up what it can (false).
	if player.inventory.add(stack):
		queue_free()
	elif Net.is_networked():
		# Only part fitted: everyone should see what is left.
		_rpc_count.rpc(stack.count)


@rpc("authority", "call_remote", "reliable")
func _rpc_count(count: int) -> void:
	stack.count = count
