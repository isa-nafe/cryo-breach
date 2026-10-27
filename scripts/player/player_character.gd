class_name PlayerCharacter
extends CharacterBody3D
## The body every crew member uses: movement, crouching, looking, noise.
##
## It never reads the keyboard itself. Each physics frame it asks its input
## source (a PlayerInput node today) for an InputState and acts on it. That
## keeps the door open for remote players and bots later.

## Emitted whenever this character makes noise in its current zone.
signal made_noise(amount: float)

## The node that provides this character's InputState.
@export var input_source_path: NodePath = ^"PlayerInput"

## The room or corridor segment the character is standing in (or null).
var current_zone: Zone = null
var is_crouching := false
var is_sprinting := false

var _tuning: Tuning
var _capsule: CapsuleShape3D
var _zones: Array[Zone] = []
var _sprint_noise_timer := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var lamp: SpotLight3D = $Head/Camera3D/HelmetLamp
@onready var input_source: PlayerInput = get_node(input_source_path)
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_tuning = Config.tuning
	_capsule = _collision.shape as CapsuleShape3D
	_set_body_height(_tuning.stand_height)


func _process(_delta: float) -> void:
	# Looking is applied every rendered frame so the mouse feels responsive.
	var look := input_source.state.look_delta
	if look == Vector2.ZERO:
		return
	input_source.state.look_delta = Vector2.ZERO
	rotate_y(look.x)
	var max_pitch := deg_to_rad(_tuning.max_look_pitch_degrees)
	head.rotation.x = clampf(head.rotation.x + look.y, -max_pitch, max_pitch)


func _physics_process(delta: float) -> void:
	var input := input_source.poll()
	_update_crouch(input.crouch, delta)
	_update_movement(input, delta)
	move_and_slide()
	_update_noise(delta)
	if input.toggle_lamp:
		lamp.visible = not lamp.visible
	input.clear_one_shots()


## Adds noise to the zone this character is in.
func emit_noise(amount: float) -> void:
	if current_zone:
		current_zone.add_noise(amount)
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


func _update_movement(input: InputState, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif input.jump and not is_crouching:
		velocity.y = _tuning.jump_velocity

	var wants_to_move := input.move.length() > 0.1
	is_sprinting = input.sprint and wants_to_move and not is_crouching and is_on_floor()

	var speed := _tuning.walk_speed
	if is_crouching:
		speed = _tuning.crouch_speed
	elif is_sprinting:
		speed = _tuning.sprint_speed

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
	head.position.y = height - _tuning.eye_offset_from_top


func _update_noise(delta: float) -> void:
	if not is_sprinting:
		_sprint_noise_timer = 0.0
		return
	_sprint_noise_timer += delta
	if _sprint_noise_timer >= _tuning.sprint_noise_interval:
		_sprint_noise_timer -= _tuning.sprint_noise_interval
		emit_noise(_tuning.sprint_noise_amount)
