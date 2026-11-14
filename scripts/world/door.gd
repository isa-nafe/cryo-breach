class_name Door
extends Interactable
## A sliding door in a doorway. It is its own Interactable: E opens and
## closes it, a held welder welds or cuts it, a held keycard passes a lock.
##
## Build with `Door.create(...)`. The slab is on the "doors" layer so it
## blocks bodies and bullets but does not cut the navigation mesh.

## Emitted on every change of open / locked / welded.
signal state_changed

var is_open := false
var is_welded := false
## Seconds of lock left; 0 = not locked.
var lock_seconds: float = 0.0

var _slab: StaticBody3D
var _slab_collider: CollisionShape3D
var _closed_height := 0.0


## Makes a door that fills a doorway of the given size. `along_x` is true
## if the wall it sits in runs along X.
static func create(width: float, height: float, thickness: float, along_x: bool) -> Door:
	var door := Door.new()
	var size := Vector3(width, height, thickness) if along_x else Vector3(thickness, height, width)
	door._closed_height = height * 0.5
	door._slab = StaticBody3D.new()
	door._slab.collision_layer = Layers.DOORS
	door._slab.collision_mask = 0
	door._slab.position.y = door._closed_height
	var slab_shape := BoxShape3D.new()
	slab_shape.size = size
	door._slab_collider = CollisionShape3D.new()
	door._slab_collider.shape = slab_shape
	door._slab.add_child(door._slab_collider)
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.45, 0.1)
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	door._slab.add_child(visual)
	door.add_child(door._slab)
	# The look-at area is a little fatter than the slab so the crosshair
	# ray reaches it first, and it stays in the doorway when the door is open.
	var area_shape := BoxShape3D.new()
	area_shape.size = size + Vector3.ONE * 0.2
	var area_collider := CollisionShape3D.new()
	area_collider.shape = area_shape
	area_collider.position.y = door._closed_height
	door.add_child(area_collider)
	return door


func _ready() -> void:
	super._ready()
	add_to_group(&"doors")


func _physics_process(delta: float) -> void:
	if lock_seconds <= 0.0 or not multiplayer.is_server():
		return
	lock_seconds = maxf(lock_seconds - delta, 0.0)
	if lock_seconds <= 0.0:
		state_changed.emit()


func is_locked() -> bool:
	return lock_seconds > 0.0


func get_prompt(_player: PlayerCharacter) -> String:
	return "Close" if is_open else "Open"


## Shown without a key when the door cannot be used right now.
func get_blocked_prompt(_player: PlayerCharacter) -> String:
	if is_welded:
		return "Welded shut"
	return "Locked (%d s)" % ceili(lock_seconds)


func can_interact(player: PlayerCharacter) -> bool:
	if is_welded:
		return false
	return not is_locked() or player.inventory.holds(&"keycard")


func get_item_prompt(_player: PlayerCharacter, item: ItemData) -> String:
	if item.id != &"welder" or is_open:
		return ""
	return "Cut open" if is_welded else "Weld shut"


func get_item_seconds(_player: PlayerCharacter, _item: ItemData) -> float:
	return Config.tuning.weld_seconds


## Host only: locks the door for a while (Security terminal).
func lock(seconds: float) -> void:
	lock_seconds = seconds
	state_changed.emit()


## Host only: releases the lock (timer ran out, or the section lost power).
func unlock() -> void:
	lock_seconds = 0.0
	state_changed.emit()


## Host only: opens or closes the door. Phase 3 syncs this to clients.
func set_open(open: bool) -> void:
	if is_open == open:
		return
	is_open = open
	_slab_collider.set_deferred("disabled", open)
	var target := _closed_height * 3.0 if open else _closed_height
	var slide := create_tween()
	slide.tween_property(_slab, "position:y", target, Config.tuning.door_slide_seconds)
	state_changed.emit()


## Host only: true if this alien may pass. Opens the door for it if so.
func let_alien_through(_alien: Alien) -> bool:
	if is_open:
		return true
	if is_welded or is_locked():
		return false
	set_open(true)
	return true


func _on_interact(_player: PlayerCharacter) -> void:
	set_open(not is_open)


func _on_item_used(_player: PlayerCharacter, _item: ItemData, _hand: int) -> void:
	is_welded = not is_welded
	state_changed.emit()
