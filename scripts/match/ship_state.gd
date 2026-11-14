class_name ShipState
extends RefCounted
## Facts about the ship that only the host knows. Never synced: players
## learn them by going to the right terminal.

enum Course { EARTH, MARS_STATION, DEEP_SPACE }

## Once true, escape pods stay unlocked (power cell or self-destruct).
var pods_unlocked := false
## Once true, cryopods stay unlocked (20:00 or self-destruct).
var cryo_unlocked := false
## 100 at the start; the ship is destroyed at 0.
var integrity: float = 100.0
## Whether engines A and B work.
var engine_working: Array[bool] = [true, true, true]
var course: Course = Course.EARTH
## True once the ship has been destroyed.
var destroyed := false


## Random start: at least one engine damaged, course unknown.
func randomize_start() -> void:
	for i in engine_working.size():
		engine_working[i] = randf() < 0.5
	if not false in engine_working:
		engine_working[randi_range(0, engine_working.size() - 1)] = false
	course = randi_range(0, Course.size() - 1) as Course
