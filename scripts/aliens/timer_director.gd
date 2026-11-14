class_name TimerDirector
extends Node
## Phase 2 stand-in for the noise director: spawns a Crawler in an empty room
## every so often after the grace period. Host only. M4.1 deletes this.

var _spawn_alien: Callable
var _timer := 0.0


## `spawn_alien` is called as spawn_alien(alien_id: StringName, position: Vector3).
func setup(spawn_alien: Callable) -> void:
	_spawn_alien = spawn_alien


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or GameState.phase != GameState.Phase.PLAYING:
		return
	if not GameState.is_grace_over():
		return
	_timer += delta
	if _timer < Config.tuning.slice_spawn_interval:
		return
	_timer = 0.0
	if get_tree().get_nodes_in_group(&"aliens").size() >= Config.tuning.slice_max_aliens:
		return
	var empty_rooms: Array[Zone] = []
	for zone: Zone in GameState.zones:
		if zone.kind == "Room" and zone.players_inside.is_empty():
			empty_rooms.append(zone)
	if empty_rooms.is_empty():
		return
	var room: Zone = empty_rooms.pick_random()
	_spawn_alien.call(&"crawler", Vector3(room.global_position.x, 0.1, room.global_position.z))
