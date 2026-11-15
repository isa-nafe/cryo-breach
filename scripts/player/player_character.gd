class_name PlayerCharacter
extends CharacterBody3D
## The body every crew member uses: movement, crouching, looking, noise.
##
## It never reads the keyboard itself. Each physics frame it asks its input
## source (a PlayerInput node today) for an InputState and acts on it. That
## keeps the door open for remote players and bots later.

## Emitted whenever this character makes noise in its current zone.
signal made_noise(amount: float)
## Emitted once when this character dies.
signal died
## Emitted when something wants to tell this player a short text.
signal message_shown(text: String)

## Physics layer 6 ("doors") as a collision-mask bit.
const _DOOR_LAYER_BIT := 32

## The node that provides this character's InputState.
@export var input_source_path: NodePath = ^"PlayerInput"

## The network peer that controls this character. Set before it is added.
## Solo play and the host's own character use 1.
var peer_id: int = 1

## The room or corridor segment the character is standing in (or null).
var current_zone: Zone = null
var is_crouching := false
var is_sprinting := false
var is_dead := false
## The escape pod this character is sitting in, or null.
var seated_pod: EscapePod = null

var _tuning: Tuning
var _capsule: CapsuleShape3D
var _zones: Array[Zone] = []
var _sprint_noise_timer := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var lamp: SpotLight3D = $Head/Camera3D/HelmetLamp
@onready var wounds: PlayerWounds = $Wounds
@onready var interactor: PlayerInteractor = $Interactor
@onready var inventory: Inventory = $Inventory
@onready var item_user: ItemUser = $ItemUser
@onready var input_source: PlayerInput = get_node(input_source_path)
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _body_mesh: MeshInstance3D = $Body
@onready var _visor: MeshInstance3D = $Head/Visor


func _enter_tree() -> void:
	# The controlling player's machine sends this character's movement; the
	# host stays the authority over everything else about it.
	$MovementSync.set_multiplayer_authority(peer_id)


func _ready() -> void:
	_tuning = Config.tuning
	_capsule = _collision.shape as CapsuleShape3D
	_set_body_height(_tuning.stand_height)
	# You see through your own character's eyes and never see its body; other
	# players' characters show as a capsule with a visor on the front.
	_body_mesh.visible = not is_local()
	_visor.visible = not is_local()
	if is_local():
		camera.make_current()
		if not multiplayer.is_server():
			# Doors are not synced until M3.4, so a client could never leave
			# its room. Until then a client's character walks through them.
			collision_mask &= ~_DOOR_LAYER_BIT
	wounds.died.connect(_on_wounds_died)
	wounds.changed.connect(_on_wounds_changed)
	GameState.register_player(self)


## True on the machine of the player who controls this character.
func is_local() -> bool:
	return peer_id == multiplayer.get_unique_id()


func _process(_delta: float) -> void:
	if not is_local():
		return
	# Looking is applied every rendered frame so the mouse feels responsive.
	var look := input_source.state.look_delta
	if look == Vector2.ZERO:
		return
	input_source.state.look_delta = Vector2.ZERO
	rotate_y(look.x)
	var max_pitch := deg_to_rad(_tuning.max_look_pitch_degrees)
	head.rotation.x = clampf(head.rotation.x + look.y, -max_pitch, max_pitch)


func _physics_process(delta: float) -> void:
	if is_local():
		_local_step(delta)
	else:
		_remote_step(delta)
	if multiplayer.is_server():
		# The host makes the noise for every character, using the synced
		# is_sprinting flag for the ones it does not control.
		_update_noise(delta)


## Runs on the machine of the player who controls this character: reads the
## input and moves the body. The host receives the result.
func _local_step(delta: float) -> void:
	var input := input_source.poll()
	if seated_pod != null and not is_dead:
		# Sitting in a pod: no walking, the pod reads the E key.
		velocity = Vector3.ZERO
		is_sprinting = false
		seated_pod.update_seated(self, input, delta)
		if input.toggle_lamp:
			lamp.visible = not lamp.visible
		input.clear_one_shots()
		return
	if not is_dead:
		_update_crouch(input.crouch, delta)
	_update_movement(input, delta)
	move_and_slide()
	# Until M3.3 turns actions into host requests, only the host's own
	# character can pick things up, search or use items.
	if not is_dead and multiplayer.is_server():
		interactor.update(self, input.interact_held, delta)
		item_user.update(input, delta)
	if input.toggle_lamp:
		lamp.visible = not lamp.visible
	input.clear_one_shots()


