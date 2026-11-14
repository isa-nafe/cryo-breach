# Phase 2: solo vertical slice

Goal: one player wakes in the Cryo Bay of an 8-room ship, searches for
gear, opens and welds doors, fights Crawlers, carries a power cell to the
Pod Bay and escapes before the 40:00 jump. GDD sections to read: *Match
flow*, *The ship*, *Players > Inventory*, *Items, weapons and crafting*,
*Escaping > Escape pods*.

From here on **all rule changes follow the host-authority pattern** in
README section 4.3: write `request_*` and `_host_*` even though there is
only one player. Phase 3 then only adds the RPC in the middle.

Simplifications that later phases replace:

| In Phase 2 | Replaced in |
| --- | --- |
| Crawlers arrive on a timer | M4.1 (pool + noise director) |
| Room types are fixed, 4 slots sealed | M4.5 (shuffle, all rooms) |
| Player starts with a pistol | M5.1 (roles) |
| One pod, one seat is enough | M5.3 (3 pods x 2 seats, abort, lock) |
| End screen shows only your fate | M5.5 (objectives) |

---

## M2.1 GameState, match scene, match clock

*Concepts:* autoloads (a node that exists in every scene), scene
instancing in code.

### Files

| File | Action |
| --- | --- |
| `autoload/game_state.gd` | new; register in `project.godot` as `GameState` after `Config` |
| `scripts/match/match.gd`, `scenes/match.tscn` | new |
| `scripts/ui/hud.gd`, `scenes/ui/hud.tscn` | edit: clock label, top centre |
| `project.godot` | `run/main_scene="res://scenes/match.tscn"` |

Keep `scenes/main.tscn` as a test room; it still works on its own.

```gdscript
# FILE: autoload/game_state.gd
extends Node
## The state of the current match, available everywhere as `GameState`.
##
## The host advances the clock and decides when the match ends. Phase 3
## sends the clock and the end of the match to clients.

## Emitted when the match begins.
signal match_started
## Emitted once when the match ends. `reason` is &"jump", &"destroyed",
## &"nobody_awake" or (Phase 2 only) &"escaped" / &"died".
signal match_ended(reason: StringName)
## Emitted when the clock passes a named time (see Tuning "Match flow").
signal time_mark(mark: StringName)

enum Phase { LOBBY, PLAYING, ENDED }

var phase: Phase = Phase.LOBBY
## Seconds since the match started.
var clock: float = 0.0
## Why the match ended (valid once phase is ENDED).
var end_reason: StringName = &""
## Every room and corridor segment in the ship.
var zones: Array[Zone] = []
## Every player character in the match, alive or not.
var players: Array[PlayerCharacter] = []

var _marks_done: Dictionary = {}


func _physics_process(delta: float) -> void:
	if phase != Phase.PLAYING or not multiplayer.is_server():
		return
	clock += delta
	for mark: StringName in _get_marks():
		if clock >= _get_marks()[mark] and not _marks_done.has(mark):
			_marks_done[mark] = true
			time_mark.emit(mark)
	if clock >= Config.tuning.jump_time:
		end_match(&"jump")


## Clears everything for a new match. Call before building the ship.
func reset() -> void:
	phase = Phase.LOBBY
	clock = 0.0
	end_reason = &""
	zones.clear()
	players.clear()
	_marks_done.clear()


func start_match() -> void:
	phase = Phase.PLAYING
	match_started.emit()


## Ends the match. Host only.
func end_match(reason: StringName) -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	end_reason = reason
	match_ended.emit(reason)


func register_zone(zone: Zone) -> void:
	zones.append(zone)


func register_player(player: PlayerCharacter) -> void:
	players.append(player)


## True once the grace period is over (encounters and events may happen).
func is_grace_over() -> bool:
	return clock >= Config.tuning.grace_period


## Players who are alive and still walking around the ship.
func get_awake_players() -> Array[PlayerCharacter]:
	var awake: Array[PlayerCharacter] = []
	for player: PlayerCharacter in players:
		if is_instance_valid(player) and player.is_awake():
			awake.append(player)
	return awake


## The clock as "MM:SS".
func get_clock_text() -> String:
	var total := int(clock)
	return "%02d:%02d" % [total / 60, total % 60]


func _get_marks() -> Dictionary:
	var tuning := Config.tuning
	return {
		&"grace_over": tuning.grace_period,
		&"commit": tuning.commit_time,
		&"cryo_unlock": tuning.cryo_unlock_time,
		&"jump_warning": tuning.jump_warning_time,
		&"final_warning": tuning.final_warning_time,
	}
```

`PlayerCharacter` gains `func is_awake() -> bool: return not is_dead`
(M5.3 adds sleeping and escaped) and calls
`GameState.register_player(self)` in `_ready`.

`scenes/match.tscn` tree:

```text
Match (Node3D, match.gd)
  WorldEnvironment        copy the Environment from main.tscn
  Navigation (NavBaker)   bake_on_ready = false
    Ship (ShipBuilder)    added in M2.2
  Players (Node3D)
  Aliens (Node3D)
  Items (Node3D)          dropped pickups
  HUD, DebugHUD
```

`match.gd` (`_ready`): `GameState.reset()`; build the ship (M2.2); bake
navigation; instance `player.tscn` under `Players` at the first Cryo Bay
spawn point; point the HUDs at it; `GameState.start_match()`. On
`GameState.match_ended` show the end screen (M2.7). Change `NavBaker` to
have `@export var bake_on_ready := true` and a public `bake()` method.

### Tuning to add (`@export_group("Match flow")`, all in seconds)

| Name | Value | GDD |
| --- | --- | --- |
| `grace_period` | 90.0 | No encounters or events before 1:30 |
| `commit_time` | 600.0 | Commit to an objective at 10:00 |
| `cryo_unlock_time` | 1200.0 | Cryopods unlock at 20:00 |
| `jump_warning_time` | 1800.0 | Announcement at 30:00 |
| `final_warning_time` | 2100.0 | Announcement and alarm lighting at 35:00 |
| `jump_time` | 2400.0 | Hyperspace jump at 40:00 |
| `max_players` | 6 | Most players in a match |

### Owner checks

- F5 starts in the match scene; the HUD shows a clock counting up.
- For a quick test set `jump_time` to 30 in `tuning.tres`: at 0:30 the
  match ends. Put it back to 2400.

---

## M2.2 Ship generated from data

*Concepts:* building nodes in code, `StaticBody3D` + `CollisionShape3D` +
`MeshInstance3D`, resources that describe content.

The ship is built from boxes at match start (README decision D1 and D2).
Nothing is hand-placed except each room type's furnishing scene.

### Layout

Fore is -X. `L` = segment length. Segment `i` spans x from `i * L` to
`(i + 1) * L`. The corridor is centred on z = 0. "North" is -Z.

```text
            slot_1   slot_3   slot_4   slot_6   engine_a
           +------+ +------+ +------+ +------+ +------+        north (-Z)
 +------+  |      | |      | |      | |      | |      |  +------+
 |bridge|==+==seg0==+==seg1==+==seg2==+==seg3==+==seg4==+==| pod  |
 +------+  |      | |      | |      | |      | |      |  | bay  |
           +------+ +------+ +------+ +------+ +------+  +------+
            slot_2  cryo_bay  slot_5   slot_7   engine_b       south (+Z)
            <------ Fore ----> <----- Mid ----> <------ Aft ------->
```

Phase 2 room assignment (the host passes this dictionary to the builder;
M4.5 replaces it with a shuffle): `bridge`, `cryo_bay`, `engine_a`,
`engine_b`, `pod_bay` are themselves; `slot_1` = `medbay`, `slot_2` =
`armory`, `slot_4` = `generator`; `slot_3`, `slot_5`, `slot_6`, `slot_7`
are missing from the dictionary, which means sealed (solid wall, no room).

### Files

| File | Action |
| --- | --- |
| `scripts/data/ship_layout.gd`, `data/ship_layout.tres` | new |
| `scripts/data/room_type.gd`, `data/rooms/*.tres` (8 files) | new |
| `scripts/world/ship_builder.gd` | new |
| `scripts/world/zone.gd` | edit |
| `autoload/config.gd` | edit: load data folders |
| `scenes/rooms/furnish/cryo_bay.tscn` | new: 6 pod boxes + 6 `Marker3D` under `SpawnPoints` |

