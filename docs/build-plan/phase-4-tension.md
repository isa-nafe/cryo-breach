# Phase 4: tension systems

Goal: the ship becomes dangerous on its own. Noise pulls aliens from a
hidden pool, all five alien types exist, the ship catches fire and
breaks, every room and item in the GDD is in the game. GDD sections:
*Aliens*, *Noise and encounters*, *Ship systems and hazards*, *Items,
weapons and crafting*, *Sabotage*, *The ship*.

Everything here is host-side logic plus a small public effect. Keep using
the three message kinds from Phase 3. The pool, the noise meters, engine
states, course and integrity are **never** sent to clients except as the
private answer to a player using the right terminal.

---

## M4.1 Alien pool, vents, noise director

Replaces the Phase 2 timer director (delete `timer_director.gd` and its
tuning values).

### Files

| File | Action |
| --- | --- |
| `scripts/aliens/alien_pool.gd` | new |
| `scripts/aliens/noise_director.gd` | new; child `NoiseDirector` of `Match` |
| `scripts/world/vent.gd` | new |
| `scripts/world/ship_builder.gd` | edit: one vent per zone |
| `scripts/world/zone.gd` | edit: `vent`, `get_awake_player_count()` |
| `scripts/aliens/alien.gd` | edit: spawn from a vent, flee to a vent |
| `data/aliens/*.tres` | new: larva, adult, breeder, queen (numbers only; behaviour in M4.2) |

```gdscript
# FILE: scripts/aliens/alien_pool.gd
class_name AlienPool
extends RefCounted
## The hidden bag of alien tokens (GDD "Pool rules"). Host only.
##
## One token per alien plus one Blank. Pulling an alien removes its token;
## the Blank always stays. Kills shrink the pool for good; an alien that
## flees is put back with `return_alien`.

const BLANK := &"blank"

var _tokens: Array[StringName] = []


## Fills the pool for a player count (GDD "Starting pool" table).
func setup(player_count: int) -> void:
	var tuning := Config.tuning
	var column := clampi(player_count, 3, 6) - 3
	_tokens.clear()
	_add(&"larva", tuning.pool_larva[column])
	_add(&"crawler", tuning.pool_crawler[column])
	_add(&"adult", tuning.pool_adult[column])
	_add(&"breeder", tuning.pool_breeder[column])
	_add(&"queen", tuning.pool_queen[column])
	_tokens.append(BLANK)


## Pulls one token at random. Returns BLANK or an alien id.
func pull() -> StringName:
	var token: StringName = _tokens.pick_random()
	if token != BLANK:
		_tokens.erase(token)
	return token


## An alien fled into a vent: its token goes back in.
func return_alien(alien_id: StringName) -> void:
	_tokens.append(alien_id)


## True when only the Blank is left in the pool.
func is_empty_of_aliens() -> bool:
	return _tokens.size() <= 1


## Alien id -> how many tokens are left (debug overlay only).
func get_counts() -> Dictionary:
	var counts := {}
	for token: StringName in _tokens:
		counts[token] = counts.get(token, 0) + 1
	return counts


func _add(alien_id: StringName, amount: int) -> void:
	for _i in amount:
		_tokens.append(alien_id)
```

