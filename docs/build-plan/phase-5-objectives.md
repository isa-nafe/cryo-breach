# Phase 5: secret objectives

Goal: the full game. Roles, hidden infection, cryosleep, the
self-destruct, two secret objectives per player, the end-of-match
resolution, and bots for testing alone. GDD sections: *Players > Roles*,
*Objectives*, *Infection*, *Ship systems > Self-destruct*, *Escaping and
the end of the match*.

**Secrecy checklist for every milestone in this phase.** Before calling
it done, search the new code for these mistakes:

- a secret stored in a property a `MultiplayerSynchronizer` sends;
- a secret sent with `.rpc(` (everyone) instead of `.rpc_id(owner, `;
- a secret stored on a node on clients "for later" (objectives,
  contamination cards, other players' wounds or inventories).

Test with two windows: open the *Remote* scene tree in the editor on the
client and check the other player's nodes hold none of it.

---

## M5.1 Roles, lobby role pick, starting gear

```gdscript
# FILE: scripts/data/role_data.gd
class_name RoleData
extends Resource
## One crew role. Roles differ only in starting gear (GDD "Roles").

## Short id, for example &"captain".
@export var id: StringName = &""
@export var display_name: String = ""
## One line for the lobby about what the gear is good for.
@export var summary: String = ""
## Item ids the role starts with, in the order they are handed out
## (hands first, then slots).
@export var starting_items: Array[StringName] = []
## How many of each starting item, same order as `starting_items`.
@export var starting_counts: PackedInt32Array = PackedInt32Array()
```

| Role | `starting_items` (count) |
| --- | --- |
| `captain` | pistol, keycard, radio |
| `soldier` | assault_rifle, knife, grenade |
| `mechanic` | toolkit, welder, o2_mask |
| `medic` | medkit (2), bandage (2), handheld_scanner |
| `scout` | motion_tracker, noisemaker (2), knife |
| `scientist` | stun_baton, chemicals (2), rag |

Medkits do not stack (limit 1), so the Medic's two medkits take two
places. The scanner starts with 2 charges, the pistol with 8 rounds, the
rifle with 20.

- **Lobby:** each player picks a role from the six; one player per role,
  first come first served. `Net.request_role(role_id)` goes to the host,
  which accepts it only if it is free, then re-broadcasts `Net.players`.
  The host cannot start until everyone has a role. Roles are public in
  the lobby and on the end screen, never in the match.
- **Match start (host):** give each player their gear with
  `inventory.add`; remove the Phase 2 test pistol and floor items.
- **Loot extras:** keycard if no Captain, toolkit if no Mechanic, radio
  if no Comms room (already wired in M4.6; now use the real roles).

### Owner checks

- Two windows cannot pick the same role.
- Each role starts with exactly its GDD gear; the Soldier's rifle is in
  both hands.

---

## M5.2 Contamination deck, scanners, surgery

```gdscript
# FILE: scripts/match/contamination_deck.gd
class_name ContaminationDeck
extends RefCounted
## The hidden deck of contamination cards (GDD "Infection"). Host only.
## A card is just a bool: true = infected.

var _cards: Array[bool] = []


func setup() -> void:
	_cards.clear()
	var tuning := Config.tuning
	for i in tuning.contamination_deck_size:
		_cards.append(i < tuning.contamination_infected_cards)
	_cards.shuffle()


## Takes up to `count` cards off the top.
func draw(count: int) -> Array[bool]:
	var drawn: Array[bool] = []
	for _i in count:
		if _cards.is_empty():
			break
		drawn.append(_cards.pop_back())
	return drawn


## Thrown-away cards are shuffled back in.
func discard(cards: Array[bool]) -> void:
	_cards.append_array(cards)
	_cards.shuffle()
```

```gdscript
# FILE: scripts/match/player_secrets.gd
class_name PlayerSecrets
extends RefCounted
## What the host knows about one player that nobody else may see:
## contamination cards, objectives, kill count. Lives in a dictionary on
## the Match node keyed by peer id. Never put this on the player node.

## Contamination cards held: true = infected.
var cards: Array[bool] = []
## Same length as `cards`: true once a scanner has looked at the card.
var checked: Array[bool] = []
## The two objectives dealt: {"id": StringName, "target_role": StringName}.
var crew_objective: Dictionary = {}
var personal_objective: Dictionary = {}
## The objective committed to; empty until the commit.
var committed: Dictionary = {}
## Aliens this player killed.
var kills: int = 0


func add_cards(new_cards: Array[bool]) -> void:
	for card: bool in new_cards:
		cards.append(card)
		checked.append(false)


## Scanner: clean cards are thrown away and returned so the deck can take
## them back; infected ones stay, now marked as checked.
func scan() -> Array[bool]:
	var kept: Array[bool] = []
	var thrown: Array[bool] = []
	for card: bool in cards:
		if card:
			kept.append(card)
		else:
			thrown.append(card)
	cards = kept
	checked.clear()
	for _i in cards.size():
		checked.append(true)
	return thrown


## Surgery: every card is removed and returned for the deck.
func remove_all_cards() -> Array[bool]:
	var removed := cards
	cards = []
	checked = []
	return removed


func has_infected_card() -> bool:
	return true in cards


## What the owner's HUD may show: counts only.
func get_card_summary() -> Dictionary:
	return {"unchecked": checked.count(false), "infected": checked.count(true)}
```

- `match.gd` (host): `var contamination := ContaminationDeck.new()`,
  `var secrets: Dictionary` (peer id to `PlayerSecrets`).
  `give_contamination(player, count)` (the hook from M4.2) draws, adds,
  and sends the owner the new summary with `rpc_id`.
- **HUD:** "Contamination: 3 unchecked, 1 infected" for the owner only.
  A card has no other effect: no symptoms, no sound.
- **Medbay scanner** (`Terminal`, 5 s, unlimited): `scan()`, discard the
  clean cards to the deck, private message "2 clean cards thrown away, 1
  infected".
- **Handheld scanner:** `use_kind = SCANNER`, hold `scanner_seconds`;
  same effect; uses one charge; checks only yourself.
- **Surgery pod** now offers two choices (12 s, +2 noise): remove one
  serious wound, **or** remove all contamination cards (and take 1 light
  wound).
- Larva latch = 2 cards; each wound from an Adult, Breeder or Queen = 1.

### Tuning (`@export_group("Infection")`)

`contamination_deck_size` 24, `contamination_infected_cards` 9,
`scanner_seconds` 5.0, `handheld_scanner_charges` 2, `surgery_light_wounds`
1.

### Owner checks

- A Larva latch adds 2 unchecked cards to your HUD and nothing else
  happens.
- The Medbay scanner removes the clean ones and marks the infected ones;
  only your window shows the result.
- Surgery clears all cards and gives one light wound.
- In a two-window test the other player's card count is nowhere on the
  client (Remote scene tree).

---

## M5.3 Cryosleep and the full pod rules

**Cryosleep** (GDD "Cryosleep")

- The 6 cryopods in the Cryo Bay are `Interactable`s: "Locked until
  20:00" until `ship_state.cryo_unlocked` (set at the `cryo_unlock` time
  mark, or when the self-destruct is armed; it never re-locks).
