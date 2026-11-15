class_name HitscanWeapon
extends Node3D
## A gun that hits instantly along a ray: pistol, rifle, shotgun.
##
## The character calls `update_trigger` every physics frame. The weapon
## decides when a shot happens, casts the ray and damages what it hits.
## Scene: Node3D with children "MuzzleFlash" (OmniLight3D) and "ShotSound"
## (AudioStreamPlayer3D).

## Emitted for every shot fired.
signal fired
## Emitted when the trigger is pulled on an empty weapon.
signal dry_fired
## Emitted when a shot damages something. `killed` is true on a kill.
signal hit_confirmed(killed: bool)
## Emitted when the number of loaded rounds changes.
signal ammo_changed(rounds: int, capacity: int)

## The weapon's numbers.
@export var data: WeaponData

## Rounds currently loaded.
var rounds: int = 0
## The item this weapon is a view of; its `charges` are the rounds, so ammo
## survives stowing, dropping and picking the weapon up again.
var stack: ItemStack = null

var _cooldown := 0.0
var _trigger_was_held := false

@onready var _flash: OmniLight3D = $MuzzleFlash
@onready var _shot_sound: AudioStreamPlayer3D = $ShotSound


func _ready() -> void:
	rounds = data.capacity
	_flash.visible = false
	_shot_sound.stream = PlaceholderSounds.noise_burst(Config.tuning.placeholder_shot_seconds)


## Connects this view to the item it shows and loads its rounds.
func bind_stack(item_stack: ItemStack) -> void:
	stack = item_stack
	if stack.data.weapon:
		data = stack.data.weapon
	rounds = stack.charges
	ammo_changed.emit(rounds, data.capacity)


## Call every physics frame with whether the fire button is held. When the
## trigger fires a shot, returns its directions (one per pellet); otherwise an
## empty array. The caller applies the shot with `apply_shot`: on the host
## directly, from a client through a request.
func update_trigger(held: bool, shooter: PlayerCharacter, delta: float) -> PackedVector3Array:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var directions := PackedVector3Array()
	var pulled := held and (data.automatic or not _trigger_was_held)
	_trigger_was_held = held
	if not pulled or _cooldown > 0.0:
		return directions
	_cooldown = data.fire_interval
	if rounds <= 0:
		dry_fired.emit()
		return directions
	var spread := data.spread_degrees * shooter.get_spread_multiplier()
	var aim := shooter.camera.global_basis
	for _i in data.pellets:
		directions.append(_spread_direction(aim, spread))
	return directions


## Host only: fires one shot. Uses up a round, casts a ray along each direction,
## damages what they hit and makes noise.
func apply_shot(shooter: PlayerCharacter, origin: Vector3, directions: PackedVector3Array) -> void:
	rounds -= 1
	if stack:
		stack.charges = rounds
	ammo_changed.emit(rounds, data.capacity)
	for direction: Vector3 in directions:
		_resolve_shot(shooter, origin, direction.normalized())
	shooter.emit_noise(data.noise)
	fired.emit()


## Fills the weapon (ammo box).
func reload_full() -> void:
	rounds = data.capacity
	if stack:
		stack.charges = rounds
	ammo_changed.emit(rounds, data.capacity)


## Decides what one ray hits. Host only.
func _resolve_shot(shooter: PlayerCharacter, origin: Vector3, direction: Vector3) -> void:
	var end := origin + direction * data.max_range
	var query := PhysicsRayQueryParameters3D.create(origin, end, Layers.BULLET_MASK)
	var hit := shooter.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var health := HealthComponent.find_in(hit.collider as Node)
	if health == null or health.is_dead:
		return
	health.take_damage(data.damage, shooter)
	hit_confirmed.emit(health.is_dead)


## A random direction inside a cone around the camera's forward axis.
func _spread_direction(aim: Basis, spread_deg: float) -> Vector3:
	var angle := deg_to_rad(spread_deg) * sqrt(randf())
	var roll := randf() * TAU
	var local := Vector3.FORWARD.rotated(Vector3.RIGHT, angle).rotated(Vector3.FORWARD, roll)
	return (aim * local).normalized()


## The flash and the sound of a shot from this gun.
func show_effects() -> void:
	_shot_sound.play()
	_flash.visible = true
	var timer := get_tree().create_timer(Config.tuning.muzzle_flash_seconds)
	timer.timeout.connect(_hide_flash)


func _hide_flash() -> void:
	_flash.visible = false