```gdscript
# FILE: scripts/data/ship_layout.gd
class_name ShipLayout
extends Resource
## The shape of the Meridian: sizes in metres plus the fixed slot table.
## Fore is -X; the spine corridor runs along X, centred on z = 0.

const SIDE_NORTH := -1
const SIDE_SOUTH := 1
const SIDE_FORE := 2
const SIDE_AFT := 3

## The 12 room slots. `fixed` is the room type that is always there, or
## &"" for a slot that gets a shuffled room type each match.
const SLOTS: Array[Dictionary] = [
	{"id": &"bridge", "segment": 0, "side": SIDE_FORE, "fixed": &"bridge", "section": "Fore"},
	{"id": &"slot_1", "segment": 0, "side": SIDE_NORTH, "fixed": &"", "section": "Fore"},
	{"id": &"slot_2", "segment": 0, "side": SIDE_SOUTH, "fixed": &"", "section": "Fore"},
	{"id": &"slot_3", "segment": 1, "side": SIDE_NORTH, "fixed": &"", "section": "Fore"},
	{"id": &"cryo_bay", "segment": 1, "side": SIDE_SOUTH, "fixed": &"cryo_bay", "section": "Fore"},
	{"id": &"slot_4", "segment": 2, "side": SIDE_NORTH, "fixed": &"", "section": "Mid"},
	{"id": &"slot_5", "segment": 2, "side": SIDE_SOUTH, "fixed": &"", "section": "Mid"},
	{"id": &"slot_6", "segment": 3, "side": SIDE_NORTH, "fixed": &"", "section": "Mid"},
	{"id": &"slot_7", "segment": 3, "side": SIDE_SOUTH, "fixed": &"", "section": "Mid"},
	{"id": &"engine_a", "segment": 4, "side": SIDE_NORTH, "fixed": &"engine_a", "section": "Aft"},
	{"id": &"engine_b", "segment": 4, "side": SIDE_SOUTH, "fixed": &"engine_b", "section": "Aft"},
	{"id": &"pod_bay", "segment": 4, "side": SIDE_AFT, "fixed": &"pod_bay", "section": "Aft"},
]

## Power section of each corridor segment, fore to aft.
const SEGMENT_SECTIONS: Array[String] = ["Fore", "Fore", "Mid", "Mid", "Aft"]

## Length of one corridor segment (along X).
@export var segment_length: float = 16.0
@export var corridor_width: float = 4.0
@export var corridor_height: float = 3.0
## Room size along the wall that has its door.
@export var room_width: float = 12.0
## Room size going away from its door.
@export var room_depth: float = 10.0
@export var room_height: float = 3.5
@export var wall_thickness: float = 0.2
@export var door_width: float = 2.0
@export var door_height: float = 2.4
## Brightness of the one light in each room and segment.
@export var light_energy: float = 1.0


func get_segment_count() -> int:
	return SEGMENT_SECTIONS.size()


## X of the middle of a corridor segment.
func get_segment_center_x(segment: int) -> float:
	return (segment + 0.5) * segment_length


## Middle of a slot's floor.
func get_slot_center(slot: Dictionary) -> Vector3:
	var away := wall_thickness + room_depth * 0.5
	match slot.side:
		SIDE_FORE:
			return Vector3(-away, 0.0, 0.0)
		SIDE_AFT:
			return Vector3(get_segment_count() * segment_length + away, 0.0, 0.0)
	var z: float = slot.side * (corridor_width * 0.5 + away)
	return Vector3(get_segment_center_x(slot.segment), 0.0, z)


## Inside size of a slot's room in world axes (x, height, z).
func get_slot_size(slot: Dictionary) -> Vector3:
	if slot.side == SIDE_FORE or slot.side == SIDE_AFT:
		return Vector3(room_depth, room_height, room_width)
	return Vector3(room_width, room_height, room_depth)


## Rotation that turns a furnishing scene (authored with its door toward
## -Z) to face this slot's door.
func get_slot_yaw(slot: Dictionary) -> float:
	match slot.side:
		SIDE_NORTH:
			return PI
		SIDE_FORE:
			return -PI * 0.5
		SIDE_AFT:
			return PI * 0.5
	return 0.0


## Floor position of the middle of a slot's doorway.
func get_door_position(slot: Dictionary) -> Vector3:
	var half := wall_thickness * 0.5
	match slot.side:
		SIDE_FORE:
			return Vector3(-half, 0.0, 0.0)
		SIDE_AFT:
			return Vector3(get_segment_count() * segment_length + half, 0.0, 0.0)
	var z: float = slot.side * (corridor_width * 0.5 + half)
	return Vector3(get_segment_center_x(slot.segment), 0.0, z)


## True if the wall holding this slot's door runs along X.
func is_door_wall_along_x(slot: Dictionary) -> bool:
	return slot.side == SIDE_NORTH or slot.side == SIDE_SOUTH
```

```gdscript
# FILE: scripts/data/room_type.gd
class_name RoomType
extends Resource
## One kind of room. One .tres per type in res://data/rooms/.

## Short id, for example &"medbay".
@export var id: StringName = &""
## Name shown to a player who steps inside.
@export var display_name: String = ""
## True for Bridge, Cryo Bay, both engines and the Pod Bay.
@export var is_fixed: bool = false
## Shuffled rooms only: true if the room is in every match.
@export var is_essential: bool = false
## Search containers in the room (GDD: fixed rooms 1, shuffled 2-3,
## Storage 6).
@export var search_spots: int = 2
## The room's stations and props, authored with the door toward -Z and the
## origin at the middle of the floor. May be empty.
@export var furnishing: PackedScene
## Colour of the room's light, so each room has a readable mood.
@export var light_color: Color = Color(0.7, 0.85, 1.0)
```