```gdscript
# FILE: scripts/aliens/noise_director.gd
class_name NoiseDirector
extends Node
## Turns noise into encounters (GDD "What triggers an encounter"). Host only.
##
## - A zone that reaches the maximum noise triggers at once.
## - Every roll interval, each zone with an awake player in it rolls:
##   chance = noise x chance-per-point.
## - After an encounter the zone cannot trigger for a while, and the whole
##   ship has a shorter cooldown.

## Emitted after an encounter. `token` is an alien id, AlienPool.BLANK, or
## &"" when the active cap stopped the pull.
signal encounter(zone: Zone, token: StringName)

## The hidden pool.
var pool := AlienPool.new()

var _roll_timer := 0.0
var _ship_cooldown := 0.0
var _zone_cooldowns: Dictionary = {}
var _spawn_alien: Callable


## `spawn_alien` is called as spawn_alien(alien_id: StringName, zone: Zone).
func setup(player_count: int, spawn_alien: Callable) -> void:
	pool.setup(player_count)
	_spawn_alien = spawn_alien


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or GameState.phase != GameState.Phase.PLAYING:
		return
	if not GameState.is_grace_over():
		return
	_ship_cooldown = maxf(_ship_cooldown - delta, 0.0)
	for zone: Zone in _zone_cooldowns:
		_zone_cooldowns[zone] = maxf(_zone_cooldowns[zone] - delta, 0.0)
	for zone: Zone in GameState.zones:
		if zone.noise >= Config.tuning.noise_max and _can_trigger(zone):
			_trigger(zone)
	_roll_timer += delta
	if _roll_timer >= Config.tuning.encounter_roll_interval:
		_roll_timer -= Config.tuning.encounter_roll_interval
		_roll_all()


func _roll_all() -> void:
	for zone: Zone in GameState.zones:
		if zone.get_awake_player_count() == 0:
			continue
		var chance := zone.noise * Config.tuning.encounter_chance_per_noise
		if randf() < chance and _can_trigger(zone):
			_trigger(zone)


func _can_trigger(zone: Zone) -> bool:
	return _ship_cooldown <= 0.0 and _zone_cooldowns.get(zone, 0.0) <= 0.0


func _trigger(zone: Zone) -> void:
	var tuning := Config.tuning
	_ship_cooldown = tuning.encounter_ship_cooldown
	_zone_cooldowns[zone] = tuning.encounter_zone_cooldown
	var active := get_tree().get_nodes_in_group(&"aliens")
	var cap := maxi(GameState.get_awake_players().size(), tuning.active_alien_minimum_cap)
	if active.size() >= cap:
		# At the cap nothing is pulled; the nearest alien comes instead.
		zone.set_noise(tuning.noise_after_encounter)
		_send_nearest(active, zone)
		encounter.emit(zone, &"")
		return
	var token := pool.pull()
	if token == AlienPool.BLANK:
		zone.set_noise(floorf(zone.noise * tuning.blank_noise_multiplier))
	else:
		zone.set_noise(tuning.noise_after_encounter)
		_spawn_alien.call(token, zone)
	encounter.emit(zone, token)


func _send_nearest(active: Array[Node], zone: Zone) -> void:
	var nearest: Alien = null
	var nearest_distance := INF
	for node: Node in active:
		var alien := node as Alien
		if alien == null:
			continue
		var distance := alien.global_position.distance_to(zone.global_position)
		if distance < nearest_distance:
			nearest = alien
			nearest_distance = distance
	if nearest:
		nearest.go_to(zone.global_position)
```

### Vents

- `Vent` (extends `Interactable`): a grate on the floor in a corner of
  each room and against the wall of each corridor segment, named
  `Vent_<id>`; `zone.vent` points to it. State: `is_sealed`.
  `get_item_prompt` offers "Seal vent" / "Cut vent open" for a welder
  (`weld_seconds`).
- **Arriving:** `match.spawn_alien_at_vent(alien_id, zone)`: if the
  zone's vent is sealed and the alien cannot break welds
  (`weld_break_seconds < 0`), use the nearest unsealed vent among the
  zone's neighbours (then their neighbours); if every vent is sealed, put
  the token back and treat the pull as a Blank. A breaker spends
  `weld_break_seconds` (the vent rattles) and then un-seals it. Spawn the
  alien on the vent and send it `go_to(zone.global_position)`.
- **Rattle:** on a Blank, and whenever an alien arrives, every peer plays
  a rattle sound at the vent (`_rpc_rattle.rpc()`); use
  `PlaceholderSounds.noise_burst(0.4)`.
- **Vent travel:** an alien standing on a vent may move to a neighbouring
  zone's vent in `vent_travel_seconds`, ignoring doors: hide it, disable
  its collision, wait, move it, show it. Used when a door blocks it
  (M2.5 wait logic now tries the vent first), when wandering, and when
  fleeing.
- **Fleeing:** `alien.flee()` walks to its zone's vent (or the nearest
  usable one) and on arrival calls `match.on_alien_fled(alien)`, which
  does `pool.return_alien(alien.data.id)` and frees the alien. Fleeing
  heals it by definition, since a new one is spawned next time.
- **Kills:** `match.on_alien_died(alien, killer)` adds to the crew's kill
  count and to the killer's (`PlayerCharacter.peer_id`) personal count.
  Nothing returns to the pool.

`match.spawn_alien` now picks the scene by id: one scene per type under
`scenes/aliens/` (copy `crawler.tscn`, change the mesh size and colour and
the `data` resource).

### Idle behaviour (GDD "Behaviour")

Every `alien_think_interval` seconds an alien that is `IDLE`:

1. Looks for the loudest zone within two steps of its own zone (its
   neighbours and their neighbours) with noise above 0 that is not on
   fire: `go_to` it, by door if possible, else by vent.
2. Otherwise, with chance `alien_wander_chance`, takes the vent to a
   random neighbouring zone that is not on fire.

### Debug overlay (host only)

Add: pool counts, active aliens, ship cooldown, and for the current zone
its trigger cooldown. Add debug keys: F9 = +5 noise here, F10 = force an
encounter here.

### Tuning (`@export_group("Encounters")`)

| Name | Value | GDD |
| --- | --- | --- |
| `encounter_roll_interval` | 30.0 | Roll every 30 s |
| `encounter_chance_per_noise` | 0.04 | 4% per point of noise |
| `noise_after_encounter` | 3.0 | Meter drops to 3 |
| `blank_noise_multiplier` | 0.5 | A Blank halves the meter (README D6) |
| `encounter_zone_cooldown` | 45.0 | Same zone cannot trigger for 45 s |
| `encounter_ship_cooldown` | 20.0 | One encounter per 20 s ship-wide |
| `active_alien_minimum_cap` | 2 | Cap = awake players, at least 2 |
| `vent_travel_seconds` | 5.0 | Vent crawl to a neighbour |
| `alien_think_interval` | 2.0 | How often an idle alien picks a goal |
| `alien_wander_chance` | 0.2 | Chance per think to wander when all is quiet |
| `pool_larva` | `PackedInt32Array(3, 4, 4, 5)` | Tokens for 3, 4, 5, 6 players |
| `pool_crawler` | `PackedInt32Array(3, 4, 4, 5)` | |
| `pool_adult` | `PackedInt32Array(3, 3, 4, 4)` | |
| `pool_breeder` | `PackedInt32Array(1, 1, 2, 2)` | |
| `pool_queen` | `PackedInt32Array(1, 1, 1, 1)` | |

### Owner checks

- Nothing appears before 1:30 however loud you are.
- After 1:30, F9 twice (noise 10) makes a vent rattle and usually an
  alien climbs out; the zone's noise drops to 3 (or halves on a Blank,
  with a rattle and no alien).
- A second encounter in that zone cannot happen for 45 s, or anywhere for
  20 s.
- Walking and crouching never cause encounters; sprinting around for a
  few minutes does.
- With two aliens active (solo cap), a new encounter spawns nothing and
  the nearest alien walks to you.
- A welded vent: Crawlers come out of a neighbouring zone's vent instead.

---

## M4.2 Larva, Adult, Breeder, Queen

Numbers go in `data/aliens/*.tres` straight from the GDD table:

| Field | Larva | Crawler | Adult | Breeder | Queen |
| --- | --- | --- | --- | --- | --- |
| `max_health` | 10 | 30 | 80 | 150 | 400 |
| `move_speed` | 5 | 6 | 3 | 3.5 | 4 |
| `sight_range` | 8 | 20 | 0 | 15 | 25 |
| `sight_cone_degrees` | 360 | 120 | - | 360 | 360 |
| `hearing_range` | 0 | 10 | 20 | 15 | 25 |
| `charge_speed` / `charge_range` | - | - | 6 / 6 | - | - |
| `attack_interval` | - | 1.2 | 2 | 2.5 | 3 |
| `light_wounds_per_hit` | 0 | 1 | 0 | 0 | 0 |
| `serious_wounds_per_hit` | 0 | 0 | 1 | 1 | 2 |
| `contamination_per_hit` | 2 | 0 | 1 | 1 | 1 |
| `knockdown_seconds` | 0 | 0 | 0 | 1.5 | 0 |
| `latch_seconds` | 3 | 0 | 0 | 0 | 0 |
| `lock_break_seconds` | -1 | -1 | -1 | 5 | 0 |
| `weld_break_seconds` | -1 | -1 | -1 | 10 | 3 |
| `flee_health_fraction` | 0 | 0 | 0.3 | 0.3 | 0.25 |
| `flee_chance` | 0 | 0 | 0.5 | 0.5 | 1.0 |
| `drops_sample` | no | no | yes | yes | yes |
| `stun_immune` | no | no | no | no | yes |

Behaviour added to `alien.gd` (all driven by the data, no per-type
scripts unless the file passes about 400 lines; then split senses and
door handling into helper scripts):