- Getting in: `cryo_enter_seconds` (5 s) hold, cannot be undone. Not
  possible while the Cryo Bay is malfunctioning.
- The player's fate becomes `SLEEPING`: character hidden inside the pod,
  cannot be harmed, spectates. Whether they live is decided only at the
  resolution.

**Escape pods** (replace the Phase 2 single pod)

- 3 pods, 2 seats each. Each pod has its own state: seats, locked
  seconds (Security terminal), launching, launched.
- Boarding 2 s; get out any time before launch.
- Any seated player holds to start the 10 s launch (+5 noise in the Pod
  Bay). During the countdown, **anyone seated in that pod** can hold to
  abort. A player not seated when it launches is left behind.
- Cannot launch while the Pod Bay is malfunctioning or the pod is locked.
- Aliens cannot enter a pod, but a seated player is still inside the Pod
  Bay zone for alien attacks until launch (GDD: "can still attack people
  boarding"); seated players cannot be attacked.
- On launch: occupants' fate becomes `ESCAPED`; record the pod's launch
  time and occupant count on the host (needed for objectives).

**Ending early:** after every fate change, the host checks whether any
player is still `AWAKE`; if none, `GameState.end_match(&"nobody_awake")`.

### Tuning

`cryo_enter_seconds` 5.0, `pod_count` 3, `pod_seats` 2.

### Owner checks

- Cryopods refuse you before 20:00 (set `cryo_unlock_time` to 20 to
  test) and take 5 s after.
- Two players can sit in one pod; either can start the launch; the other
  can abort it during the 10 s.
- A pod locked from Security cannot be boarded for 60 s.
- When the last awake player sleeps, escapes or dies, the match ends at
  once.

---

## M5.4 Self-destruct

```gdscript
# FILE: scripts/match/self_destruct.gd
class_name SelfDestruct
extends RefCounted
## The self-destruct state machine (GDD "Self-destruct"). Host only.
## The Match node calls `tick` every physics frame and reacts to the
## signals.

## Emitted when it is armed (by hand or by low integrity).
signal armed
## Emitted when it is cancelled.
signal cancelled
## Emitted each time a whole minute is left, for the announcement.
signal minute_left(minutes: int)
## Emitted when the countdown reaches zero.
signal detonated

var is_armed := false
## Seconds until detonation while armed.
var seconds_left: float = 0.0

var _rearm_cooldown := 0.0
var _last_minute_announced := -1


func tick(delta: float) -> void:
	_rearm_cooldown = maxf(_rearm_cooldown - delta, 0.0)
	if not is_armed:
		return
	seconds_left -= delta
	var minutes := ceili(seconds_left / 60.0)
	if minutes != _last_minute_announced and minutes > 0:
		_last_minute_announced = minutes
		minute_left.emit(minutes)
	if seconds_left <= 0.0:
		is_armed = false
		detonated.emit()


## True if a player may arm it now.
func can_arm() -> bool:
	return not is_armed and _rearm_cooldown <= 0.0


## Arms it. `forced` is true when low integrity arms it by itself, which
## ignores the re-arm cooldown.
func arm(forced: bool = false) -> bool:
	if is_armed or (not forced and _rearm_cooldown > 0.0):
		return false
	is_armed = true
	seconds_left = Config.tuning.self_destruct_seconds
	_last_minute_announced = -1
	armed.emit()
	return true


## True while it can still be stopped.
func can_cancel() -> bool:
	return is_armed and seconds_left > Config.tuning.self_destruct_point_of_no_return


func cancel() -> bool:
	if not can_cancel():
		return false
	is_armed = false
	_rearm_cooldown = Config.tuning.self_destruct_rearm_cooldown
	cancelled.emit()
	return true
```

- **Bridge terminal:** "Arm self-destruct" (10 s, needs a keycard in a
  hand, only when `can_arm()`); "Cancel self-destruct" (10 s, no
  keycard, only when `can_cancel()`).
- **On `armed`:** `ship_state.pods_unlocked = true`,
  `ship_state.cryo_unlocked = true` (both stay unlocked even after a
  cancel); ship-wide announcement.
- **On `minute_left`:** ship-wide announcement "Self-destruct in N
  minutes".
- **On `detonated`:** `ship_state.destroyed = true`,
  `GameState.end_match(&"destroyed")`.
- **Low integrity:** when integrity drops below
  `self_destruct_auto_integrity`, `arm(true)`.
- **At the jump:** if it is still armed, the ship counts as destroyed
  (handled by the resolver through `MatchFacts.ship_destroyed`).

### Tuning

`self_destruct_seconds` 360.0, `self_destruct_point_of_no_return` 60.0,
`self_destruct_rearm_cooldown` 120.0, `self_destruct_hold_seconds` 10.0.

### Owner checks

- Arming needs a keycard and a 10 s hold; everyone gets the announcement
  and pods and cryopods unlock at once.
- Cancelling works until 1:00 is left, then the option disappears.
- After a cancel it cannot be armed for 2 minutes.
- At zero the match ends: everyone aboard dies, launched pods survive.

---

## M5.5 Objectives: deal, commit, track, resolve, end screen

### Data

```gdscript
# FILE: scripts/data/objective_data.gd
class_name ObjectiveData
extends Resource
## One secret objective. One .tres per objective in res://data/objectives/.
## The rule itself is in ObjectiveRules, looked up by `id`.

## Short id, for example &"hunter".
@export var id: StringName = &""
## Name shown to its owner and on the end screen.
@export var title: String = ""
## What must be true besides surviving. "{role}" is replaced by the
## target role's name.
@export var description: String = ""
## False = crew objective, true = personal objective.
@export var is_personal: bool = false
## True if the objective names another role (Bodyguard, Grudge).
@export var needs_target_role: bool = false
```

Create 17 files with the GDD's titles and texts. Ids, crew:
`strength_in_numbers`, `bring_her_home`, `pest_control`, `save_the_ship`,
`clean_bill`, `bodyguard`, `sleep_together`, `full_house`. Personal:
`alone_in_the_dark`, `grudge`, `corporate_secrets`, `specimen`,
`exclusive`, `hunter`, `early_exit`, `cold_storage`, `quarantine`.

### Resolution (pure logic, easy to test without the game)

```gdscript
# FILE: scripts/match/player_record.gd
class_name PlayerRecord
extends RefCounted
## One player's part in the end-of-match resolution. The host fills the
## top half; MatchResolver fills the results.

enum Fate { AWAKE, DEAD, SLEEPING, ESCAPED }

var peer_id: int = 0
var player_name: String = ""
var role: StringName = &""
var fate: Fate = Fate.AWAKE
## Index of the pod the player left in, or -1.
var pod_index: int = -1
var has_infected_card := false
var kills: int = 0
var carries_data_core := false
var carries_sample := false
## The committed objective and, if it names one, its target role.
var objective_id: StringName = &""
var target_role: StringName = &""

## Results.
var survived := false
var died_of_infection := false
## Why the player did not survive ("" if they did or were already dead).
var death_reason: String = ""
var objective_met := false
```

```gdscript
# FILE: scripts/match/match_facts.gd
class_name MatchFacts
extends RefCounted
## What the host knows about the ship when the match ends.

## Self-destruct went off or is still running, or integrity reached 0.
var ship_destroyed := false
## All three engines work and no engine room is malfunctioning.
var engines_working := false
var course_is_earth := false
## An alien is in the Cryo Bay, or it is burning or malfunctioning.
var cryo_bay_unsafe := false
## Aliens killed by the whole crew.
var crew_kills: int = 0
var player_count: int = 0
## One entry per launched pod: seconds on the clock when it launched.
var pod_launch_times: Array[float] = []
## One entry per launched pod: how many players were in it.
var pod_occupants: Array[int] = []
```

```gdscript
# FILE: scripts/match/match_resolver.gd
class_name MatchResolver
extends RefCounted
## Works out who survived and who met their objective (GDD "Resolving the
## match"). Pure logic: no nodes, no network.


static func resolve(records: Array[PlayerRecord], facts: MatchFacts) -> void:
	for record: PlayerRecord in records:
		_resolve_survival(record, facts)
	for record: PlayerRecord in records:
		record.objective_met = record.survived and ObjectiveRules.is_met(record, records, facts)


static func _resolve_survival(record: PlayerRecord, facts: MatchFacts) -> void:
	match record.fate:
		PlayerRecord.Fate.ESCAPED:
			# A launched pod is safe whatever happens to the ship, and
			# escapees are never checked for infection.
			record.survived = true
		PlayerRecord.Fate.DEAD:
			record.survived = false
		PlayerRecord.Fate.AWAKE:
			record.survived = false
			if facts.ship_destroyed:
				record.death_reason = "Died with the ship"
			else:
				record.death_reason = "Left behind at the jump"
		PlayerRecord.Fate.SLEEPING:
			record.death_reason = _get_sleeper_death(record, facts)
			record.survived = record.death_reason.is_empty()


## Steps 2 to 5 of the GDD list, in order. "" means the sleeper lives.
static func _get_sleeper_death(record: PlayerRecord, facts: MatchFacts) -> String:
	if facts.ship_destroyed:
		return "The ship was destroyed"
	if not facts.engines_working or not facts.course_is_earth:
		return "The ship was lost in space"
	if facts.cryo_bay_unsafe:
		return "The Cryo Bay was not safe"
	if record.has_infected_card:
		record.died_of_infection = true
		return "Infection"
	return ""
```

```gdscript
# FILE: scripts/match/objective_rules.gd
class_name ObjectiveRules
extends RefCounted
## The condition behind each objective id (GDD "Objectives"). Surviving is
## checked by MatchResolver before this is called.


static func is_met(
	record: PlayerRecord, records: Array[PlayerRecord], facts: MatchFacts
) -> bool:
	var tuning := Config.tuning
	var survivors := _count(records, func(r: PlayerRecord) -> bool: return r.survived)
	var sleepers := _count(
		records,
		func(r: PlayerRecord) -> bool: return r.survived and r.fate == PlayerRecord.Fate.SLEEPING
	)
	var is_sleeper := record.fate == PlayerRecord.Fate.SLEEPING
	var escaped := record.fate == PlayerRecord.Fate.ESCAPED and record.pod_index >= 0
	var met := false
	match record.objective_id:
		&"strength_in_numbers":
			met = survivors - 1 >= tuning.strength_in_numbers_others
		&"bring_her_home":
			met = not facts.ship_destroyed and facts.engines_working and facts.course_is_earth
		&"pest_control":
			var needed: int = tuning.pest_control_kills
			if facts.player_count <= 3:
				needed = tuning.pest_control_kills_small
			met = facts.crew_kills >= needed
		&"save_the_ship":
			met = not facts.ship_destroyed
		&"clean_bill":
			met = _count(records, func(r: PlayerRecord) -> bool: return r.died_of_infection) == 0
		&"bodyguard":
			met = _role_survived(records, record.target_role)
		&"sleep_together":
			met = is_sleeper and sleepers >= 2
		&"full_house":
			met = not facts.pod_occupants.is_empty()
			for occupants: int in facts.pod_occupants:
				met = met and occupants >= tuning.pod_seats
		&"alone_in_the_dark":
			met = escaped and facts.pod_occupants[record.pod_index] == 1
		&"grudge":
			met = not _role_survived(records, record.target_role)
		&"corporate_secrets":
			met = record.carries_data_core
		&"specimen":
			met = record.carries_sample
		&"exclusive":
			met = survivors <= tuning.exclusive_max_survivors
		&"hunter":
			met = record.kills >= tuning.hunter_kills
		&"early_exit":
			met = escaped and facts.pod_launch_times[record.pod_index] < tuning.jump_warning_time
		&"cold_storage":
			met = is_sleeper and sleepers == 1
		&"quarantine":
			met = not facts.course_is_earth
		_:
			push_warning("Unknown objective id: %s" % record.objective_id)
	return met


static func _count(records: Array[PlayerRecord], test: Callable) -> int:
	var total := 0
	for record: PlayerRecord in records:
		if test.call(record):
			total += 1
	return total


static func _role_survived(records: Array[PlayerRecord], role: StringName) -> bool:
	for record: PlayerRecord in records:
		if record.role == role:
			return record.survived
	return false
```

Write a small test scene (`scenes/tests/resolver_test.tscn` with a script
that builds records by hand, calls `MatchResolver.resolve`, and prints
PASS/FAIL per case) covering at least: a sleeper on a good ship lives; a
sleeper dies for each of the four reasons in order; an escapee with an
infected card lives; Quarantine with course Mars; Full house with a
1-player pod fails; Cold storage with two sleepers fails. Run it headless
if Godot is available.

### Dealing (host, at match start)

```gdscript
# FILE: scripts/match/objective_dealer.gd
class_name ObjectiveDealer
extends RefCounted
## Deals one crew and one personal objective to each player with no
## repeats across the table (GDD "How objectives work"). Host only.


## `roles` maps peer id -> role id. Returns peer id ->
## {"crew": {"id", "target_role"}, "personal": {"id", "target_role"}}.
static func deal(roles: Dictionary) -> Dictionary:
	var crew: Array[ObjectiveData] = []
	var personal: Array[ObjectiveData] = []
	for objective: ObjectiveData in Config.objectives.values():
		# An objective that names another role needs another player.
		if objective.needs_target_role and roles.size() < 2:
			continue
		if objective.is_personal:
			personal.append(objective)
		else:
			crew.append(objective)
	crew.shuffle()
	personal.shuffle()
	var dealt := {}
	for peer_id: int in roles:
		dealt[peer_id] = {
			"crew": _make(crew.pop_back(), peer_id, roles),
			"personal": _make(personal.pop_back(), peer_id, roles),
		}
	return dealt


static func _make(objective: ObjectiveData, peer_id: int, roles: Dictionary) -> Dictionary:
	var target: StringName = &""
	if objective.needs_target_role:
		var others: Array[StringName] = []
		for other_id: int in roles:
			if other_id != peer_id:
				others.append(roles[other_id])
		target = others.pick_random()
	return {"id": objective.id, "target_role": target}
```

### Flow

1. **0:00:** the host deals, stores both objectives in each player's
   `PlayerSecrets`, and sends each player their own two with `rpc_id`.
   The HUD shows them (key O toggles the panel).
2. **10:00 (`commit` time mark):** each client gets a `ChoiceMenu` with
   its two objectives (it can also commit earlier from the O panel). The
   client sends `request_commit(index)`. Anyone who has not answered
   within `commit_grace_seconds` gets one at random. The other objective
   is discarded; the HUD shows only the committed one.
3. **During the match:** the host tracks what the rules need: kills per
   player and crew total (M4.1), pod launch times and occupants (M5.3).
   Fire kills count for `zone.fire_starter_peer`.
4. **At the end:** the host builds a `PlayerRecord` per player
   (`carries_*` = the item is anywhere in their inventory;
   `has_infected_card` from `PlayerSecrets`) and a `MatchFacts`
   (`ship_destroyed` = destroyed or self-destruct still armed or
   integrity at 0), calls `MatchResolver.resolve`, and broadcasts the
   results. Only now does every objective become public.
5. **End screen:** one row per player: name, role, fate and reason,
   objective title and text, met or not, "WON" for survived + met.
   Several players can win, or none.

### Tuning (`@export_group("Objectives")`)

`commit_grace_seconds` 20.0, `strength_in_numbers_others` 2,
`pest_control_kills` 5, `pest_control_kills_small` 4,
`exclusive_max_survivors` 2, `hunter_kills` 3.

### Owner checks

- Each window shows two different objectives; no objective appears in
  two windows.
- At 10:00 (set `commit_time` to 30 to test) a choice appears; not
  choosing picks one at random.
- The end screen shows everyone's objective and result, and matches what
  happened (try: both sleep with a damaged engine; one escapes alone
  with *Alone in the dark*).
- The resolver test scene prints all PASS.

---

## M5.6 Giving items, bodies, name badges, bots

- **Giving** (GDD): looking at a player within `give_range` (2 m) with
  an item in the main hand shows "[F] Offer (item)". The host sends the
  other player a private prompt "(name) offers you (item): [Y] accept";
  it expires after `give_offer_seconds`. On accept the host moves the
  stack if it fits. Items can never be taken from a living player.
  (Move the lamp toggle to L if F is used here; update the README.)
- **Bodies:** a dead player's character becomes a `Body` interactable
  ("Search body", 2 s, +1 noise) that opens a `ChoiceMenu` of its items;
  picking one moves it to the searcher. This is the first time another
  player's inventory is sent to anyone, and only for a dead player.
- **Name badge:** a `Label3D` above each character showing only the
  player's name, visible only while the local camera looks at that
  player within `name_badge_range` (10 m) with a clear line of sight. No
  role, wounds or items.
- **Dead, sleeping and escaped players** can type to each other in a
  text box the living never see (stands in for the separate voice
  channel until voice exists).
- **Bots** (development plan rule 3: "test with bots"):
  - Extract a base class `InputSource` (a `Node` with `var state:
    InputState`, `var enabled`, and `func poll() -> InputState`) from
    `PlayerInput`; `PlayerCharacter.input_source` becomes that type.
  - `BotInput` extends it, runs on the host, and owns a
    `NavigationAgent3D` on the bot's body. It fills `InputState` the way
    a human would:

```gdscript
# In bot_input.gd: turning a navigation path into InputState.


func _steer_toward(body: PlayerCharacter, next_point: Vector3) -> void:
	var to_point := next_point - body.global_position
	to_point.y = 0.0
	if to_point.length() < 0.2:
		state.move = Vector2.ZERO
		return
	# Turn the body to face the next path point, then walk forward.
	var wanted_yaw := atan2(-to_point.x, -to_point.z)
	state.look_delta.x = angle_difference(body.rotation.y, wanted_yaw)
	state.move = Vector2(0.0, 1.0)
```

  - A bot has a peer id that no real peer uses (negative numbers), its
    own `PlayerSecrets`, and commits to a random objective.
  - Behaviour, one goal at a time: wander to a random unvisited room and
    search it; shoot a visible alien if armed, otherwise walk away; after
    `bot_exit_time`, go for its way out (cryosleep if unlocked and its
    objective allows, else a pod).
  - The lobby gets an "Add bot" button for the host.

### Tuning

`give_range` 2.0, `give_offer_seconds` 10.0, `name_badge_range` 10.0,
`body_search_seconds` 2.0, `bot_exit_time` 1500.0.

### Gate 5

A full 3-6 player match (bots count for testing, people for the gate)
plays from lobby to end screen. Check: nobody could see another player's
objective, wounds, cards or map; at least one match had two players
whose goals conflicted; the end screen was correct. Ask players what
they thought the others' objectives were; if everyone guessed right,
note it in `docs/playtest-notes.md`.