```gdscript
# FILE: scripts/world/ship_builder.gd
class_name ShipBuilder
extends Node3D
## Builds the whole ship out of boxes from a ShipLayout and a room
## assignment. Runs on every peer with the same assignment, so everyone
## gets the same ship.

## The ship's sizes.
@export var layout: ShipLayout

## Slot id -> the Zone built for that room.
var room_zones: Dictionary = {}
## Corridor zones, fore to aft.
var corridor_zones: Array[Zone] = []
## Slot id -> the furnishing node instanced in that room.
var furnishings: Dictionary = {}

var _wall_material := StandardMaterial3D.new()
var _floor_material := StandardMaterial3D.new()


## Builds everything. `assignment` maps slot id -> room type id; a slot
## that is missing from it is sealed.
func build(assignment: Dictionary) -> void:
	_wall_material.albedo_color = Color(0.55, 0.58, 0.62)
	_wall_material.roughness = 0.85
	_floor_material.albedo_color = Color(0.3, 0.32, 0.36)
	_floor_material.roughness = 0.9
	for segment in layout.get_segment_count():
		_build_segment(segment, assignment)
	for slot: Dictionary in ShipLayout.SLOTS:
		if slot.side == ShipLayout.SIDE_FORE or slot.side == ShipLayout.SIDE_AFT:
			_build_end_wall(slot, assignment.has(slot.id))
		if assignment.has(slot.id):
			_build_room(slot, Config.get_room_type(assignment[slot.id]))
	_link_neighbours()


func _build_segment(segment: int, assignment: Dictionary) -> void:
	var thickness := layout.wall_thickness
	var center_x := layout.get_segment_center_x(segment)
	var length := layout.segment_length
	var slab := Vector3(length, thickness, layout.corridor_width + thickness * 2.0)
	_box(Vector3(center_x, -thickness * 0.5, 0.0), slab, _floor_material)
	_box(Vector3(center_x, layout.corridor_height + thickness * 0.5, 0.0), slab, _wall_material)
	for slot: Dictionary in ShipLayout.SLOTS:
		if slot.segment != segment or not layout.is_door_wall_along_x(slot):
			continue
		var wall_center := layout.get_door_position(slot)
		wall_center.y = layout.room_height * 0.5
		_wall_line(wall_center, length, layout.room_height, true, assignment.has(slot.id))
	var size := Vector3(length, layout.corridor_height, layout.corridor_width)
	var zone := _zone(Vector3(center_x, size.y * 0.5, 0.0), size)
	zone.zone_name = "Spine corridor, segment %d" % (segment + 1)
	zone.kind = "Corridor"
	zone.power_section = ShipLayout.SEGMENT_SECTIONS[segment]
	corridor_zones.append(zone)
	_light(Vector3(center_x, size.y - 0.4, 0.0), length * 0.6, Color(0.6, 0.7, 0.85))


## The wall across one end of the corridor (Bridge or Pod Bay side).
func _build_end_wall(slot: Dictionary, has_room: bool) -> void:
	var center := layout.get_door_position(slot)
	center.y = layout.room_height * 0.5
	var length := layout.room_width + layout.wall_thickness * 2.0
	_wall_line(center, length, layout.room_height, false, has_room)


func _build_room(slot: Dictionary, type: RoomType) -> void:
	var thickness := layout.wall_thickness
	var center := layout.get_slot_center(slot)
	var size := layout.get_slot_size(slot)
	var yaw := layout.get_slot_yaw(slot)
	var slab := Vector3(size.x + thickness * 2.0, thickness, size.z + thickness * 2.0)
	_box(center + Vector3.DOWN * thickness * 0.5, slab, _floor_material)
	_box(center + Vector3.UP * (size.y + thickness * 0.5), slab, _wall_material)
	# The wall on the door side is built by the corridor, so skip it here.
	var door_direction := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		if direction.is_equal_approx(door_direction):
			continue
		var along_x := is_zero_approx(direction.x)
		var half := (size.z if along_x else size.x) * 0.5 + thickness * 0.5
		var wall_center := center + direction * half + Vector3.UP * size.y * 0.5
		var length := (size.x if along_x else size.z) + thickness * 2.0
		_wall_line(wall_center, length, size.y, along_x, false)
	var zone := _zone(center + Vector3.UP * size.y * 0.5, size)
	zone.zone_name = type.display_name
	zone.kind = "Room"
	zone.power_section = slot.section
	zone.slot_id = slot.id
	zone.room_type = type
	room_zones[slot.id] = zone
	_light(center + Vector3.UP * (size.y - 0.4), maxf(size.x, size.z), type.light_color)
	if type.furnishing:
		var furnishing := type.furnishing.instantiate() as Node3D
		furnishing.position = center
		furnishing.rotation.y = yaw
		add_child(furnishing)
		furnishings[slot.id] = furnishing


## A straight wall, optionally with a doorway in the middle.
func _wall_line(
	center: Vector3, length: float, height: float, along_x: bool, with_door: bool
) -> void:
	if not with_door:
		_box(center, _wall_size(length, height, along_x), _wall_material)
		return
	var side_length := (length - layout.door_width) * 0.5
	var offset := (layout.door_width + side_length) * 0.5
	var axis := Vector3.RIGHT if along_x else Vector3.BACK
	var side_size := _wall_size(side_length, height, along_x)
	_box(center - axis * offset, side_size, _wall_material)
	_box(center + axis * offset, side_size, _wall_material)
	var lintel_height := height - layout.door_height
	var lintel_center := Vector3(center.x, layout.door_height + lintel_height * 0.5, center.z)
	_box(lintel_center, _wall_size(layout.door_width, lintel_height, along_x), _wall_material)


func _wall_size(length: float, height: float, along_x: bool) -> Vector3:
	if along_x:
		return Vector3(length, height, layout.wall_thickness)
	return Vector3(layout.wall_thickness, height, length)


## One solid box: something to stand on or bump into, plus what you see.
func _box(center: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	body.add_child(visual)
	add_child(body)


func _zone(center: Vector3, size: Vector3) -> Zone:
	var zone := Zone.new()
	zone.collision_layer = 0
	zone.collision_mask = Layers.PLAYERS | Layers.ALIENS
	zone.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	zone.add_child(collider)
	add_child(zone)
	GameState.register_zone(zone)
	return zone


func _light(at: Vector3, light_range: float, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.omni_range = light_range
	light.light_color = color
	light.light_energy = layout.light_energy
	add_child(light)


## Rooms neighbour their corridor segment; segments neighbour each other.
func _link_neighbours() -> void:
	for i in corridor_zones.size() - 1:
		corridor_zones[i].neighbours.append(corridor_zones[i + 1])
		corridor_zones[i + 1].neighbours.append(corridor_zones[i])
	for slot: Dictionary in ShipLayout.SLOTS:
		if not room_zones.has(slot.id):
			continue
		var room: Zone = room_zones[slot.id]
		var corridor := corridor_zones[slot.segment]
		room.neighbours.append(corridor)
		corridor.neighbours.append(room)
```

### Edits

`scripts/world/zone.gd`: add these public variables, and keep
`players_inside` / `aliens_inside` up to date in `_on_body_entered` and
`_on_body_exited` (an `Alien` body goes in `aliens_inside`):

```gdscript
## Slot id from ShipLayout.SLOTS, or &"" for a corridor segment.
var slot_id: StringName = &""
## What kind of room this is, or null for a corridor segment.
var room_type: RoomType = null
## Zones reachable through one door or along the corridor (and by vent).
var neighbours: Array[Zone] = []
## Players currently inside.
var players_inside: Array[PlayerCharacter] = []
## Aliens currently inside.
var aliens_inside: Array[Alien] = []
```

`autoload/config.gd`: load each data folder into a dictionary keyed by the
resource's `id`, with typed getters (`get_room_type`, later `get_item`,
`get_alien`, ...):

```gdscript
## Room type id -> RoomType.
var room_types: Dictionary = {}


## Loads every .tres in a folder into a dictionary keyed by its `id`.
func load_by_id(folder: String) -> Dictionary:
	var found := {}
	for file: String in ResourceLoader.list_directory(folder):
		if not file.ends_with(".tres"):
			continue
		var resource := load(folder.path_join(file))
		if resource and resource.get("id"):
			found[resource.get("id")] = resource
	return found


func get_room_type(id: StringName) -> RoomType:
	return room_types.get(id) as RoomType
```

Call `room_types = load_by_id("res://data/rooms")` in `_enter_tree`.

`data/rooms/`: `bridge`, `cryo_bay`, `engine_a`, `engine_b`, `pod_bay`
(`is_fixed = true`, `search_spots = 1`), `medbay`, `armory`, `generator`
(`is_essential = true`, `search_spots = 2`). Give each a different
`light_color` (Medbay green-white, Armory amber, engines orange, Bridge
cold blue, Pod Bay red).

### Owner checks

- You start in the Cryo Bay; the corridor outside runs left to right.
- Walking the corridor, the debug overlay names segments 1 to 5 and the
  power section changes Fore, Mid, Aft.
- Eight doorways lead to rooms; the overlay shows each room's name.
  Bridge is at one end, Pod Bay at the other.
- No holes in floors or walls; you cannot leave the ship.
- *Debug > Visible Navigation*: blue floor everywhere, joined through
  every doorway.

---

## M2.3 Interaction system

*Concepts:* `Area3D` used as a "thing you can look at", raycasts that hit
areas.

One system serves every door, terminal, container, pickup and pod in the
game: look at it, see a prompt, press or hold a button. Two kinds of use:

- **E**: the interactable's own action ("Open", "Search").
- **Hand button** while holding the right item: an item action on the
  thing you look at ("Weld" with a welder, "Insert" with a power cell).
  This is added to the same class in M2.4.

### Files

| File | Action |
| --- | --- |
| `scripts/core/hold_action.gd` | new |
| `scripts/world/interactable.gd` | new |
| `scripts/player/player_interactor.gd` | new; add as child `Interactor` of the player |
| `scripts/player/input_state.gd`, `player_input.gd` | edit: add held `interact_held` |
| HUD | edit: prompt label and `ProgressBar` under the crosshair |

