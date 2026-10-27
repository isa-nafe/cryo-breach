class_name Zone
extends Area3D
## A room or a corridor segment.
##
## The design doc makes everything room-based: noise, fire, hull breaches,
## power and vents all belong to a zone, and explosions hit everything inside
## one. For now a zone only tracks its noise meter and who is inside.
##
## Setup: give the Area3D a CollisionShape3D that fills the room. Keep
## collision_layer at 0 and collision_mask on "players" and "aliens".

## Emitted when the noise meter changes.
signal noise_changed(value: float)

## Name shown to players and in the debug HUD.
@export var zone_name: String = "Unnamed zone"
## Rooms and corridor segments behave slightly differently later
## (fires and breaches only happen in rooms).
@export_enum("Room", "Corridor") var kind: String = "Room"
## Which power section this zone belongs to.
@export_enum("Fore", "Mid", "Aft") var power_section: String = "Fore"

## Current noise, from 0 to Config.tuning.noise_max.
var noise: float = 0.0

var _drain_timer := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if noise <= 0.0:
		_drain_timer = 0.0
		return
	_drain_timer += delta
	var interval := Config.tuning.noise_drain_interval
	if _drain_timer >= interval:
		_drain_timer -= interval
		set_noise(noise - 1.0)


## Adds noise to this zone (it never goes above the maximum).
func add_noise(amount: float) -> void:
	set_noise(noise + amount)


func set_noise(value: float) -> void:
	var clamped := clampf(value, 0.0, Config.tuning.noise_max)
	if is_equal_approx(clamped, noise):
		return
	noise = clamped
	noise_changed.emit(noise)


func _on_body_entered(body: Node3D) -> void:
	var player := body as PlayerCharacter
	if player:
		player.enter_zone(self)


func _on_body_exited(body: Node3D) -> void:
	var player := body as PlayerCharacter
	if player:
		player.exit_zone(self)
