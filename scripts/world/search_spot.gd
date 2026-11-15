class_name SearchSpot
extends Interactable
## A container: hold E to search, then it draws one card from the loot deck.
## Build with `SearchSpot.new()`; it makes its own crate.

## Size of the grey-box crate.
const CRATE_SIZE := Vector3(0.7, 0.5, 0.7)


func _ready() -> void:
	super._ready()
	prompt = "Search"
	hold_seconds = Config.tuning.search_seconds
	noise = Config.tuning.search_noise
	# The look-at area is a little bigger than the crate so it is hit first.
	var area_shape := BoxShape3D.new()
	area_shape.size = CRATE_SIZE + Vector3.ONE * 0.2
	var area_collider := CollisionShape3D.new()
	area_collider.shape = area_shape
	area_collider.position.y = CRATE_SIZE.y * 0.5
	add_child(area_collider)
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var body_shape := BoxShape3D.new()
	body_shape.size = CRATE_SIZE
	var body_collider := CollisionShape3D.new()
	body_collider.shape = body_shape
	body_collider.position.y = CRATE_SIZE.y * 0.5
	body.add_child(body_collider)
	add_child(body)
	var mesh := BoxMesh.new()
	mesh.size = CRATE_SIZE
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.35, 0.2)
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position.y = CRATE_SIZE.y * 0.5
	add_child(visual)


func get_blocked_prompt(_player: PlayerCharacter) -> String:
	return "Already searched"


func _on_interact(player: PlayerCharacter) -> void:
	set_enabled_everywhere(false)
	var id := GameState.loot_deck.draw()
	if id == &"":
		player.show_message("Empty")
		return
	var stack := ItemStack.create(Config.get_item(id))
	var item_name := stack.data.display_name
	if player.inventory.add(stack):
		player.show_message("Found: %s" % item_name)
	else:
		Pickup.spawn(get_tree(), stack, global_position + Vector3.UP * CRATE_SIZE.y)
		player.show_message("Found: %s (no room, left on the crate)" % item_name)