```gdscript
# FILE: scripts/core/hold_action.gd
class_name HoldAction
extends RefCounted
## Tracks "hold a button for N seconds on one target".
##
## Call `update` every physics frame. It returns true exactly once, when
## the hold completes; the button must then be released before it can
## start again. Looking at a different target restarts the timer.

## Seconds held so far on the current target.
var progress: float = 0.0

var _target: Variant = null
var _needs_release := false


func update(held: bool, target: Variant, seconds: float, delta: float) -> bool:
	if not held or target == null:
		progress = 0.0
		_target = null
		_needs_release = _needs_release and held
		return false
	if _needs_release:
		return false
	if target != _target:
		_target = target
		progress = 0.0
	progress += delta
	if progress < seconds:
		return false
	progress = 0.0
	_needs_release = true
	return true


## Progress from 0 to 1, for the HUD bar.
func get_fraction(seconds: float) -> float:
	if seconds <= 0.0:
		return 0.0
	return clampf(progress / seconds, 0.0, 1.0)
```

```gdscript
# FILE: scripts/world/interactable.gd
class_name Interactable
extends Area3D
## Something a player can look at and use. Give it a CollisionShape3D.
##
## Simple cases: set the exports and connect to `interacted`.
## Complex cases (doors, stations): extend this class and override
## `get_prompt`, `get_hold_seconds`, `can_interact` and `_on_interact`.

## Emitted on the host when a player completes the interaction.
signal interacted(player: PlayerCharacter)

## Text after the key, for example "Search". Empty hides the prompt.
@export var prompt: String = "Use"
## Seconds the key must be held. 0 = instant.
@export var hold_seconds: float = 0.0
## Noise added to the player's zone on completion.
@export var noise: float = 0.0

## When false the interactable cannot be used and shows no prompt.
var enabled := true


func _ready() -> void:
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	monitoring = false


## Prompt for this player right now. Override for changing prompts.
func get_prompt(_player: PlayerCharacter) -> String:
	return prompt


## Hold time for this player right now.
func get_hold_seconds(_player: PlayerCharacter) -> float:
	return hold_seconds


## Whether this player may use it right now.
func can_interact(_player: PlayerCharacter) -> bool:
	return enabled


## Called on the acting player's machine when the hold completes.
func request_interact(player: PlayerCharacter) -> void:
	# Phase 3: send an RPC to the host instead when not the server.
	_host_interact(player)


## Host only: checks the request and applies it.
func _host_interact(player: PlayerCharacter) -> void:
	if player.is_dead or not can_interact(player) or not _is_in_reach(player):
		return
	if noise > 0.0:
		player.emit_noise(noise)
	_on_interact(player)
	interacted.emit(player)


## Override in subclasses: what the interaction does.
func _on_interact(_player: PlayerCharacter) -> void:
	pass


func _is_in_reach(player: PlayerCharacter) -> bool:
	var reach := Config.tuning.interact_range + Config.tuning.interact_range_slack
	return player.head.global_position.distance_to(global_position) <= reach + _get_radius()


## Rough size of the interactable, so big ones can be used from their edge.
func _get_radius() -> float:
	for child: Node in get_children():
		var collider := child as CollisionShape3D
		if collider and collider.shape is BoxShape3D:
			return (collider.shape as BoxShape3D).size.length() * 0.5
	return 0.0
```

```gdscript
# FILE: scripts/player/player_interactor.gd
class_name PlayerInteractor
extends Node
## Finds what the player is looking at and runs the hold-to-use timer.
## Child of the player, named "Interactor". Only runs for the local player.

## The interactable under the crosshair, or null.
var focused: Interactable = null
## The hold timer for the interact key (the HUD reads its progress).
var hold := HoldAction.new()


## Call every physics frame from the character.
func update(player: PlayerCharacter, interact_held: bool, delta: float) -> void:
	focused = _find_focus(player)
	var usable := focused != null and focused.can_interact(player)
	var target: Variant = focused if usable else null
	var seconds := focused.get_hold_seconds(player) if usable else 0.0
	if hold.update(interact_held, target, seconds, delta):
		focused.request_interact(player)


## Text for the HUD, for example "[E] Search (hold)". Empty if nothing.
func get_prompt_text(player: PlayerCharacter) -> String:
	if focused == null or not focused.can_interact(player):
		return ""
	var text := focused.get_prompt(player)
	if text.is_empty():
		return ""
	if focused.get_hold_seconds(player) > 0.0:
		return "[E] %s (hold)" % text
	return "[E] %s" % text


func _find_focus(player: PlayerCharacter) -> Interactable:
	var from := player.camera.global_position
	var to := from - player.camera.global_basis.z * Config.tuning.interact_range
	var mask := Layers.WORLD | Layers.DOORS | Layers.INTERACTABLES
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	query.collide_with_areas = true
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.collider as Interactable
```

`InputState`: add `var interact_held := false` (cleared in
`release_all`). `PlayerInput.poll`: `state.interact_held =
Input.is_action_pressed("interact")`. `PlayerCharacter._physics_process`:
call `interactor.update(self, input.interact_held, delta)` when not dead.

Test object: put an `Interactable` box in the Cryo Bay furnishing with
`prompt = "Test"`, `hold_seconds = 2`, `noise = 1`, connected to print.

### Tuning (`@export_group("Interaction")`)

| Name | Value | Doc comment |
| --- | --- | --- |
| `interact_range` | 2.5 | How far the player can reach, in metres. |
| `interact_range_slack` | 1.0 | Extra reach the host allows, to forgive network lag. |

### Owner checks

- Looking at the test box within 2.5 m shows "[E] Test (hold)".
- Holding E fills the bar in 2 s, then the zone noise rises by 1 and the
  bar resets; holding on does not repeat until E is released.
- Looking away mid-hold cancels it. A wall between you and the box hides
  the prompt.

---

## M2.4 Items and inventory

*Concepts:* `RefCounted` objects (plain data that is not a node),
dictionaries.

GDD rules: 2 hands + 4 slots; only hand items can be used; hand to slot
takes 0.75 s; two-handed items fill both hands; small items stack to 3;
drop is instant; pick-up takes 0.5 s.

Calls made here (README D5 plus two new ones to confirm with the owner):

- **Two-handed items cannot be put in a slot.** That is what makes
  carrying the power cell a real job.
- **Ammo boxes are used with a reload hold** (R, 2 s) while the gun is in
  a hand; the box may be anywhere in the inventory. Otherwise a two-handed
  rifle could never be reloaded.

### Files

| File | Action |
| --- | --- |
| `scripts/data/item_data.gd`, `data/items/*.tres` | new |
| `scripts/player/item_stack.gd` | new |
| `scripts/player/inventory.gd` | new; child `Inventory` of the player |
| `scripts/player/item_user.gd` | new; child `ItemUser` of the player |
| `scripts/world/pickup.gd`, `scenes/items/pickup.tscn` | new |
| `scripts/world/interactable.gd` | edit: item actions |
| `scripts/weapons/hitscan_weapon.gd` | edit: rounds live in the stack |
| `scenes/player/player.tscn` | edit: remove the fixed `Pistol`; add `HandMain`, `HandOff` (`Node3D`) under the camera |
| `input_setup.gd`, `input_state.gd`, `player_input.gd` | edit: new actions |
| HUD | edit: hands and slots, bottom centre |

```gdscript
# FILE: scripts/data/item_data.gd
class_name ItemData
extends Resource
## One kind of item. One .tres per item in res://data/items/.

enum UseKind { NONE, HITSCAN, MELEE, THROWN, HEAL_LIGHT, DRESS_WOUND, SCANNER, AMMO, TOOL }

## Short id, for example &"medkit".
@export var id: StringName = &""
## Name on the HUD.
@export var display_name: String = ""
## True if the item needs both hands and cannot go in a slot.
@export var two_handed: bool = false
## How many fit in one hand or slot (3 for small items, otherwise 1).
@export var stack_limit: int = 1
## What happens when its hand button is pressed with nothing to use it on.
@export var use_kind: UseKind = UseKind.NONE
## Seconds the hand button must be held to use it on yourself.
@export var use_seconds: float = 0.0
## Hitscan weapons: the gun's numbers.
@export var weapon: WeaponData
## Melee weapons: damage to aliens per hit.
@export var melee_damage: float = 0.0
## Rounds, charges or uses when full. 0 = the item has none.
@export var max_charges: int = 0
## True if using it up removes one from the stack.
@export var consumed_on_use: bool = false
## What the player sees in their hand. Empty = a coloured box.
@export var view_scene: PackedScene
## Colour of the grey-box pickup and hand box.
@export var color: Color = Color(0.8, 0.8, 0.8)
```