- **Hearing as a sense (Adult, Breeder, Queen).** A blind alien cannot
  chase by sight, so it chases sound. `hear_noise` already handles loud
  events. Add footsteps: each think tick, a player inside
  `hearing_range` who is sprinting, or inside `footstep_hearing_range`
  who is walking (not crouched, not standing still), is "heard" and
  becomes the target position. Crouch-walking and standing still are
  never heard: that is the GDD's "slip past the Adult" rule. A heard
  target is a *position*, refreshed while the player keeps making sound;
  the alien attacks whoever is within reach when it gets there.
- **Charge (Adult):** when the heard position is within `charge_range`,
  move at `charge_speed`.
- **Latch (Larva):** on reaching a player, attach for `latch_seconds`
  (follow the player's position, player sees it on screen), then give
  `contamination_per_hit` cards (M5.2 hook: `match.give_contamination(
  player, count)`; a no-op until then) and `flee()`. Killing it while
  latched prevents the cards.
- **Contamination on wounds:** after an attack that wounds, call the same
  hook with `contamination_per_hit`.
- **Knockdown (Breeder):** `player.knock_down(seconds)`: the host tells
  the owner (private RPC); the owner's input is disabled and the camera
  drops for that long.
- **Fleeing:** the first time health drops below `flee_health_fraction`,
  roll `flee_chance` once; on success `flee()`.
- **Breaking doors and vents:** at a locked door with
  `lock_break_seconds >= 0`, or a welded one with `weld_break_seconds >=
  0`: wait that long (banging sound for everyone), then
  `door.unlock()` / un-weld and open it.
- **Stun:** `alien.stun(seconds)` freezes it unless `stun_immune`.
- **Fire:** aliens in a burning zone take `fire_alien_damage_per_second`
  and never choose a burning zone as a goal (M4.3).
- **Sample:** on death, if `drops_sample`, spawn an `alien_sample`
  pickup.

### Tuning

`footstep_hearing_range` 6.0.

### Debug

F11 cycles through alien types and spawns one at the nearest vent.

### Owner checks (use F11)

- Larva: fast, latches for 3 s, runs to a vent and vanishes. Shooting it
  off in time kills it (10 health).
- Adult: ignores you while you stand still or crouch-walk, even up
  close; walks to gunshots within 20 m; charges when you walk within 6 m;
  one hit = one serious wound. Below 30% health it sometimes flees.
- Breeder: sees and hears; a hit knocks you down for 1.5 s; breaks a
  locked door in 5 s and a welded one in 10 s.
- Queen: 400 health; 2 serious wounds per hit; walks through locks;
  breaks welds in 3 s; flees below 25% health; drops a sample if killed.

---

## M4.3 Hazards, integrity, event director

GDD *Ship systems and hazards*. Hazards are zone state on the host with a
public visual (everyone sees fire, darkness, a breach).

### Files

| File | Action |
| --- | --- |
| `scripts/world/zone.gd` | edit: hazard state and public RPCs |
| `scripts/match/hazard_system.gd` | new; child of `Match`, ticks every zone |
| `scripts/match/event_director.gd` | new; child of `Match` |
| `scripts/world/stations/repair_panel.gd`, `breach_point.gd` | new; one of each per room |
| `data/items/extinguisher.tres`, `toolkit.tres`, `o2_mask.tres` | new |

```gdscript
# FILE: scripts/match/event_director.gd
class_name EventDirector
extends Node
## Random ship events from 5:00, every 3-5 minutes (GDD "Random events").
## Host only. `HazardSystem` applies them.

## Emitted when an event should happen.
signal event_rolled(kind: Kind)

enum Kind { FIRE, MALFUNCTION, OUTAGE, BREACH }

var _timer := 0.0


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or GameState.phase != GameState.Phase.PLAYING:
		return
	if GameState.clock < Config.tuning.first_event_time:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var tuning := Config.tuning
	_timer = randf_range(tuning.event_interval_min, tuning.event_interval_max)
	event_rolled.emit(_pick_kind())


func _pick_kind() -> Kind:
	var tuning := Config.tuning
	var roll := randf()
	if roll < tuning.event_fire_chance:
		return Kind.FIRE
	roll -= tuning.event_fire_chance
	if roll < tuning.event_malfunction_chance:
		return Kind.MALFUNCTION
	roll -= tuning.event_malfunction_chance
	if roll < tuning.event_outage_chance:
		return Kind.OUTAGE
	return Kind.BREACH
```

### Rules for `HazardSystem` (host)

Zone state: `on_fire`, `fire_seconds`, `breached`, `malfunctioning`.
Section state: `section_powered` (Fore, Mid, Aft). Each change is
broadcast with one RPC per zone or section so clients can show it.

**Fire** (rooms only)

- Target: a random room that is not already burning.
- Players inside: 1 light wound every `fire_wound_interval` (4 s), each
  player on their own timer starting when they enter.
- Aliens inside: `fire_alien_damage_per_second` (10); they avoid it.
- Every `fire_spread_interval` (30 s): for each other room whose door
  opens on the **same corridor segment**, if both doors are open,
  `fire_spread_chance` (30%) to catch fire. (Interpretation of
  "neighbouring room"; confirm with the owner.)
- After `fire_burn_seconds` (180 s) it burns out and the room becomes
  malfunctioning.
- Integrity: `fire_integrity_per_minute` (1) per burning room.
- Put out: extinguisher item on the room's fire (10 s, 3 uses per
  extinguisher; the fire is an `Interactable` in the room's centre), or
  Fire Control (M4.5).
- Fires also start from fire bombs and 25% of explosions (M4.6). Kills by
  fire count for whoever started it: store `fire_starter_peer` on the
  zone.

**Hull breach** (rooms only)

- The room's door closes at once (it can be opened again).
- A player inside for more than `breach_grace_seconds` (10 s) takes 1
  light wound every `breach_wound_interval` (3 s), unless an O2 mask is
  anywhere in their inventory with air left. A mask holds
  `o2_mask_seconds` (60 s), drains only when needed, refills when the
  player is back in air. Show the air left on the HUD.
- Integrity: `breach_integrity_per_minute` (2) per open breach.
- Seal: welder on the room's `BreachPoint` (6 s), or Air Control.

**Malfunction**

- Every station in the room stops: `Interactable.can_interact` returns
  false and the prompt reads "Not working" while the station's zone is
  malfunctioning. (Give `Interactable` a `zone` reference set by the
  builder; doors and vents ignore malfunctions.)
- A malfunctioning engine room counts as a damaged engine; Pod Bay
  cannot launch; Cryo Bay takes no sleepers.
- Fix: toolkit on the room's `RepairPanel` (8 s, +2 noise).

**Power outage** (a random powered section)

- The section's lights go out for everyone (the builder keeps each
  zone's light; switch `visible`). Helmet lamps matter now.
- Terminals in the section stop (same check as malfunction, prompt "No
  power"). Cryopods and escape pods keep working.
- Every lock in the section releases (`door.unlock()`).
- Doors in the section must be forced: E becomes a
  `door_force_seconds` (3 s) hold that adds `door_force_noise` (2).
- Fix: the Generator breaker (M4.4).

**Room alarm:** while a room burns or is breached, add
`alarm_noise_amount` (1) to it every `alarm_noise_interval` (10 s), and
flash its light red.

**Integrity** (`ShipState.integrity`): drained per the rates above (per
second = rate / 60); each explosion costs `explosion_integrity_cost` (1).
Below `self_destruct_auto_integrity` (25) the self-destruct arms (M5.4;
until then log it). At 0: `ship_state.destroyed = true` and
`GameState.end_match(&"destroyed")`.

### Tuning (`@export_group("Hazards")`)

`first_event_time` 300.0, `event_interval_min` 180.0, `event_interval_max`
300.0, `event_fire_chance` 0.3, `event_malfunction_chance` 0.3,
`event_outage_chance` 0.2 (breach is the remainder), `fire_wound_interval`
4.0, `fire_alien_damage_per_second` 10.0, `fire_spread_interval` 30.0,
`fire_spread_chance` 0.3, `fire_burn_seconds` 180.0,
`fire_integrity_per_minute` 1.0, `extinguish_seconds` 10.0,
`extinguisher_uses` 3, `breach_grace_seconds` 10.0, `breach_wound_interval`
3.0, `breach_integrity_per_minute` 2.0, `breach_seal_seconds` 6.0,
`o2_mask_seconds` 60.0, `malfunction_repair_seconds` 8.0, `repair_noise`
2.0, `door_force_seconds` 3.0, `door_force_noise` 2.0, `alarm_noise_interval`
10.0, `alarm_noise_amount` 1.0, `explosion_integrity_cost` 1.0,
`self_destruct_auto_integrity` 25.0, `ship_start_integrity` 100.0.

### Debug

Shift+F5..F8 start a fire, breach, malfunction or outage in the current
zone or section. The host overlay shows integrity.

### Owner checks

- A fire: orange light and an alarm; you take a light wound every 4 s
  inside; an extinguisher puts it out in 10 s and works three times; left
  alone it dies after 3 minutes and the room's stations say "Not
  working" until repaired with a toolkit (8 s).
- A breach: the door slams; after 10 s you are wounded every 3 s; the
  welder seals it in 6 s; with an O2 mask you get 60 s first.
- An outage: the section goes dark; its doors need a 3 s noisy hold;
  locked doors there unlock.
- From 5:00 an event happens every 3-5 minutes without debug keys.
- Integrity falls while fires or breaches are open and the match ends
  with "ship destroyed" at 0 (set `ship_start_integrity` to 3 to test).

---

## M4.4 Engines, navigation console, breakers, Security

A shared UI piece first: **`ChoiceMenu`** (`scenes/ui/choice_menu.tscn`),
a centred list of options the local player picks from with the mouse or
number keys; Esc cancels. **`Terminal`** (extends `Interactable`) uses
it: E opens the menu locally; picking an option starts a timed "working"
bar (the option's seconds; moving out of reach or Esc cancels); when it
completes the client sends `request_choice(option_id)`; the host
validates and applies; any answer is a private message to that player.
Terminals never show who used them.

| Terminal | Room | Options | Time | Notes |
| --- | --- | --- | --- | --- |
| Engine console | Engine A / B / C | Check | 2 s | Private answer: "working" or "damaged" |
| | | Repair (needs toolkit in hand) | 15 s | +2 noise; sets working |
| | | Damage (needs toolkit in hand) | 10 s | +2 noise; sets damaged. To everyone else it must look and sound exactly like a repair: same bar, same sound, same noise |
| Navigation console | Bridge | Check course | 2 s | Private answer |
| | | Set course: Earth / Mars Station / Deep Space | 5 s | |
| Status panel | Bridge | Read | 0 s | Private: integrity and how many crew are alive and awake (no names) |
| Breakers | Generator | Fore / Mid / Aft: cut or restore | 5 s | The Generator's own section being dark does not stop the breakers (otherwise an outage there could never be fixed) |
| Door terminal | Security | Lock a door (list of all 12 doors) | 0 s | Lasts `door_lock_seconds`; `security_door_cooldown` (20 s) shared by everyone |
| Pod terminal | Security | Lock pod 1 / 2 / 3 | 0 s | Lasts `pod_lock_seconds` (60 s); a locked pod cannot be boarded or launched |

In the door list, a room the local player has not visited shows as
"Unknown room" plus its position ("fore, north side"), so the terminal
does not leak room types.

`ShipState.randomize_start()` (written in M2.7) is now called at match
start. A malfunctioning engine room counts as a damaged engine when the
match resolves.

The Bridge also gets the **Data Core** pickup (one `data_core` item).

### Tuning (`@export_group("Ship systems")`)

`engine_check_seconds` 2.0, `engine_repair_seconds` 15.0,
`engine_damage_seconds` 10.0, `course_check_seconds` 2.0,
`course_set_seconds` 5.0, `breaker_seconds` 5.0, `security_door_cooldown`
20.0, `pod_lock_seconds` 60.0.

### Owner checks

- Each engine console tells only you its state; at least one engine
  starts damaged; repair (15 s) and damage (10 s) both need a toolkit.
- The course starts unknown; setting it takes 5 s; checking again shows
  the new one.
- Cutting a section's power at the breakers has the same effect as an
  outage event; restoring it brings the lights back.
- The Security terminal locks a chosen door for 60 s, then cannot be
  used for 20 s.

---

## M4.5 Remaining rooms, room shuffle, personal map

- **Room types to add** (`data/rooms/` + furnishing scenes): `workshop`,
  `security`, `storage` (6 search spots, a second power cell), `comms`
  (2 radios; the broadcast microphone is a prop until voice exists),
  `lab` (analyser), `fire_control`, `air_control`. Essential: medbay,
  workshop, armory, security, generator. Optional: storage, comms, lab,
  fire_control, air_control.
- **Fire Control terminal:** list of rooms on fire; put one out;
  `remote_control_cooldown` (60 s).
- **Air Control terminal:** seal a breach in any room, or vent a room
  (opens to space for `vent_room_seconds` 15 s, then reseals): aliens
  inside take `vent_room_alien_damage` (60) and flee; players inside
  without an O2 mask take 1 serious wound. Same 60 s cooldown.
- **Shuffle** (host, at match start):

```gdscript
# FILE: scripts/match/room_shuffle.gd
class_name RoomShuffle
extends RefCounted
## Decides which room type goes in each slot for one match (GDD "Shuffled
## rooms"): fixed rooms stay; the 7 open slots get the 5 essential rooms
## plus 2 optional ones chosen at random, in random order.


## Returns slot id -> room type id for every slot.
static func make_assignment() -> Dictionary:
	var essential: Array[StringName] = []
	var optional: Array[StringName] = []
	for type: RoomType in Config.room_types.values():
		if type.is_fixed:
			continue
		if type.is_essential:
			essential.append(type.id)
		else:
			optional.append(type.id)
	optional.shuffle()
	var open_slots := 0
	for slot: Dictionary in ShipLayout.SLOTS:
		if slot.fixed == &"":
			open_slots += 1
	var chosen := essential + optional.slice(0, open_slots - essential.size())
	chosen.shuffle()
	var assignment := {}
	for slot: Dictionary in ShipLayout.SLOTS:
		if slot.fixed != &"":
			assignment[slot.id] = slot.fixed
		else:
			assignment[slot.id] = chosen.pop_back()
	return assignment
```

- **Personal map** (`scripts/ui/ship_map.gd`, toggled with M or Tab): a
  2D drawing of the hull from `ShipLayout`, drawn with `_draw()` on a
  `Control`. It starts with the outline and the Cryo Bay. When the
  **local** player's `current_zone` becomes a room, record that slot's
  type locally and draw its name. Nothing about the map is ever sent
  over the network. Other players are not shown.
- **Known compromise to tell the owner:** every client receives the full
  room assignment at match start, because every peer must build the same
  ship. The UI never shows it before a visit, but a modified client could
  read it. Hiding it properly means building room interiors only when a
  door first opens; write that in `docs/later.md`.

### Tuning

`remote_control_cooldown` 60.0, `vent_room_seconds` 15.0,
`vent_room_alien_damage` 60.0.

### Owner checks

- Two matches in a row have different rooms behind the 7 unfixed doors;
  the five fixed rooms never move; all five essential rooms are always
  present.
- The map shows only the Cryo Bay at first and fills in as you enter
  rooms; in a two-window test each player's map is their own.
- Fire Control and Air Control (when drawn) work from their rooms.

---

## M4.6 Remaining weapons and items, crafting, full loot deck

### Weapons (`WeaponData` or `ItemData` values from the GDD)

| Item | Kind | Hands | Damage | Capacity | Noise | Extra |
| --- | --- | --- | --- | --- | --- | --- |
| Punch (empty main hand) | MELEE | - | 5 | - | 1 per hit | Always available |
| `knife` | MELEE | 1 | 15 | - | 1 | |
| `stun_baton` | MELEE | 1 | 5 | 6 charges | 1 | Stuns 3 s (not the Queen); a battery recharges it |
| `welder` | MELEE + TOOL | 1 | 20 | - | 1 | |
| `pipe_club` | MELEE | 1 | 25 | - | 1 | Crafted |
| `assault_rifle` | HITSCAN | 2 | 12 | 20 | 1 per round | Automatic |
| `shotgun` | HITSCAN | 2 | 8 x 8 pellets | 4 | 4 | Wide spread |
| `grenade`, `pipe_bomb` | THROWN | 1 | 120 to every alien in the room | 1 | 6 | 1 serious wound to every player in the room, thrower included |
| `fire_bomb` | THROWN | 1 | - | 1 | 3 | Sets the room on fire |
| `noisemaker` | THROWN | 1 | - | 1 | +3 every 5 s for 15 s where it lands | |

- **Melee:** a short ray (`melee_range` 2.0 m) from the camera with
  `Layers.BULLET_MASK`; `melee_interval` 0.6 s between swings; noise only
  on a hit. Players are not on the mask, so melee never hurts players.
- **Thrown:** the host spawns a `RigidBody3D` (through a spawner) thrown
  along the camera direction at `throw_speed`. After `fuse_seconds` it
  acts on the zone containing it (`GameState.get_zone_at(position)`: test
  the point against each zone's box).
- **Explosion** (`match.explode(zone, thrower_peer)`): every alien in the
  zone takes the damage (kills credited to the thrower); every player in
  the zone gets 1 serious wound; +6 noise; integrity -1; 25% chance the
  room catches fire (rooms only). This is the only player-vs-player
  damage besides fire and venting.
- **Lab analysis:** an Alien Sample in hand at the Lab analyser (15 s)
  is used up and sets `match.alien_damage_multiplier` to 1.25 for
  everyone for the rest of the match. Apply the multiplier in one place:
  where the host calls `take_damage` on an alien.

### Other items

`handheld_scanner` (charges; effect in M5.2), `motion_tracker` (HUD
radar of anything moving within 15 m, aliens and players alike; 180 s of
use per battery; the host sends the owner the blips), `flashlight`
(a brighter `SpotLight3D` while in a hand), `radio` (item only until
voice), `battery`, `chemicals`, `rag`, `duct_tape`, `pipe`,
`alien_sample`, `data_core`. A battery in a hand used with the other
hand's tracker or baton recharges it instantly, anywhere.

### Crafting

```gdscript
# FILE: scripts/data/recipe_data.gd
class_name RecipeData
extends Resource
## One crafting recipe. One .tres per recipe in res://data/recipes/.

## Short id, for example &"fire_bomb".
@export var id: StringName = &""
## The two ingredient item ids. Both are used up.
@export var ingredient_a: StringName = &""
@export var ingredient_b: StringName = &""
## The item made. Empty when the recipe only recharges something.
@export var result: StringName = &""
## Scanner recipe: charges added to the scanner instead of making an item.
@export var adds_charges: int = 0
```

Recipes (GDD table): chemicals + rag = fire_bomb; chemicals + pipe =
pipe_bomb; battery + duct_tape = noisemaker; pipe + duct_tape =
pipe_club; rag + duct_tape = bandage; battery + handheld_scanner =
scanner with 2 more charges (`adds_charges = 2`, the scanner is kept).

The **workbench** (Workshop, a `Terminal`) lists only the recipes the
player has both ingredients for anywhere in their inventory; crafting
takes `craft_seconds` (8 s) and adds `craft_noise` (2).

### Loot deck

`LootDeck.setup` now gets the real player count and the GDD extras: add a
`keycard` if nobody is the Captain, a `toolkit` if nobody is the
Mechanic (until roles exist in M5.1, always add both), and a `radio` if
the Comms room was not drawn. The Armory gun rack holds a pistol or
shotgun at random.

### Tuning

`melee_range` 2.0, `melee_interval` 0.6, `punch_damage` 5.0,
`stun_seconds` 3.0, `throw_speed` 12.0, `fuse_seconds` 2.5,
`explosion_alien_damage` 120.0, `explosion_noise` 6.0,
`explosion_fire_chance` 0.25, `fire_bomb_noise` 3.0,
`noisemaker_noise` 3.0, `noisemaker_interval` 5.0, `noisemaker_seconds`
15.0, `lab_analysis_seconds` 15.0, `lab_damage_multiplier` 1.25,
`craft_seconds` 8.0, `craft_noise` 2.0, `motion_tracker_range` 15.0,
`motion_tracker_battery_seconds` 180.0.

### Owner checks

- You can punch with an empty hand (5 damage, +1 noise per hit).
- The rifle fires while held (+1 noise per round); the shotgun kills a
  Crawler up close in one shot and adds 4 noise.
- A grenade in a room: aliens there take 120, you take a serious wound if
  you are inside, the room sometimes catches fire.
- A noisemaker thrown into another room pulls an encounter there, not on
  you.
- Each of the six recipes works at the workbench and nowhere else.
- Searching the whole ship in a solo game finds 22 cards plus the extras.

---

## M4.7 Lighting and sound mood pass

Cheap atmosphere, still with generated placeholder sounds:

- Dim the room lights; add a small coloured light at every terminal.
- Alarm lighting at 35:00 (`final_warning`): every light pulses red.
- Announcements at 30:00, 35:00 and each self-destruct minute: a HUD
  banner plus a tone.
- Low drone loop; vent rattle; door slide; alien footsteps (a tick sound
  whose rate follows speed) so a careful player can hear an Adult coming.
- Sounds use `AudioStreamPlayer3D` so distance and direction are
  audible.

### Gate 4

Play (or host) three matches. Quiet play must be visibly safer: a player
who crouch-walks and closes doors meets fewer aliens than one who sprints
and shoots. If not, tune `encounter_chance_per_noise`,
`sprint_noise_interval` and the pool sizes in `tuning.tres` and note the
changes in `docs/playtest-notes.md`.
