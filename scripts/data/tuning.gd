class_name Tuning
extends Resource
## Every gameplay number in Cryo Breach lives in a Tuning resource.
##
## The values used by the game are the ones saved in res://data/tuning.tres.
## Open that file in the Inspector to change them; no code changes needed.
## The defaults below match the Game Design Document and are only used if a
## value is missing from the .tres file.
##
## Rule from the design doc: when a new system needs a number (a timer, a
## speed, a chance, a count), add it here instead of writing it in code.

@export_group("Player movement")
## Normal walking speed, in metres per second.
@export var walk_speed: float = 3.5
## Sprinting speed. Sprinting makes noise.
@export var sprint_speed: float = 5.5
## Crouch-walking speed. Crouch-walking is silent.
@export var crouch_speed: float = 1.8
## Upward speed when jumping, in metres per second.
@export var jump_velocity: float = 4.0
## How fast you reach your target speed on the ground (m/s per second).
@export var ground_acceleration: float = 30.0
## Fraction of ground acceleration available in the air (0 = none, 1 = full).
@export_range(0.0, 1.0) var air_control: float = 0.25
## Radians turned per pixel of mouse movement.
@export var mouse_sensitivity: float = 0.0025
## How far up or down you can look, in degrees.
@export var max_look_pitch_degrees: float = 85.0

@export_group("Player body")
## Height of the collision capsule when standing, in metres.
@export var stand_height: float = 1.8
## Height of the collision capsule when crouching.
@export var crouch_height: float = 1.1
## How fast the body changes height when crouching or standing (m/s).
@export var crouch_transition_speed: float = 6.0
## Distance from the top of the capsule down to the eyes.
@export var eye_offset_from_top: float = 0.15

@export_group("Noise")
## Maximum noise a room or corridor segment can hold.
@export var noise_max: float = 10.0
## Every this many seconds, each zone's noise drops by 1.
@export var noise_drain_interval: float = 15.0
## While sprinting, add noise every this many seconds.
@export var sprint_noise_interval: float = 3.0
## Noise added per sprint interval.
@export var sprint_noise_amount: float = 1.0