```gdscript
# FILE: scripts/player/item_stack.gd
class_name ItemStack
extends RefCounted
## One hand or slot's contents: an item type, how many, and its charges.

var data: ItemData
var count: int = 1
## Rounds, charges or uses left (weapons, scanner, extinguisher...).
var charges: int = 0


static func create(item: ItemData, amount: int = 1) -> ItemStack:
	var stack := ItemStack.new()
	stack.data = item
	stack.count = amount
	stack.charges = item.max_charges
	return stack


## For sending over the network (Phase 3).
func to_dict() -> Dictionary:
	return {"id": data.id, "count": count, "charges": charges}


static func from_dict(dict: Dictionary) -> ItemStack:
	var stack := ItemStack.new()
	stack.data = Config.get_item(dict.id)
	stack.count = dict.count
	stack.charges = dict.charges
	return stack
```

```gdscript
# FILE: scripts/player/inventory.gd
class_name Inventory
extends Node
## What a player carries: 2 hands and a few slots (GDD "Inventory").
##
## A two-handed item sits in hand 0 and blocks hand 1. Only the host
## changes an inventory; the owner gets a copy (Phase 3).

## Emitted after any change.
signal changed

const MAIN_HAND := 0
const OFF_HAND := 1

## Hand contents; null = empty.
var hands: Array[ItemStack] = [null, null]
## Slot contents; null = empty.
var slots: Array[ItemStack] = []
## 1 with a broken arm, otherwise 2 (set from PlayerWounds).
var usable_hands: int = 2


func _ready() -> void:
	slots.resize(Config.tuning.inventory_slots)


## True if nothing is in the hand and nothing blocks it.
func is_hand_free(hand: int) -> bool:
	if hand >= usable_hands or hands[hand] != null:
		return false
	return not (hand == OFF_HAND and _holds_two_handed())


## Puts a stack into the inventory: tops up matching stacks first, then a
## free hand, then a free slot. Returns true if all of it fitted. If only
## part fitted, `stack.count` is what is left over.
func add(stack: ItemStack) -> bool:
	if stack.data.stack_limit > 1:
		_merge_into_existing(stack)
		if stack.count <= 0:
			changed.emit()
			return true
	if stack.data.two_handed:
		if not (is_hand_free(MAIN_HAND) and is_hand_free(OFF_HAND)):
			return false
		hands[MAIN_HAND] = stack
		changed.emit()
		return true
	for hand in hands.size():
		if is_hand_free(hand):
			hands[hand] = stack
			changed.emit()
			return true
	var slot := slots.find(null)
	if slot == -1:
		changed.emit()
		return false
	slots[slot] = stack
	changed.emit()
	return true


## Swaps a hand with a slot. Two-handed items cannot be stowed.
func swap_hand_slot(hand: int, slot: int) -> bool:
	if hand >= usable_hands or (hand == OFF_HAND and _holds_two_handed()):
		return false
	if hands[hand] != null and hands[hand].data.two_handed:
		return false
	var from_slot := slots[slot]
	slots[slot] = hands[hand]
	hands[hand] = from_slot
	changed.emit()
	return true


func swap_hands() -> bool:
	if usable_hands < 2 or _holds_two_handed():
		return false
	var main := hands[MAIN_HAND]
	hands[MAIN_HAND] = hands[OFF_HAND]
	hands[OFF_HAND] = main
	changed.emit()
	return true


## Empties a hand and returns what was in it (for dropping).
func take_from_hand(hand: int) -> ItemStack:
	var stack := hands[hand]
	hands[hand] = null
	if stack:
		changed.emit()
	return stack


## Uses up one item from a hand's stack.
func consume_from_hand(hand: int) -> void:
	var stack := hands[hand]
	if stack == null:
		return
	stack.count -= 1
	if stack.count <= 0:
		hands[hand] = null
	changed.emit()


## True if a hand holds this item (keycard, welder, toolkit checks).
func holds(id: StringName) -> bool:
	for stack: ItemStack in hands:
		if stack != null and stack.data.id == id:
			return true
	return false


## How many of an item are carried anywhere.
func count_of(id: StringName) -> int:
	var total := 0
	for stack: ItemStack in get_all_stacks():
		if stack.data.id == id:
			total += stack.count
	return total


## Removes `amount` of an item from anywhere. False if there are too few.
func consume(id: StringName, amount: int = 1) -> bool:
	if count_of(id) < amount:
		return false
	var left := amount
	for list: Array[ItemStack] in [hands, slots]:
		for i in list.size():
			var stack := list[i]
			if stack == null or stack.data.id != id or left <= 0:
				continue
			var used := mini(stack.count, left)
			stack.count -= used
			left -= used
			if stack.count <= 0:
				list[i] = null
	changed.emit()
	return true


## Every stack carried, hands first.
func get_all_stacks() -> Array[ItemStack]:
	var all: Array[ItemStack] = []
	for stack: ItemStack in hands + slots:
		if stack != null:
			all.append(stack)
	return all


## Broken arm: sets the usable hands and returns what must be dropped.
func set_usable_hands(count: int) -> Array[ItemStack]:
	usable_hands = count
	var dropped: Array[ItemStack] = []
	if count < 2:
		if _holds_two_handed():
			dropped.append(take_from_hand(MAIN_HAND))
		elif hands[OFF_HAND] != null:
			dropped.append(take_from_hand(OFF_HAND))
	return dropped


func _holds_two_handed() -> bool:
	return hands[MAIN_HAND] != null and hands[MAIN_HAND].data.two_handed


func _merge_into_existing(stack: ItemStack) -> void:
	for existing: ItemStack in get_all_stacks():
		if existing.data.id != stack.data.id:
			continue
		var room := existing.data.stack_limit - existing.count
		var moved := mini(room, stack.count)
		existing.count += moved
		stack.count -= moved
		if stack.count <= 0:
			return
```

Item actions on `Interactable` (add to `interactable.gd`):

```gdscript
## Emitted on the host when a player uses a held item on this.
signal item_used(player: PlayerCharacter, item: ItemData)


## Prompt for using `item` on this, or "" if the item does nothing here.
func get_item_prompt(_player: PlayerCharacter, _item: ItemData) -> String:
	return ""


## Hold time for using `item` on this.
func get_item_seconds(_player: PlayerCharacter, _item: ItemData) -> float:
	return 0.0


## Called on the acting player's machine when the hold completes.
func request_use_item(player: PlayerCharacter, hand: int) -> void:
	# Phase 3: send an RPC to the host instead when not the server.
	_host_use_item(player, hand)


func _host_use_item(player: PlayerCharacter, hand: int) -> void:
	var stack := player.inventory.hands[hand]
	if stack == null or player.is_dead or not _is_in_reach(player):
		return
	if get_item_prompt(player, stack.data).is_empty():
		return
	_on_item_used(player, stack.data, hand)
	item_used.emit(player, stack.data)


## Override in subclasses: what using the item here does.
func _on_item_used(_player: PlayerCharacter, _item: ItemData, _hand: int) -> void:
	pass
```

**`ItemUser`** (`scripts/player/item_user.gd`), called every physics frame
with the two hand buttons. For each hand, in this order:

1. If a hand-to-slot move is in progress (0.75 s timer), do nothing else.
2. If the hand is empty: the main hand punches (M4.6); nothing in Phase 2.
3. If `interactor.focused` returns a non-empty `get_item_prompt` for the
   held item: run a `HoldAction` for `get_item_seconds`, then
   `focused.request_use_item(player, hand)`.
4. Otherwise act on `use_kind`:
   - `HITSCAN`: forward the button to the hand's `HitscanWeapon` view
     (`update_trigger`).
   - `HEAL_LIGHT` / `DRESS_WOUND`: `HoldAction` for `use_seconds`, then
     `request_use_on_self(hand)`; the host calls `wounds.heal_light()` or
     `wounds.dress_one()` and, if it did something, `consume_from_hand`.
5. Reload (`R` held, `ammo_reload_seconds`): if a hand holds a `HITSCAN`
   item that is not full and `inventory.count_of(&"ammo_box") > 0`, the
   host consumes one box and fills the weapon.

