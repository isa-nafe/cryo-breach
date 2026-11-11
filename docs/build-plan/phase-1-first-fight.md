# Phase 1: first fight

Goal: walk around the grey-box Cryo Bay, shoot a pistol, get chased and
killed by one Crawler, restart. GDD sections to read: *Players > Wounds and
death*, *Aliens > Alien types* (Crawler row), *Items > Weapons* (Pistol
row), *Noise and encounters > Noise per action*.

Everything in this phase runs in `scenes/main.tscn`. It is a test scene;
Phase 2 replaces it with a generated ship, but every script written here
is kept.

---

## M1.0 First run (owner)

No code. The owner installs Godot 4.7, opens the project and goes through
the "First-run checklist" in the project `README.md`. Anything that fails
is written in `docs/playtest-notes.md` and fixed in a Sonnet session before
M1.1 starts.

Likely trouble spots, in order of suspicion:

1. `scenes/rooms/cryo_bay.tscn` was written by hand; a typo shows as a red
   "Parse Error" on import. Fix the line the error names.
2. The player falls through the floor: the `Shell` `CSGCombiner3D` needs
   `use_collision = true` and `collision_layer = 1`.
3. Crouch never ends: `_can_stand_up()` in `player_character.gd` uses
   `test_move`; check the capsule is not touching the ceiling.

---

## M1.1 Layers, HealthComponent, target dummy, pistol

