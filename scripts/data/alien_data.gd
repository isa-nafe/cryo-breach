class_name AlienData
extends Resource
## The numbers for one alien type. One .tres per type in res://data/aliens/.
## Values come from the GDD "Alien types" table. Fields a type does not use
## stay at 0 (or -1 for "cannot").

## Short id used in the alien pool, for example &"crawler".
@export var id: StringName = &"crawler"
## Name for debug text and the end screen.
@export var display_name: String = "Crawler"
@export_group("Body")
@export var max_health: float = 30.0
## Normal movement speed in metres per second.
@export var move_speed: float = 6.0
## Height of the eyes above the feet, for sight checks.
@export var eye_height: float = 0.5
@export_group("Senses")
## How far it sees, in metres. 0 = blind.
@export var sight_range: float = 20.0
## Full width of the sight cone in degrees. 360 = sees all around.
@export var sight_cone_degrees: float = 120.0
## How far it hears loud noise, in metres. 0 = deaf.
@export var hearing_range: float = 10.0
## Speed when charging toward a noise (Adult). 0 = never charges.
@export var charge_speed: float = 0.0
## A noise this close triggers a charge (Adult).
@export var charge_range: float = 0.0
@export_group("Attack")
## Reach of the attack, measured between body centres.
@export var attack_range: float = 1.4
## Seconds between attacks.
@export var attack_interval: float = 1.2
@export var light_wounds_per_hit: int = 1
@export var serious_wounds_per_hit: int = 0
## Contamination cards given per hit (or per latch for the Larva).
@export var contamination_per_hit: int = 0
## Seconds the victim is knocked down (Breeder).
@export var knockdown_seconds: float = 0.0
## Seconds a Larva stays latched before fleeing. 0 = does not latch.
@export var latch_seconds: float = 0.0
@export_group("Doors and fleeing")
## Seconds to break a locked door. -1 = cannot.
@export var lock_break_seconds: float = -1.0
## Seconds to break a welded door or vent. -1 = cannot.
@export var weld_break_seconds: float = -1.0
## Below this fraction of health it may flee. 0 = never flees.
@export var flee_health_fraction: float = 0.0
## Chance to flee when below the fraction (rolled once).
@export var flee_chance: float = 0.0
## True if it drops an Alien Sample when killed.
@export var drops_sample: bool = false
## True if the stun baton does not stun it (Queen).
@export var stun_immune: bool = false