Hand views: when `inventory.changed` fires, `ItemUser` frees the children
of `HandMain` / `HandOff` and instances the new item's `view_scene` (or a
small coloured box). `HitscanWeapon` gets a `var stack: ItemStack`; set
`rounds = stack.charges` on equip and write `stack.charges = rounds` after
each shot and reload, so ammo survives being stowed or dropped.
`PlayerCharacter.weapon` becomes a getter returning the main hand's view if
it is a `HitscanWeapon`; the HUD reconnects on `inventory.changed`.

Other pieces:

- `PlayerCharacter`: `@onready var inventory: Inventory = $Inventory`. On
  `wounds.changed`, call `inventory.set_usable_hands(
  wounds.get_usable_hands())` and drop what it returns.
- Slot keys `1`-`4`: start a `hand_slot_swap_seconds` timer, then
  `inventory.swap_hand_slot(Inventory.MAIN_HAND, n)`. `X`:
  `swap_hands()`. `G`: `take_from_hand` and spawn a pickup 1 m in front of
  the player on the floor.
- `Pickup` (extends `Interactable`): holds an `ItemStack`; prompt "Take
  (name)", hold `pickup_seconds`; `_on_interact` calls
  `player.inventory.add(stack)` and frees itself when `stack.count == 0`.
  It builds its own box mesh and collision from `stack.data.color`.
- `Config`: `items = load_by_id("res://data/items")` and
  `get_item(id) -> ItemData`.

Items to create now (values from the GDD tables):

| id | hands | stack | use | notes |
| --- | --- | --- | --- | --- |
| `pistol` | 1 | 1 | HITSCAN | `weapon` = `pistol.tres`, `max_charges` 8, view `pistol.tscn` |
| `ammo_box` | 1 | 3 | AMMO | used through reload |
| `medkit` | 1 | 1 | HEAL_LIGHT | 3 s, consumed |
| `bandage` | 1 | 3 | DRESS_WOUND | 3 s, consumed |
| `keycard` | 1 | 1 | TOOL | used on doors |
| `welder` | 1 | 1 | TOOL | used on doors; melee in M4.6 |
| `power_cell` | 2 | 1 | TOOL | used on the pod socket |

For testing, `match.gd` gives the player a pistol and drops one of each
other item on the Cryo Bay floor.

### Tuning (`@export_group("Inventory")`)

| Name | Value | Doc comment |
| --- | --- | --- |
| `inventory_slots` | 4 | Slots besides the two hands. |
| `hand_slot_swap_seconds` | 0.75 | Time to move an item between a hand and a slot. |
| `pickup_seconds` | 0.5 | Time to pick an item up. |
| `ammo_reload_seconds` | 2.0 | Time to reload a gun from an ammo box. |
| `drop_distance` | 1.0 | How far in front of the player a dropped item lands. |

### Owner checks

- The HUD shows two hands and four slots; the pistol is in the main hand
  and still fires; its ammo count survives stowing (key 1) and drawing it.
- Picking up three bandages makes one stack of 3; a fourth starts a new
  stack.
- The power cell cannot be picked up with anything in either hand, and
  cannot be stowed.
- Medkit: hold left mouse 3 s with light wounds (F5 debug key) heals them
  and the medkit is gone. With no light wounds nothing is used up.
- R with an ammo box in a slot refills the pistol in 2 s and uses the box.
- G drops the main hand item in front of you; it can be picked up again.
- With a *Broken arm* (F6 until you get one) the off-hand item drops and
  the power cell cannot be picked up.

---

## M2.5 Doors

GDD door table: open/closed (anyone, instant, silent); locked (60 s;
keycard holders pass); welded (welder 4 s to weld or cut). Power-loss
behaviour and alien door-breaking are added in M4.3 and M4.2.

### Files

| File | Action |
| --- | --- |
| `scripts/world/door.gd` | new |
| `scripts/world/ship_builder.gd` | edit: one `Door` per open doorway; store it as `zone.door` |
| `scripts/aliens/alien.gd` | edit: react to closed doors |
| `data/tuning.tres` | edit |

```gdscript
# FILE: scripts/world/door.gd
class_name Door
extends Interactable
## A sliding door in a doorway. It is its own Interactable: E opens and
## closes it, a held welder welds or cuts it, a held keycard passes a lock.
##
## Build with `Door.create(...)`. The slab is on the "doors" layer so it
## blocks bodies and bullets but does not cut the navigation mesh.

## Emitted on every change of open / locked / welded.
signal state_changed

var is_open := false
var is_welded := false
## Seconds of lock left; 0 = not locked.
var lock_seconds: float = 0.0

var _slab: StaticBody3D
var _slab_collider: CollisionShape3D
var _closed_height := 0.0


## Makes a door that fills a doorway of the given size. `along_x` is true
## if the wall it sits in runs along X.
static func create(width: float, height: float, thickness: float, along_x: bool) -> Door:
	var door := Door.new()
	var size := Vector3(width, height, thickness) if along_x else Vector3(thickness, height, width)
	door._closed_height = height * 0.5
	door._slab = StaticBody3D.new()
	door._slab.collision_layer = Layers.DOORS
	door._slab.collision_mask = 0
	door._slab.position.y = door._closed_height
	var slab_shape := BoxShape3D.new()
	slab_shape.size = size
	door._slab_collider = CollisionShape3D.new()
	door._slab_collider.shape = slab_shape
	door._slab.add_child(door._slab_collider)
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.45, 0.1)
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	door._slab.add_child(visual)
	door.add_child(door._slab)
	# The look-at area is a little fatter than the slab so the crosshair
	# ray reaches it first, and it stays in the doorway when the door is open.
	var area_shape := BoxShape3D.new()
	area_shape.size = size + Vector3.ONE * 0.2
	var area_collider := CollisionShape3D.new()
	area_collider.shape = area_shape
	area_collider.position.y = door._closed_height
	door.add_child(area_collider)
	return door


func _physics_process(delta: float) -> void:
	if lock_seconds <= 0.0 or not multiplayer.is_server():
		return
	lock_seconds = maxf(lock_seconds - delta, 0.0)
	if lock_seconds <= 0.0:
		state_changed.emit()


func is_locked() -> bool:
	return lock_seconds > 0.0


func get_prompt(player: PlayerCharacter) -> String:
	if is_welded:
		return "Welded shut"
	if is_locked() and not player.inventory.holds(&"keycard"):
		return "Locked (%d s)" % ceili(lock_seconds)
	return "Close" if is_open else "Open"


func can_interact(player: PlayerCharacter) -> bool:
	if is_welded:
		return false
	return not is_locked() or player.inventory.holds(&"keycard")


func get_item_prompt(_player: PlayerCharacter, item: ItemData) -> String:
	if item.id != &"welder" or is_open:
		return ""
	return "Cut open" if is_welded else "Weld shut"


func get_item_seconds(_player: PlayerCharacter, _item: ItemData) -> float:
	return Config.tuning.weld_seconds


## Host only: locks the door for a while (Security terminal).
func lock(seconds: float) -> void:
	lock_seconds = seconds
	state_changed.emit()


## Host only: releases the lock (timer ran out, or the section lost power).
func unlock() -> void:
	lock_seconds = 0.0
	state_changed.emit()


## Host only: opens or closes the door. Phase 3 syncs this to clients.
func set_open(open: bool) -> void:
	if is_open == open:
		return
	is_open = open
	_slab_collider.set_deferred("disabled", open)
	var target := _closed_height * 3.0 if open else _closed_height
	var slide := create_tween()
	slide.tween_property(_slab, "position:y", target, Config.tuning.door_slide_seconds)
	state_changed.emit()


## Host only: true if this alien may pass. Opens the door for it if so.
func let_alien_through(_alien: Alien) -> bool:
	if is_open:
		return true
	if is_welded or is_locked():
		return false
	set_open(true)
	return true


func _on_interact(_player: PlayerCharacter) -> void:
	set_open(not is_open)


func _on_item_used(_player: PlayerCharacter, _item: ItemData, _hand: int) -> void:
	is_welded = not is_welded
	state_changed.emit()
```

`ShipBuilder._build_room`: after the zone is made,

```gdscript
func _add_door(slot: Dictionary, zone: Zone) -> void:
	var door := Door.create(
		layout.door_width,
		layout.door_height,
		layout.wall_thickness,
		layout.is_door_wall_along_x(slot)
	)
	door.position = layout.get_door_position(slot)
	add_child(door)
	zone.door = door
```