*Concepts to explain to the owner:* signals (a node announcing "something
happened"), `Resource` files as data, raycasts.

### Files

| File | Action |
| --- | --- |
| `scripts/core/layers.gd` | new |
| `scripts/core/placeholder_sounds.gd` | new |
| `scripts/components/health_component.gd` | new |
| `scripts/data/weapon_data.gd`, `data/weapons/pistol.tres` | new |
| `scripts/weapons/hitscan_weapon.gd`, `scenes/weapons/pistol.tscn` | new |
| `scripts/aliens/target_dummy.gd`, `scenes/aliens/target_dummy.tscn` | new |
| `scripts/player/player_character.gd`, `scenes/player/player.tscn` | edit |
| `scenes/main.tscn` | edit: add a dummy |
| `scripts/data/tuning.gd`, `data/tuning.tres` | edit |
| `project.godot` | edit: name layers 5 and 6 |

### Code

```gdscript
# FILE: scripts/core/layers.gd
class_name Layers
extends RefCounted
## Physics layer bit values. Use these instead of raw numbers.
##
## Example: `query.collision_mask = Layers.WORLD | Layers.ALIENS`

const WORLD := 1
const PLAYERS := 2
const ALIENS := 4
const ZONES := 8
const INTERACTABLES := 16
const DOORS := 32

## What a bullet can hit. Players are left out on purpose: bullets and
## melee never damage players (design rule).
const BULLET_MASK := WORLD | ALIENS | DOORS
```

In `project.godot` add under `[layer_names]`:

```text
3d_physics/layer_5="interactables"
3d_physics/layer_6="doors"
```

```gdscript
# FILE: scripts/core/placeholder_sounds.gd
class_name PlaceholderSounds
extends RefCounted
## Makes simple sounds in code so the game needs no audio files yet.
## Replace with real sounds in Phase 6.

const MIX_RATE := 22050


## A short burst of fading white noise: good enough for a gunshot.
static func noise_burst(seconds: float, volume: float = 0.6) -> AudioStreamWAV:
	var count := int(seconds * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var fade := 1.0 - float(i) / float(count)
		var sample := randf_range(-1.0, 1.0) * fade * fade * volume
		bytes.encode_s16(i * 2, int(sample * 32767.0))
	return _wav(bytes)


## A plain beep: good enough for terminals and alarms.
static func tone(frequency: float, seconds: float, volume: float = 0.4) -> AudioStreamWAV:
	var count := int(seconds * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var fade := 1.0 - float(i) / float(count)
		var sample := sin(TAU * frequency * float(i) / MIX_RATE) * fade * volume
		bytes.encode_s16(i * 2, int(sample * 32767.0))
	return _wav(bytes)


static func _wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = bytes
	return wav
```

```gdscript
# FILE: scripts/components/health_component.gd
class_name HealthComponent
extends Node
## Hit points for aliens and breakable things.
##
## Players do NOT use this: they use the wound system (PlayerWounds).
## Add it as a child named "HealthComponent" so `find_in` can locate it.

## Emitted after damage is applied. `source` is who caused it (may be null).
signal damaged(amount: float, source: Node)
## Emitted once, when health reaches 0. `killer` dealt the last damage.
signal died(killer: Node)

## Starting and maximum health.
@export var max_health: float = 30.0

## Current health.
var health: float = 0.0
var is_dead := false


func _ready() -> void:
	health = max_health


## Returns the HealthComponent of `node`, or null if it has none.
static func find_in(node: Node) -> HealthComponent:
	if node == null:
		return null
	return node.get_node_or_null(^"HealthComponent") as HealthComponent


## Removes health. Only the host should call this.
func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	damaged.emit(amount, source)
	if health <= 0.0:
		is_dead = true
		died.emit(source)


## Back to full health (used when an alien returns to the pool).
func revive() -> void:
	is_dead = false
	health = max_health


## Health as a fraction from 0 to 1.
func get_fraction() -> float:
	if max_health <= 0.0:
		return 0.0
	return health / max_health
```

```gdscript
# FILE: scripts/data/weapon_data.gd
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
```

`data/weapons/pistol.tres`:

```text
[gd_resource type="Resource" script_class="WeaponData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/weapon_data.gd" id="1_data"]

[resource]
script = ExtResource("1_data")
display_name = "Pistol"
damage = 20.0
capacity = 8
pellets = 1
automatic = false
fire_interval = 0.25
spread_degrees = 1.0
max_range = 60.0
noise = 2.0
```

```gdscript
# FILE: scripts/weapons/hitscan_weapon.gd
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

var _cooldown := 0.0
var _trigger_was_held := false

@onready var _flash: OmniLight3D = $MuzzleFlash
@onready var _shot_sound: AudioStreamPlayer3D = $ShotSound


func _ready() -> void:
	rounds = data.capacity
	_flash.visible = false
	_shot_sound.stream = PlaceholderSounds.noise_burst(Config.tuning.placeholder_shot_seconds)


## Call every physics frame with whether the fire button is held.
func update_trigger(held: bool, shooter: PlayerCharacter, delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var pulled := held and (data.automatic or not _trigger_was_held)
	_trigger_was_held = held
	if not pulled or _cooldown > 0.0:
		return
	_cooldown = data.fire_interval
	if rounds <= 0:
		dry_fired.emit()
		return
	rounds -= 1
	ammo_changed.emit(rounds, data.capacity)
	var spread := data.spread_degrees * shooter.get_spread_multiplier()
	var aim := shooter.camera.global_basis
	var origin := shooter.camera.global_position
	for _i in data.pellets:
		_resolve_shot(shooter, origin, _spread_direction(aim, spread))
	shooter.emit_noise(data.noise)
	_show_effects()
	fired.emit()


## Fills the weapon (ammo box).
func reload_full() -> void:
	rounds = data.capacity
	ammo_changed.emit(rounds, data.capacity)


## Decides what one ray hits. In Phase 3 this moves to the host.
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


func _show_effects() -> void:
	_shot_sound.play()
	_flash.visible = true
	var timer := get_tree().create_timer(Config.tuning.muzzle_flash_seconds)
	timer.timeout.connect(_hide_flash)


func _hide_flash() -> void:
	_flash.visible = false
```

`scenes/weapons/pistol.tscn` (a grey box held at the lower right of the view):

```text
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/weapons/hitscan_weapon.gd" id="1_weapon"]
[ext_resource type="Resource" path="res://data/weapons/pistol.tres" id="2_data"]

[sub_resource type="BoxMesh" id="Mesh_pistol"]
size = Vector3(0.05, 0.12, 0.28)

[sub_resource type="StandardMaterial3D" id="Mat_pistol"]
albedo_color = Color(0.2, 0.22, 0.25, 1)
metallic = 0.6
roughness = 0.4

[node name="Pistol" type="Node3D"]
script = ExtResource("1_weapon")
data = ExtResource("2_data")

[node name="Model" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.22, -0.2, -0.45)
mesh = SubResource("Mesh_pistol")
surface_material_override/0 = SubResource("Mat_pistol")

[node name="MuzzleFlash" type="OmniLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.22, -0.15, -0.7)
light_color = Color(1, 0.8, 0.4, 1)
light_energy = 3.0
omni_range = 6.0

[node name="ShotSound" type="AudioStreamPlayer3D" parent="."]
```

```gdscript
# FILE: scripts/aliens/target_dummy.gd
extends StaticBody3D
## A practice target: takes damage, disappears at 0 health, comes back.
## Scene: StaticBody3D on the "aliens" layer with children
## "CollisionShape3D", "MeshInstance3D" and "HealthComponent".

@onready var _health: HealthComponent = $HealthComponent
@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


func _on_damaged(_amount: float, _source: Node) -> void:
	# A tween animates a property over time; here a quick "pop".
	_mesh.scale = Vector3.ONE * 1.15
	create_tween().tween_property(_mesh, "scale", Vector3.ONE, 0.15)


func _on_died(_killer: Node) -> void:
	_mesh.visible = false
	_shape.set_deferred("disabled", true)
	await get_tree().create_timer(Config.tuning.dummy_respawn_seconds).timeout
	_health.revive()
	_mesh.visible = true
	_shape.set_deferred("disabled", false)
```

`scenes/aliens/target_dummy.tscn`:

```text
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/aliens/target_dummy.gd" id="1_dummy"]
[ext_resource type="Script" path="res://scripts/components/health_component.gd" id="2_health"]

[sub_resource type="CapsuleShape3D" id="Shape_dummy"]
radius = 0.35
height = 1.7

[sub_resource type="CapsuleMesh" id="Mesh_dummy"]
radius = 0.35
height = 1.7

[sub_resource type="StandardMaterial3D" id="Mat_dummy"]
albedo_color = Color(0.9, 0.75, 0.2, 1)

[node name="TargetDummy" type="StaticBody3D"]
collision_layer = 4
collision_mask = 0
script = ExtResource("1_dummy")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
shape = SubResource("Shape_dummy")

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
mesh = SubResource("Mesh_dummy")
surface_material_override/0 = SubResource("Mat_dummy")

[node name="HealthComponent" type="Node" parent="."]
script = ExtResource("2_health")
max_health = 60.0
```

### Edits

`scenes/player/player.tscn`: add an `ext_resource` for
`res://scenes/weapons/pistol.tscn` and, after the `HelmetLamp` node:

```text
[node name="Pistol" parent="Head/Camera3D" instance=ExtResource("3_pistol")]
```

`scripts/player/player_character.gd`:

```gdscript
# Add with the other @onready lines (null when the scene has no pistol):
@onready var weapon: HitscanWeapon = get_node_or_null(^"Head/Camera3D/Pistol")


# Add as a public method. M1.2 makes it read the wounds.
## How much wider than normal this character's weapon spread is.
func get_spread_multiplier() -> float:
	return 1.0


# In _physics_process, after _update_noise(delta):
#	if weapon:
#		weapon.update_trigger(input.fire, self, delta)
```

`scenes/main.tscn`: instance `target_dummy.tscn` at `(3.5, 0, 4)` (inside
the Cryo Bay, clear of the pods).

### Tuning to add

| Name | Value | Doc comment |
| --- | --- | --- |
| `muzzle_flash_seconds` | 0.05 | How long the muzzle flash light stays on. |
| `placeholder_shot_seconds` | 0.12 | Length of the generated gunshot sound. |
| `dummy_respawn_seconds` | 3.0 | Seconds before a destroyed target dummy returns. |

Put them in a new `@export_group("Weapons")`.

### Owner checks

- Left mouse fires; there is a flash and a noise burst.
- The debug overlay shows the zone's noise going up by 2 per shot.
- The dummy "pops" on each hit and vanishes after 3 hits (60 health,
  20 per shot), then returns after 3 seconds.
- After 8 shots the pistol stops firing. (No HUD ammo count yet.)
- Holding the mouse button fires once, not continuously.

---

## M1.2 Wound system, HUD, death and restart

*Concepts:* `CanvasLayer` and `Control` nodes for UI, enums.

GDD rules implemented: every third light wound becomes a serious wound;
each serious wound gets a random effect (Limp, Shaky aim, Broken arm,
Bleeding); the third serious wound kills. Bandages, medkits and Broken
arm's effect on hands arrive with the inventory in Phase 2.

### Files

| File | Action |
| --- | --- |
| `scripts/player/player_wounds.gd` | new |
| `scripts/ui/hud.gd`, `scenes/ui/hud.tscn` | new |
| `scripts/player/player_character.gd`, `scenes/player/player.tscn` | edit |
| `scripts/core/input_setup.gd` | edit: add `"restart": [KEY_R]` |
| `scripts/ui/debug_hud.gd` | edit: add debug keys (below) |
| `scenes/main.tscn` | edit: add the HUD |

### Code

```gdscript
# FILE: scripts/player/player_wounds.gd
class_name PlayerWounds
extends Node
## A player's wounds. Players have no hit points (design rule).
##
## Light wounds: every third one becomes a serious wound.
## Serious wounds: each has a random effect; the third one kills.
## Only the host changes wounds; the owner is told the result.

## Emitted whenever anything about the wounds changes.
signal changed
## Emitted once when the player dies of wounds.
signal died

enum Effect { LIMP, SHAKY_AIM, BROKEN_ARM, BLEEDING }

const EFFECT_NAMES := {
	Effect.LIMP: "Limp",
	Effect.SHAKY_AIM: "Shaky aim",
	Effect.BROKEN_ARM: "Broken arm",
	Effect.BLEEDING: "Bleeding",
}

## Light wounds not yet turned into a serious wound.
var light_wounds: int = 0
## One entry per serious wound: its effect.
var serious_effects: Array[Effect] = []
## One entry per serious wound: true once it has been bandaged.
var serious_dressed: Array[bool] = []
var is_dead := false

var _bleed_timer := 0.0


func _physics_process(delta: float) -> void:
	if is_dead or not has_effect(Effect.BLEEDING):
		_bleed_timer = 0.0
		return
	_bleed_timer += delta
	if _bleed_timer >= Config.tuning.bleed_interval:
		_bleed_timer -= Config.tuning.bleed_interval
		add_light()


## Adds light wounds, converting every third into a serious wound.
func add_light(count: int = 1) -> void:
	for _i in count:
		if is_dead:
			break
		light_wounds += 1
		if light_wounds >= Config.tuning.light_wounds_per_serious:
			light_wounds = 0
			_add_one_serious()
	changed.emit()


## Adds serious wounds, each with a random effect.
func add_serious(count: int = 1) -> void:
	for _i in count:
		if is_dead:
			break
		_add_one_serious()
	changed.emit()


## Medkit or rest bed: removes all light wounds.
func heal_light() -> void:
	light_wounds = 0
	changed.emit()


## Bandage: stops the effect of the first undressed serious wound.
## It still counts toward death. Returns false if there was none.
func dress_one() -> bool:
	var index := serious_dressed.find(false)
	if index == -1:
		return false
	serious_dressed[index] = true
	changed.emit()
	return true


## Surgery: removes one serious wound completely (undressed ones first).
func remove_one_serious() -> bool:
	if serious_effects.is_empty():
		return false
	var index := serious_dressed.find(false)
	if index == -1:
		index = 0
	serious_effects.remove_at(index)
	serious_dressed.remove_at(index)
	changed.emit()
	return true


## True if an undressed serious wound has this effect.
func has_effect(effect: Effect) -> bool:
	for i in serious_effects.size():
		if serious_effects[i] == effect and not serious_dressed[i]:
			return true
	return false


func get_speed_multiplier() -> float:
	if has_effect(Effect.LIMP):
		return Config.tuning.limp_speed_multiplier
	return 1.0


func can_sprint() -> bool:
	return not has_effect(Effect.LIMP)


func get_spread_multiplier() -> float:
	if has_effect(Effect.SHAKY_AIM):
		return Config.tuning.shaky_aim_spread_multiplier
	return 1.0


## 1 with an undressed broken arm, otherwise 2.
func get_usable_hands() -> int:
	if has_effect(Effect.BROKEN_ARM):
		return 1
	return 2


## Text for the HUD, for example "Limp, Bleeding (dressed)".
func describe_serious() -> String:
	var parts := PackedStringArray()
	for i in serious_effects.size():
		var text: String = EFFECT_NAMES[serious_effects[i]]
		if serious_dressed[i]:
			text += " (dressed)"
		parts.append(text)
	return ", ".join(parts)


func _add_one_serious() -> void:
	var effect := randi_range(0, Effect.size() - 1) as Effect
	serious_effects.append(effect)
	serious_dressed.append(false)
	if serious_effects.size() >= Config.tuning.serious_wounds_to_die:
		is_dead = true
		died.emit()
```

```gdscript
# FILE: scripts/ui/hud.gd
extends CanvasLayer
## The player's own HUD: wounds, ammo, hit marker, death screen.
## Scene: CanvasLayer with Labels "Wounds", "Ammo", "HitMarker" and a
## ColorRect "DeathScreen" that has a Label child "Text".

## The PlayerCharacter this HUD belongs to.
@export var player_path: NodePath

var _player: PlayerCharacter

@onready var _wounds: Label = $Wounds
@onready var _ammo: Label = $Ammo
@onready var _hit_marker: Label = $HitMarker
@onready var _death_screen: ColorRect = $DeathScreen


func _ready() -> void:
	_death_screen.visible = false
	_hit_marker.visible = false
	_player = get_node_or_null(player_path) as PlayerCharacter
	if _player == null:
		push_warning("HUD: no PlayerCharacter at %s" % player_path)
		return
	_player.wounds.changed.connect(_refresh_wounds)
	_player.died.connect(_on_player_died)
	_refresh_wounds()
	if _player.weapon:
		_player.weapon.ammo_changed.connect(_on_ammo_changed)
		_player.weapon.hit_confirmed.connect(_on_hit_confirmed)
		_on_ammo_changed(_player.weapon.rounds, _player.weapon.data.capacity)
	else:
		_ammo.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if _player and _player.is_dead and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _refresh_wounds() -> void:
	var wounds := _player.wounds
	var tuning := Config.tuning
	var lines := PackedStringArray()
	lines.append("Light wounds   %d / %d" % [wounds.light_wounds, tuning.light_wounds_per_serious])
	lines.append(
		"Serious wounds %d / %d" % [wounds.serious_effects.size(), tuning.serious_wounds_to_die]
	)
	if not wounds.serious_effects.is_empty():
		lines.append(wounds.describe_serious())
	_wounds.text = "\n".join(lines)


func _on_ammo_changed(rounds: int, capacity: int) -> void:
	_ammo.text = "%s  %d / %d" % [_player.weapon.data.display_name, rounds, capacity]


func _on_hit_confirmed(_killed: bool) -> void:
	_hit_marker.visible = true
	await get_tree().create_timer(Config.tuning.hit_marker_seconds).timeout
	_hit_marker.visible = false


func _on_player_died() -> void:
	_death_screen.visible = true
```

`scenes/ui/hud.tscn`:

```text
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1_hud"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="Wounds" type="Label" parent="."]
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = -96.0
offset_right = 420.0
offset_bottom = -16.0
grow_vertical = 0
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
theme_override_constants/outline_size = 6
text = "Wounds"
vertical_alignment = 2

[node name="Ammo" type="Label" parent="."]
anchors_preset = 3
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -320.0
offset_top = -56.0
offset_right = -16.0
offset_bottom = -16.0
grow_horizontal = 0
grow_vertical = 0
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
theme_override_constants/outline_size = 6
theme_override_font_sizes/font_size = 22
text = "Ammo"
horizontal_alignment = 2
vertical_alignment = 2

[node name="HitMarker" type="Label" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -14.0
offset_top = -16.0
offset_right = 14.0
offset_bottom = 16.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(1, 0.3, 0.2, 1)
theme_override_font_sizes/font_size = 24
text = "x"
horizontal_alignment = 1
vertical_alignment = 1

[node name="DeathScreen" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.25, 0, 0, 0.6)

[node name="Text" type="Label" parent="DeathScreen"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_font_sizes/font_size = 32
text = "You died.
Press R to restart."
horizontal_alignment = 1
vertical_alignment = 1
```

### Edits

`scenes/player/player.tscn`: add a plain `Node` child named `Wounds` with
`player_wounds.gd` attached.

`scripts/player/player_character.gd`:

```gdscript
# New signal, next to made_noise:
## Emitted once when this character dies.
signal died

# New public variable:
var is_dead := false

# New @onready:
@onready var wounds: PlayerWounds = $Wounds


# In _ready, add:
#	wounds.died.connect(_on_wounds_died)


# Replace the M1.1 version:
func get_spread_multiplier() -> float:
	return wounds.get_spread_multiplier()


func _on_wounds_died() -> void:
	is_dead = true
	input_source.enabled = false
	input_source.state.release_all()
	# Drop the camera to the floor so death reads clearly.
	var fall := create_tween()
	fall.tween_property(head, "position:y", Config.tuning.dead_eye_height, 0.6)
	died.emit()
```

Also in `player_character.gd`:

- `_update_movement`: after `speed` is chosen, multiply it by
  `wounds.get_speed_multiplier()`; add `and wounds.can_sprint()` to the
  `is_sprinting` line.
- `_physics_process`: only call `weapon.update_trigger` when
  `not is_dead`.
- `_update_crouch` calls `_set_body_height`, which would fight the death
  tween: return early from `_update_crouch` when `is_dead`.

`scripts/ui/debug_hud.gd`: so wounds can be tested before aliens exist, add
to `_unhandled_input` (debug only, remove in Phase 6):

```gdscript
func _debug_keys(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _player == null:
		return
	match key.physical_keycode:
		KEY_F5:
			_player.wounds.add_light()
		KEY_F6:
			_player.wounds.add_serious()
		KEY_F7:
			_player.wounds.heal_light()
```

Call `_debug_keys(event)` from `_unhandled_input`, and add
`"F5 light wound | F6 serious wound | F7 heal light"` to the help lines.
(F5 only runs the game from inside the editor window, not the game window.)

### Tuning to add (`@export_group("Wounds")`)

| Name | Value | Doc comment |
| --- | --- | --- |
| `light_wounds_per_serious` | 3 | Every this many light wounds become one serious wound. |
| `serious_wounds_to_die` | 3 | Serious wounds that kill a player. |
| `limp_speed_multiplier` | 0.75 | Speed with a Limp (25% slower, no sprint). |
| `shaky_aim_spread_multiplier` | 1.5 | Weapon spread with Shaky aim (50% more). |
| `bleed_interval` | 60.0 | Bleeding gives one light wound every this many seconds. |
| `dead_eye_height` | 0.3 | Camera height above the floor after death. |
| `hit_marker_seconds` | 0.12 | How long the hit marker shows. |

### Owner checks

- The HUD shows wounds bottom-left and "Pistol 8 / 8" bottom-right; the
  ammo count drops with each shot; a red x flashes on a hit.
- F5 three times: light wounds go 1, 2, then back to 0 with one serious
  wound and a named effect.
- With *Limp*: slower, cannot sprint. With *Shaky aim*: shots scatter more.
- F6 until three serious wounds: the camera drops, the death screen
  appears, movement stops, R restarts the scene.

---

## M1.3 Navigation mesh and the first Crawler

*Concepts:* navigation meshes (the walkable floor area, computed once),
`NavigationAgent3D` (finds a path across it), a simple state machine.

GDD Crawler: 30 health, 6 m/s, sight 20 m cone, hears loud noise within
10 m, 1 light wound every 1.2 s, opens closed doors, never flees.

### Files

| File | Action |
| --- | --- |
| `scripts/data/alien_data.gd`, `data/aliens/crawler.tres` | new |
| `scripts/aliens/alien.gd`, `scenes/aliens/crawler.tscn` | new |
| `scripts/world/nav_baker.gd` | new |
| `scripts/core/main.gd` | new |
| `scenes/main.tscn` | edit |
| `scripts/player/player_character.gd` | edit: tell aliens about noise |

### Code

```gdscript
# FILE: scripts/data/alien_data.gd
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
```

`data/aliens/crawler.tres`: same shape as `pistol.tres`, `script_class`
`AlienData`, with only the non-default lines needed (the defaults above are
already the Crawler's numbers, so `id` and `display_name` are enough).

```gdscript
# FILE: scripts/aliens/alien.gd
class_name Alien
extends CharacterBody3D
## An active alien. Runs only on the host; clients see its synced position.
##
## Phase 1 behaviour (enough for the Crawler): stand still, walk to loud
## noises, chase a player it can see, attack in reach. Phase 4 adds vents,
## fleeing, doors and the other types on top of this class.
## Scene: CharacterBody3D on the "aliens" layer with children
## "CollisionShape3D", "NavigationAgent3D" and "HealthComponent".

## Emitted when this alien is killed. `killer` dealt the last damage.
signal died(alien: Alien, killer: Node)

enum State { IDLE, INVESTIGATE, CHASE, DEAD }

## This alien's numbers.
@export var data: AlienData

var state: State = State.IDLE
## The player being chased, or null.
var target: PlayerCharacter = null

var _attack_cooldown := 0.0
var _repath_timer := 0.0
var _lost_sight_timer := 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var _agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	add_to_group(&"aliens")
	health.max_health = data.max_health
	health.revive()
	health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_update_target(delta)
	var speed := 0.0
	match state:
		State.CHASE:
			_repath_to(target.global_position, delta)
			if _distance_to_target() > data.attack_range * 0.8:
				speed = data.move_speed
			_try_attack()
		State.INVESTIGATE:
			speed = data.move_speed
			if _navigation_ready() and _agent.is_navigation_finished():
				state = State.IDLE
	_steer(speed, delta)
	move_and_slide()


## Called through the "aliens" group whenever a player makes noise.
func hear_noise(noise_position: Vector3, amount: float) -> void:
	if state == State.DEAD or state == State.CHASE:
		return
	if amount < Config.tuning.loud_noise_threshold:
		return
	if global_position.distance_to(noise_position) > data.hearing_range:
		return
	go_to(noise_position)


## Sends the alien to a place (noise, encounter zone).
func go_to(place: Vector3) -> void:
	if state == State.DEAD or state == State.CHASE:
		return
	_agent.target_position = place
	state = State.INVESTIGATE


func _update_target(delta: float) -> void:
	if target != null and (not is_instance_valid(target) or target.is_dead):
		target = null
		state = State.IDLE
	var seen := _find_visible_player()
	if seen:
		target = seen
		state = State.CHASE
		_lost_sight_timer = 0.0
	elif state == State.CHASE:
		_lost_sight_timer += delta
		if _lost_sight_timer >= Config.tuning.alien_lose_target_seconds:
			# Give up the chase but check where the player was last.
			var last_place := target.global_position
			target = null
			state = State.IDLE
			go_to(last_place)


func _find_visible_player() -> PlayerCharacter:
	var best: PlayerCharacter = null
	var best_distance := INF
	for node: Node in get_tree().get_nodes_in_group(&"players"):
		var player := node as PlayerCharacter
		if player == null or player.is_dead or not _can_see(player):
			continue
		var distance := global_position.distance_to(player.global_position)
		if distance < best_distance:
			best = player
			best_distance = distance
	return best


func _can_see(player: PlayerCharacter) -> bool:
	if data.sight_range <= 0.0:
		return false
	var eye := global_position + Vector3.UP * data.eye_height
	var to_player := player.head.global_position - eye
	if to_player.length() > data.sight_range:
		return false
	if data.sight_cone_degrees < 360.0:
		var flat := Vector3(to_player.x, 0.0, to_player.z)
		var forward := -global_basis.z
		if flat.length() > 0.01 and forward.angle_to(flat) > deg_to_rad(data.sight_cone_degrees) * 0.5:
			return false
	# A wall between the eyes and the player's head blocks sight.
	var query := PhysicsRayQueryParameters3D.create(
		eye, player.head.global_position, Layers.WORLD | Layers.DOORS
	)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _try_attack() -> void:
	if _attack_cooldown > 0.0 or _distance_to_target() > data.attack_range:
		return
	_attack_cooldown = data.attack_interval
	if data.light_wounds_per_hit > 0:
		target.wounds.add_light(data.light_wounds_per_hit)
	if data.serious_wounds_per_hit > 0:
		target.wounds.add_serious(data.serious_wounds_per_hit)


func _distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


## Asks for a new path at most a few times per second (paths are costly).
func _repath_to(place: Vector3, delta: float) -> void:
	_repath_timer -= delta
	if _repath_timer > 0.0:
		return
	_repath_timer = Config.tuning.alien_repath_interval
	_agent.target_position = place


func _steer(speed: float, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var direction := Vector3.ZERO
	if speed > 0.0 and _navigation_ready() and not _agent.is_navigation_finished():
		direction = _agent.get_next_path_position() - global_position
		direction.y = 0.0
		direction = direction.normalized()
	elif state == State.CHASE:
		# In reach: stand still but keep facing the target.
		direction = target.global_position - global_position
		direction.y = 0.0
		direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction != Vector3.ZERO:
		var yaw := atan2(-direction.x, -direction.z)
		var weight := clampf(Config.tuning.alien_turn_speed * delta, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, yaw, weight)


## False until the navigation map has been built at least once.
func _navigation_ready() -> bool:
	return NavigationServer3D.map_get_iteration_id(_agent.get_navigation_map()) != 0


func _on_health_died(killer: Node) -> void:
	state = State.DEAD
	remove_from_group(&"aliens")
	died.emit(self, killer)
	queue_free()
```

`scenes/aliens/crawler.tscn`: root `CharacterBody3D` named `Crawler`,
`collision_layer = 4`, `collision_mask = 39` (world + players + aliens +
doors), script `alien.gd`, `data` = `crawler.tres`. Children:

| Node | Type | Settings |
| --- | --- | --- |
| `CollisionShape3D` | CollisionShape3D | `CapsuleShape3D` radius 0.4, height 1.0, at y 0.5 |
| `Body` | MeshInstance3D | `BoxMesh` 0.7 x 0.5 x 1.1 at y 0.45, dark red material |
| `Head` | MeshInstance3D | `BoxMesh` 0.35 x 0.3 x 0.4 at (0, 0.55, -0.7), so the facing direction (-Z) is visible |
| `NavigationAgent3D` | NavigationAgent3D | `path_desired_distance = 0.6`, `target_desired_distance = 0.8` |
| `HealthComponent` | Node | script `health_component.gd` |

```gdscript
# FILE: scripts/world/nav_baker.gd
class_name NavBaker
extends NavigationRegion3D
## Builds the navigation mesh when the level starts, from every collider on
## the "world" layer below this node. Put the level under this node.
## Wait for the built-in `bake_finished` signal before spawning aliens.


func _ready() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = Layers.WORLD
	navigation_mesh = mesh
	# CSG shapes create their collision a frame late, so wait before baking.
	await get_tree().physics_frame
	await get_tree().physics_frame
	bake_navigation_mesh()
```

If the bake comes out empty in Godot (aliens never move, and *Debug >
Visible Navigation* shows no blue floor), change the parsed type to
`NavigationMesh.PARSED_GEOMETRY_BOTH`.

```gdscript
# FILE: scripts/core/main.gd
extends Node3D
## Phase 1 test scene: spawns one Crawler at a time in the corridor.
## Scene needs children "Navigation" (NavBaker), "Aliens" (Node3D) and
## "AlienSpawn" (Marker3D).

const CRAWLER_SCENE := preload("res://scenes/aliens/crawler.tscn")

@onready var _navigation: NavBaker = $Navigation
@onready var _aliens: Node3D = $Aliens
@onready var _spawn_point: Marker3D = $AlienSpawn


func _ready() -> void:
	await _navigation.bake_finished
	_spawn_after(Config.tuning.first_crawler_delay)


func _spawn_after(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	var crawler: Alien = CRAWLER_SCENE.instantiate()
	crawler.position = _spawn_point.position
	_aliens.add_child(crawler)
	crawler.died.connect(_on_crawler_died)


func _on_crawler_died(_alien: Alien, _killer: Node) -> void:
	_spawn_after(Config.tuning.crawler_respawn_delay)
```

### Edits

`scenes/main.tscn`:

- Attach `scripts/core/main.gd` to `Main`.
- Add `Navigation` (`NavigationRegion3D`, script `nav_baker.gd`) and move
  `CryoBay` under it: `[node name="CryoBay" parent="Navigation"
  instance=ExtResource("1_cryo")]`. The `Navigation` node must come before
  `CryoBay` in the file.
- Add `Aliens` (`Node3D`) and `AlienSpawn` (`Marker3D`) at
  `(8, 0.1, -7.2)`: the aft end of the corridor.
- Add the HUD from M1.2 if not already there. `HUD` and `DebugHUD` must
  come after `Player` in the file: they read the player's `wounds` and
  `weapon` in `_ready`, and siblings become ready in file order.

`scripts/player/player_character.gd`, in `emit_noise`, add as the last line:

```gdscript
#	get_tree().call_group(&"aliens", &"hear_noise", global_position, amount)
```

### Tuning to add (`@export_group("Aliens")`)

| Name | Value | Doc comment |
| --- | --- | --- |
| `loud_noise_threshold` | 2.0 | Noise of at least this much in one go counts as loud (a gunshot does, a sprint tick does not). |
| `alien_repath_interval` | 0.25 | Seconds between path updates while chasing. |
| `alien_turn_speed` | 10.0 | How quickly aliens turn to face their direction. |
| `alien_lose_target_seconds` | 3.0 | Seconds without sight before an alien gives up a chase. |
| `first_crawler_delay` | 10.0 | Phase 1 only: seconds before the first Crawler. |
| `crawler_respawn_delay` | 8.0 | Phase 1 only: seconds between a kill and the next Crawler. |

### Owner checks

- *Debug > Visible Navigation* (editor menu) shows a blue floor in the
  room and corridor with holes around the pods.
- About 10 seconds in, a Crawler appears at the end of the corridor.
- Out of its sight it stands still; a pistol shot within 10 m brings it
  to where you fired.
- Once it sees you it chases at 6 m/s (faster than your sprint) and gives
  one light wound every 1.2 s in reach.
- Two pistol hits kill it (30 health); another arrives 8 seconds later.
- It never walks through walls or gets stuck in the doorway for more than
  a second.
- Standing still with it attacking, you die in about 11 seconds, and R
  restarts.

### Gate 1

Play for 10 minutes and write three things that feel bad in
`docs/playtest-notes.md`. Then hand the build to someone else: they must
work out how to move and shoot without help and die to the Crawler in
under two minutes. Fix what blocks that before Phase 2.
