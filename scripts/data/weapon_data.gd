class_name WeaponData
extends Resource
## The numbers for one ranged weapon. One .tres file per weapon in
## res://data/weapons/. Values come from the GDD "Weapons" table.

## Name shown on the HUD.
@export var display_name: String = "Pistol"
## Damage to aliens per pellet.
@export var damage: float = 20.0
## Rounds the weapon holds when full.
@export var capacity: int = 8
## Rays per shot (8 for the shotgun).
@export var pellets: int = 1
## True if holding the trigger keeps firing (assault rifle).
@export var automatic: bool = false
## Minimum seconds between shots.
@export var fire_interval: float = 0.25
## Half-angle of the random spread cone, in degrees.
@export var spread_degrees: float = 1.0
## How far the shot reaches, in metres.
@export var max_range: float = 60.0
## Noise added to the shooter's zone per shot.
@export var noise: float = 2.0