and add `var door: Door = null` to `Zone` ("the door between this room and
the corridor; null for corridor segments").

Aliens and doors (`alien.gd`): each physics frame while moving, if the
alien is within `alien_door_reach` of a closed door in its current zone or
the zone it is heading into, call `door.let_alien_through(self)`. If that
returns false, stop, drop the target and `go_to` a random point in its own
zone for `alien_blocked_seconds` before trying again. (M4.2 adds breaking
doors; M4.1 adds going around through vents.) To know its zone, `Alien`
gets the same `enter_zone` / `exit_zone` / `current_zone` code as
`PlayerCharacter`; move that code into a small shared helper
(`scripts/world/zone_tracker.gd`, a `RefCounted` holding the stack of
zones) and use it in both.

Sight through doors already works: `_can_see` in `alien.gd` includes
`Layers.DOORS`, and an open door's collider is disabled.

### Tuning (`@export_group("Doors")`)

| Name | Value | Doc comment |
| --- | --- | --- |
| `weld_seconds` | 4.0 | Time to weld a door or vent shut, or cut it open. |
| `door_lock_seconds` | 60.0 | How long a Security terminal lock lasts. |
| `door_slide_seconds` | 0.3 | How long the door takes to slide. |
| `alien_door_reach` | 1.5 | Distance at which an alien deals with a closed door. |
| `alien_blocked_seconds` | 4.0 | How long an alien waits at a door it cannot pass. |

### Owner checks

- Every room has an orange door; E opens and closes it instantly and adds
  no noise.
- A Crawler chasing you opens a closed door by itself.
- With the welder in a hand, looking at a closed door offers "Weld shut";
  after 4 s the door cannot be opened with E and Crawlers stop at it.
  Welding again cuts it open.
- Debug key F8 locks the door you are looking at for 60 s: it shows
  "Locked (57 s)"; with the keycard in a hand it opens.
- Bullets do not pass a closed door; they pass an open one.

---

## M2.6 Loot deck, search containers, stations

GDD: each search takes 2 s, makes 1 noise and draws one card from a shared
loot deck; containers beyond the deck are empty. Fixed rooms and corridor
segments have 1 container each; shuffled rooms 2-3.

### Files

| File | Action |
| --- | --- |
| `scripts/data/loot_table.gd`, `data/loot_table.tres` | new |
| `scripts/match/loot_deck.gd` | new |
| `scripts/world/search_spot.gd` | new |
| `scripts/world/stations/*.gd` | new: `rest_bed`, `surgery_pod`, `ammo_locker`, `gun_rack` |
| `scenes/rooms/furnish/*.tscn` | new: medbay, armory, generator, bridge, engines, pod bay |
| `scripts/world/ship_builder.gd` | edit: place search spots |

```gdscript
# FILE: scripts/data/loot_table.gd
class_name LootTable
extends Resource
## How many of each loot card are in the deck (GDD "Searching" table).

## Item id -> counts for [3 players, 4-5 players, 6 players].
@export var cards: Dictionary = {
	&"ammo_box": PackedInt32Array([4, 4, 5]),
	&"medkit": PackedInt32Array([2, 2, 2]),
	&"bandage": PackedInt32Array([2, 2, 3]),
	&"chemicals": PackedInt32Array([2, 2, 3]),
	&"rag": PackedInt32Array([1, 2, 2]),
	&"duct_tape": PackedInt32Array([2, 3, 3]),
	&"pipe": PackedInt32Array([1, 2, 2]),
	&"battery": PackedInt32Array([2, 2, 3]),
	&"grenade": PackedInt32Array([1, 1, 1]),
	&"keycard": PackedInt32Array([1, 1, 1]),
	&"toolkit": PackedInt32Array([1, 1, 1]),
	&"extinguisher": PackedInt32Array([1, 2, 2]),
	&"o2_mask": PackedInt32Array([1, 1, 1]),
	&"flashlight": PackedInt32Array([1, 1, 1]),
}


## Column of the table for a player count.
static func column_for(player_count: int) -> int:
	if player_count <= 3:
		return 0
	if player_count <= 5:
		return 1
	return 2
```

```gdscript
# FILE: scripts/match/loot_deck.gd
class_name LootDeck
extends RefCounted
## The shared, hidden deck that search containers draw from. Host only.

var _cards: Array[StringName] = []


## Fills and shuffles the deck. `extra` holds cards added by the GDD's
## "missing role" rules (keycard, toolkit, radio). Items that do not exist
## yet in res://data/items are left out.
func setup(table: LootTable, player_count: int, extra: Array[StringName] = []) -> void:
	_cards.clear()
	var column := LootTable.column_for(player_count)
	for id: StringName in table.cards:
		var counts: PackedInt32Array = table.cards[id]
		for _i in counts[column]:
			_add_card(id)
	for id: StringName in extra:
		_add_card(id)
	_cards.shuffle()


## Takes the top card. Returns &"" when the deck is empty.
func draw() -> StringName:
	if _cards.is_empty():
		return &""
	return _cards.pop_back()


func get_size() -> int:
	return _cards.size()


func _add_card(id: StringName) -> void:
	if Config.get_item(id) != null:
		_cards.append(id)
```

- The deck lives on `match.gd` as `var loot_deck := LootDeck.new()`
  (host only; never synced).
- `SearchSpot` (extends `Interactable`): `prompt = "Search"`,
  `hold_seconds = search_seconds`, `noise = search_noise`. `_on_interact`:
  draw a card; if not empty, make an `ItemStack` and `inventory.add` it,
  or spawn a `Pickup` at the container if it does not fit; then set
  `enabled = false` and tell the player "Empty" or the item's name through
  a HUD message (`player.show_message(text)`; in Phase 3 this is an
  owner-only RPC).
- `ShipBuilder` places `room_type.search_spots` crates along the back wall
  of each room (evenly spaced) and one crate per corridor segment against
  a side wall, clear of doorways.

Stations (each a small script extending `Interactable`, placed in the
furnishing scenes):

| Station | Room | Hold | Noise | Effect on the host |
| --- | --- | --- | --- | --- |
| Rest bed | Medbay | 8 s | 0 | `wounds.heal_light()` |
| Surgery pod | Medbay | 12 s | 2 | `wounds.remove_one_serious()` (M5.2 adds the contamination choice) |
| Ammo locker | Armory | 2 s | 0 | Refills the hitscan weapon in the player's hand; 3 refills for the whole crew, then "Empty" |
| Gun rack | Armory | 0.5 s | 0 | Gives its one gun (pistol now; pistol or shotgun at random from M4.6) |
| Power cell | Generator | pickup | 0 | A `Pickup` holding `power_cell` |

Furnishing scenes are authored for a 12 x 10 m room with the origin at the
middle of the floor and the door on the -Z wall: keep everything within
x = -5.5..5.5, z = -4.5..4.5, and keep a 2 m wide path clear from the door.

### Tuning (`@export_group("Stations")`)

`search_seconds` 2.0, `search_noise` 1.0, `rest_bed_seconds` 8.0,
`surgery_seconds` 12.0, `surgery_noise` 2.0, `armory_refills` 3,
`gun_rack_seconds` 0.5.

### Owner checks

- Each room has crates; searching takes 2 s, adds 1 noise and gives an
  item or says "Empty". A searched crate cannot be searched again.
- Across the whole ship you find a keycard, medkits, bandages and several
  ammo boxes (cards for items that do not exist yet are skipped); some
  crates are empty once the deck runs out.
- The rest bed heals light wounds; the surgery pod removes a serious one.
- The ammo locker works three times, then says "Empty".
- The power cell sits in the Generator room and needs both hands.

---

## M2.7 Escape pods, the jump, end screen

GDD: pods are locked until a power cell is inserted in the Pod Bay socket
(5 s); boarding takes 2 s; a seated player holds to start a 10 s launch
(+5 noise). At 40:00 anyone still awake aboard dies.

### Files

| File | Action |
| --- | --- |
| `scripts/match/ship_state.gd` | new: host-only ship facts |
| `scripts/world/stations/pod_socket.gd`, `escape_pod.gd` | new |
| `scenes/rooms/furnish/pod_bay.tscn` | edit: socket + 3 pods |
| `scripts/aliens/timer_director.gd` | new: temporary Crawler spawner |
| `scripts/ui/end_screen.gd`, `scenes/ui/end_screen.tscn` | new |
| `scripts/match/match.gd` | edit |

`ShipState` (a `RefCounted` owned by `match.gd`, host only) starts small
and grows in Phases 4 and 5:

```gdscript
# FILE: scripts/match/ship_state.gd
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
var engine_working: Array[bool] = [true, true]
var course: Course = Course.EARTH
## True once the ship has been destroyed.
var destroyed := false


## Random start: at least one engine damaged, course unknown.
func randomize_start() -> void:
	engine_working[0] = randf() < 0.5
	engine_working[1] = randf() < 0.5
	if engine_working[0] and engine_working[1]:
		engine_working[randi_range(0, 1)] = false
	course = randi_range(0, Course.size() - 1) as Course
```

- **Pod socket** (`Interactable`): `get_item_prompt` returns "Insert power
  cell" for `power_cell` while pods are locked; 5 s; on use, consume the
  cell, set `ship_state.pods_unlocked = true`, turn the pod lights green
  (public, synced state).
- **Escape pod** (`Interactable`): prompt "Pods locked" (disabled) until
  unlocked; then "Board" (2 s). Boarding moves the player into the seat,
  sets `player.seated_pod`, and disables movement (`input_source.enabled`
  stays on for look and the E key only). While seated: E tap = get out;
  E hold `pod_launch_hold_seconds` = start the launch. The launch is a
  10 s countdown shown to those seated, adds +5 noise to the Pod Bay at
  the start, then calls `match.on_pod_launched(pod)`.
- **Phase 2 ending:** on launch, `GameState.end_match(&"escaped")`. On the
  player's death, `GameState.end_match(&"died")`. At `jump_time`,
  `&"jump"` (shown as "Left behind at the jump").
- **End screen:** a `CanvasLayer` with the result text, the clock, aliens
  killed, and "Press R to play again" (reloads `match.tscn`).
- **Timer director** (temporary, deleted in M4.1): after the grace
  period, every `slice_spawn_interval` seconds, if fewer than
  `slice_max_aliens` are alive, spawn a Crawler in the middle of a random
  open room that has no player in it. It must use the same
  `match.spawn_alien(alien_id, position)` function M4.1 will use.

### Tuning (`@export_group("Escape")`)

`pod_socket_seconds` 5.0, `pod_board_seconds` 2.0, `pod_launch_hold_seconds`
1.0, `pod_launch_seconds` 10.0, `pod_launch_noise` 5.0,
`slice_spawn_interval` 60.0, `slice_max_aliens` 2.

### Owner checks

- Pods say "Pods locked" until the power cell is carried from the
  Generator and inserted (5 s) in the Pod Bay socket.
- Boarding takes 2 s; E gets you out again; holding E starts a 10 s
  countdown and the Pod Bay's noise jumps by 5.
- At zero the end screen says you escaped, with your time.
- Dying shows the end screen with "You died"; waiting until 40:00 (use a
  short `jump_time` to test) shows "Left behind at the jump".
- Crawlers appear about once a minute after 1:30, never more than two.

## M2.8 The ship's room network

*Added 13 Nov 2026 (D20); reworked 14 Nov (three engines, D21) and 15 Nov
2026 after the owner sent a ship diagram and asked for the layout to match it
(D22). Built; the code is in the repo.*
*Concepts:* data-driven layouts, convex polygons, building a node tree in code.

The ship is **21 rooms joined by 28 corridors**, arranged like the owner's
diagram: the Bridge (a rounded cockpit) at the front, the Cryo Bay (a tall
oval) in the middle, three engines (D shapes) in a column at the back, and 16
hexagons between them in rings and strings. Rooms have 2 to 5 doors and the
corridors make loops. Our names and look stay ours; only the arrangement
follows the diagram. Every corridor is a place of its own for noise and
encounters.

### How it is made

1. **`tools/make_ship_layout.py`** holds the diagram as numbers (a pixel
   position per room, which rooms are linked, the room shapes). It picks the
   wall of each room every corridor leaves by, routes each corridor (a short
   straight stub out of each door, then a run between the stubs), checks that
   no corridor cuts through a room or runs into another, and writes
   **`scripts/data/ship_layout_data.gd`** (`SHAPES`, `SLOTS`, `LINKS`).
   Run it with `python tools/make_ship_layout.py --draw layout.png` to see a
   picture. Hand-fix a route with the `OVERRIDES` table in the tool.
2. **`ShipLayout`** (a Resource, `data/ship_layout.tres`) keeps the sizes
   (wall thickness, door size, room height) and reads the data.
3. **`RoomGeometry`** has the polygon maths (walls, normals, corner overlap,
   prism points and mesh).
4. **`ShipBuilder`** builds each `Room_<slot>` (floor and ceiling slabs, one
   wall per polygon side with a doorway where a corridor leaves, zone, search
   containers, light, furnishing) and each `Link_<a>_<b>` (straight pieces
   with mitred bends, a zone, a door in the middle of the longest piece, a
   search container, a light).

Fixed rooms: Bridge, Cryo Bay, Engines A, B and C, Pod Bay (hexagon). The 15
shuffled slots are `slot_1` to `slot_15`. Power sections: Fore (Bridge, Cryo
Bay, slots 1 to 6), Mid (slots 7 to 10), Aft (slots 11 to 15, Pod Bay,
engines). A corridor takes the section of the end nearer the front.

In Phase 2 all 21 rooms are open: `PHASE2_ROOMS` in `match.gd` puts the Medbay
in slot 3, the Generator in slot 9 and the Armory in slot 11, and every other
shuffled slot is a **Crew Quarters** (a plain room with 3 search containers,
`RoomType.is_filler`). M4.5 replaces this with the real shuffle: all 10 room
types plus 5 Crew Quarters, in random slots.

### Rules for furnishing scenes

- A room is **not turned**: its frame is the ship's, origin at the middle of
  the floor, floor at y = 0.
- Any wall can have a doorway, so **keep the lanes** from the middle to every
  wall clear (1 m each side of the line). In hexagons put props at the six
  corners (directions 30, 90, 150, 210, 270, 330 degrees from -Z toward +X),
  radius 3.5 to 5, long axis pointing outward. The Cryo Bay's pods were placed
  by script so that they miss all five door lanes.
- Search containers stand 0.8 m from the longest walls that have no doorway.
- `ShipBuilder._warn_if_outside` (debug builds) warns if a top-level part of
  a furnishing has its centre within 0.3 m of a wall.

### Owner checks

- Press F5: you start in the tall Cryo Bay in the middle of the ship, among
  six pods in two columns. It looks big; it has five doors.
- Walk out of any door: a 2 m wide corridor leads, with bends, to the next
  room; it has a door in the middle of its longest straight piece. The debug
  overlay says "Corridor N" in them and names each room.
- Walk to the Bridge (front, left), an engine room (back, right) and the
  Pod Bay. The engine rooms are big D-shaped rooms with their flat wall
  facing the ship; Engine B has doors to the two rooms beside it (slot 15
  and the Pod Bay) and no door to the Cryo Bay.
- Bends: floors are continuous and walls close up at every bend, with no
  gaps and no wall across the way.
- Doors in corridors open, close, weld and lock (M2.5).
- *Debug > Visible Navigation*: blue floor in every room and corridor,
  joined through every doorway; Crawlers still reach you.
- Stations: Medbay (slot 3), Generator (slot 9), Armory (slot 11), Pod Bay
  (beside Engine C): all reachable.
- A full escape still works (power cell from slot 9 to the Pod Bay socket).
- No "sticks out of its room" warnings in the Output panel.

The ship is about 130 m long. If it feels too big to cross, change
`METRES_PER_PIXEL` in the tool and rerun it (the rooms stay the same size, the
corridors shrink).

### Gate 2

Play after M2.8, so the friend sees the hexagonal ship. A friend plays for 15 minutes with no help. Afterwards they can tell you
what they were supposed to do (find the power cell, reach the pods).
Write what confused them in `docs/playtest-notes.md` and fix the top
three before Phase 3. Freeze features here: new ideas go in
`docs/later.md`.
