class_name EscapePod
extends Interactable
## One escape pod (GDD "Escape pods"). Hold E to climb in. Once seated:
## tap E to climb out, hold E to start the launch, hold E again during the
## countdown to abort it. Phase 2 has one seat per pod and ends the match
## when a pod launches; M5.3 adds two seats and the full rules.

const LOCKED_COLOR := Color(0.8, 0.2, 0.2)
const UNLOCKED_COLOR := Color(0.2, 0.8, 0.35)
## How far above the floor a seated player is placed.
const SEAT_LIFT := 0.05

## True while the launch countdown runs.
var launching := false
## Seconds left on the countdown while `launching`.
var launch_left: float = 0.0
var launched := false
## The player in the seat, or null.
var occupant: PlayerCharacter = null
## Progress from 0 to 1 of the launch hold, for the HUD bar.
var hold_fraction: float = 0.0

var _hold_time := 0.0
# Starts true so the key that boarded the player does not also launch.
var _hold_used := true
var _last_second_shown := -1

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	super._ready()
	add_to_group(&"escape_pods")
	prompt = "Board"
	hold_seconds = Config.tuning.pod_board_seconds
	_set_light(GameState.ship_state.pods_unlocked)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or not launching or occupant == null:
		return
	launch_left -= delta
	var second := ceili(launch_left)
	if second != _last_second_shown and second > 0:
		_last_second_shown = second
		occupant.show_message("Launching in %d s (hold E to abort)" % second)
	if launch_left <= 0.0:
		_launch()


## Called through the "escape_pods" group when the socket gets power.
func on_unlocked() -> void:
	_set_light(true)


func can_interact(_player: PlayerCharacter) -> bool:
	return enabled and GameState.ship_state.pods_unlocked and occupant == null and not launched


func get_prompt(_player: PlayerCharacter) -> String:
	return "Board"


func get_blocked_prompt(_player: PlayerCharacter) -> String:
	if launched:
		return "Launched"
	if not GameState.ship_state.pods_unlocked:
		return "Pod locked: the Pod Bay needs power"
	if occupant != null:
		return "Occupied"
	return ""


## What to show a player who is sitting in this pod.
func get_seated_prompt() -> String:
	if launching:
		return "Launching in %d s: hold E to abort" % ceili(launch_left)
	return "Tap E: climb out | Hold E: launch"


## Call every physics frame for the player sitting in this pod.
func update_seated(player: PlayerCharacter, input: InputState, delta: float) -> void:
	hold_fraction = 0.0
	if input.interact_held:
		_hold_time += delta
		var needed := Config.tuning.pod_launch_hold_seconds
		if not _hold_used:
			hold_fraction = clampf(_hold_time / needed, 0.0, 1.0)
			if _hold_time >= needed:
				_hold_used = true
				request_toggle_launch(player)
	else:
		# A short press (released before the hold finished) climbs out.
		if _hold_time > 0.0 and not _hold_used and not launching:
			request_exit(player)
		_hold_time = 0.0
		_hold_used = false


## Climb out of the seat.
func request_exit(player: PlayerCharacter) -> void:
	# Phase 3: send an RPC to the host instead when not the server.
	_host_exit(player)


## Start the launch countdown, or abort it if it is running.
func request_toggle_launch(player: PlayerCharacter) -> void:
	# Phase 3: send an RPC to the host instead when not the server.
	_host_toggle_launch(player)


## Host only: lets go of the seat (used when the occupant dies).
func release(player: PlayerCharacter) -> void:
	if occupant == player:
		occupant = null
		launching = false
		player.seated_pod = null


func _on_interact(player: PlayerCharacter) -> void:
	occupant = player
	player.seated_pod = self
	player.velocity = Vector3.ZERO
	player.global_position = global_position * Vector3(1.0, 0.0, 1.0) + Vector3.UP * SEAT_LIFT
	_hold_time = 0.0
	_hold_used = true
	player.show_message("Seated. Tap E to climb out, hold E to launch")


func _host_exit(player: PlayerCharacter) -> void:
	if occupant != player or launching or launched:
		return
	occupant = null
	player.seated_pod = null
	# The pod's parent is the room's furnishing, centred on the room.
	var middle := (get_parent() as Node3D).global_position
	var toward_middle := middle - global_position
	toward_middle.y = 0.0
	var out := toward_middle.normalized() * Config.tuning.pod_exit_distance
	player.global_position = global_position * Vector3(1.0, 0.0, 1.0) + out + Vector3.UP * SEAT_LIFT


func _host_toggle_launch(player: PlayerCharacter) -> void:
	if occupant != player or launched or not GameState.ship_state.pods_unlocked:
		return
	if launching:
		launching = false
		player.show_message("Launch aborted")
		return
	launching = true
	launch_left = Config.tuning.pod_launch_seconds
	_last_second_shown = -1
	player.emit_noise(Config.tuning.pod_launch_noise)


func _launch() -> void:
	launching = false
	launched = true
	# Phase 2: one launched pod ends the match. M5.3 makes occupants "escaped".
	GameState.end_match(&"escaped")


func _set_light(unlocked: bool) -> void:
	var material := _mesh.get_surface_override_material(0) as StandardMaterial3D
	if material:
		material.albedo_color = UNLOCKED_COLOR if unlocked else LOCKED_COLOR