## Runs for every character this machine does not control: the position, turn
## and crouch flags arrive from its owner, so only the body size follows them.
func _remote_step(delta: float) -> void:
	var target_height := _tuning.stand_height
	if is_crouching:
		target_height = _tuning.crouch_height
	if not is_equal_approx(_capsule.height, target_height):
		var step := _tuning.crouch_transition_speed * delta
		_set_body_height(move_toward(_capsule.height, target_height, step))


## Adds noise to the zone this character is in.
func emit_noise(amount: float) -> void:
	if current_zone:
		current_zone.add_noise(amount)
	get_tree().call_group(&"aliens", &"hear_noise", global_position, amount)
	made_noise.emit(amount)


## Called by a Zone when this character walks into it.
func enter_zone(zone: Zone) -> void:
	if zone not in _zones:
		_zones.append(zone)
	current_zone = zone


## Called by a Zone when this character walks out of it.
func exit_zone(zone: Zone) -> void:
	_zones.erase(zone)
	if _zones.is_empty():
		current_zone = null
	else:
		current_zone = _zones.back()


## True while the character is walking around the ship (not dead).
## Sleeping and escaped states are added in Phase 5.
func is_awake() -> bool:
	return not is_dead


## Shows a short message on this player's HUD. Phase 3 sends it only to the
## owner of the character.
func show_message(text: String) -> void:
	message_shown.emit(text)


## A short description of what the character is doing, for the debug HUD.
func get_state_name() -> String:
	if not is_on_floor():
		return "In the air"
	if is_crouching:
		return "Crouching"
	if is_sprinting:
		return "Sprinting"
	if Vector2(velocity.x, velocity.z).length() > 0.1:
		return "Walking"
	return "Standing"


## How much wider than normal this character's weapon spread is.
func get_spread_multiplier() -> float:
	return wounds.get_spread_multiplier()


## A broken arm takes a hand away: whatever it held falls to the floor.
func _on_wounds_changed() -> void:
	for stack: ItemStack in inventory.set_usable_hands(wounds.get_usable_hands()):
		item_user.drop_stack(stack)


func _on_wounds_died() -> void:
	is_dead = true
	if seated_pod != null:
		seated_pod.release(self)
	input_source.enabled = false
	input_source.state.release_all()
	# Drop the camera to the floor so death reads clearly.
	var fall := create_tween()
	fall.tween_property(head, "position:y", _tuning.dead_eye_height, 0.6)
	died.emit()


func _update_movement(input: InputState, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif input.jump and not is_crouching:
		velocity.y = _tuning.jump_velocity

	var wants_to_move := input.move.length() > 0.1
	is_sprinting = (
		input.sprint and wants_to_move and not is_crouching and is_on_floor() and wounds.can_sprint()
	)

	var speed := _tuning.walk_speed
	if is_crouching:
		speed = _tuning.crouch_speed
	elif is_sprinting:
		speed = _tuning.sprint_speed
	speed *= wounds.get_speed_multiplier()

	# The body only turns left and right, so this direction is always flat.
	var direction := transform.basis * Vector3(input.move.x, 0.0, -input.move.y)
	var target := direction * speed

	var acceleration := _tuning.ground_acceleration
	if not is_on_floor():
		acceleration *= _tuning.air_control

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(target, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _update_crouch(wants_crouch: bool, delta: float) -> void:
	# Stay crouched if there is no room to stand up.
	if is_crouching and not wants_crouch and not _can_stand_up():
		wants_crouch = true
	is_crouching = wants_crouch

	var target_height := _tuning.stand_height
	if is_crouching:
		target_height = _tuning.crouch_height
	if not is_equal_approx(_capsule.height, target_height):
		var step := _tuning.crouch_transition_speed * delta
		_set_body_height(move_toward(_capsule.height, target_height, step))


func _can_stand_up() -> bool:
	var rise := _tuning.stand_height - _capsule.height
	if rise <= 0.0:
		return true
	return not test_move(global_transform, Vector3.UP * rise)


func _set_body_height(height: float) -> void:
	_capsule.height = height
	_collision.position.y = height * 0.5
	(_body_mesh.mesh as CapsuleMesh).height = height
	_body_mesh.position.y = height * 0.5
	head.position.y = height - _tuning.eye_offset_from_top


func _update_noise(delta: float) -> void:
	if not is_sprinting:
		_sprint_noise_timer = 0.0
		return
	_sprint_noise_timer += delta
	if _sprint_noise_timer >= _tuning.sprint_noise_interval:
		_sprint_noise_timer -= _tuning.sprint_noise_interval
		emit_noise(_tuning.sprint_noise_amount)
