# Phase 3: co-op networking

Goal: 2-4 players (the code allows 6) host and join over LAN or direct IP
and play the Phase 2 slice together. Read the "Networking rules" in
`docs/development-plan.md` and README section 4.3 first.

**No new game rules in this phase.** If a rule seems missing, it belongs
in Phase 4 or 5.

## How the network model works (explain this to the owner once)

- **Host** = peer id 1. It runs every rule: wounds, inventories, doors,
  aliens, noise, loot, the clock. Solo play is a host with no clients.
- **Each client moves its own character** and sends the position to
  everyone (README decision D3). Everything else a client does is a
  request to the host.
- Three kinds of message:

  | Kind | Godot tool | Used for |
  | --- | --- | --- |
  | Continuous state | `MultiplayerSynchronizer` | Player and alien positions |
  | Public events | `@rpc` sent to everyone | Door opened, shot fired, player died, match ended |
  | Private facts | `rpc_id(owner, ...)` | Your wounds, your inventory, search results, later your objectives and scan results |

- **Rule for secrets:** never in a synchronizer, never in a broadcast.
- **Rule for node paths:** an RPC is delivered to "the node at this path",
  so every node that sends or receives RPCs must have the same name and
  path on every peer. Nodes created in code get random names unless you
  set `name` before `add_child`. M3.4 names them.
- **Useful facts:** `multiplayer.is_server()` is true on the host and
  offline. Inside an RPC, `multiplayer.get_remote_sender_id()` is who sent
  it, and is `0` when the function was called locally.

**Testing:** in the editor, *Debug > Customize Run Instances...*, enable
multiple instances and set 2 (later 3). F5 then opens that many windows.
Host in one, join `127.0.0.1` in the others.

---

## M3.1 Net autoload, main menu, lobby

### Files

| File | Action |
| --- | --- |
| `autoload/net.gd` | new; register as `Net` after `GameState` |
| `scripts/ui/main_menu.gd`, `scenes/ui/main_menu.tscn` | new; becomes `run/main_scene` |
| `scripts/match/match.gd` | edit: wait for all peers |

```gdscript
# FILE: autoload/net.gd
extends Node
## Hosting, joining and the list of players, available as `Net`.

## Emitted on every peer when the player list changes.
signal players_changed
## Emitted on a client when joining fails.
signal join_failed
## Emitted on a client when the host goes away.
signal host_left
## Emitted on the host when every peer has loaded the match scene.
signal all_peers_loaded
## Emitted on the host when a client drops during a match.
signal peer_left(peer_id: int)

const MATCH_SCENE := "res://scenes/match.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

## Peer id -> {"name": String, "role": StringName}. Same on every peer.
var players: Dictionary = {}
## The name this player typed in the menu.
var local_name: String = "Crew"
## Slot id -> room type id for the match being loaded.
var match_assignment: Dictionary = {}

var _loaded_peers: Array[int] = []


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Starts a solo game: a host nobody can join.
func play_offline() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_set_players({1: _make_info(local_name)})


func host_game(port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, Config.tuning.max_players - 1)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	_set_players({1: _make_info(local_name)})
	return OK


func join_game(address: String, port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


## Drops the connection and goes back to the menu.
func leave() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	get_tree().change_scene_to_file(MENU_SCENE)


## Host only: sends everyone into the match.
func host_start_match(assignment: Dictionary) -> void:
	_loaded_peers.clear()
	_rpc_load_match.rpc(assignment)


## Every peer calls this when its match scene is ready.
func report_loaded() -> void:
	if multiplayer.is_server():
		_host_peer_loaded(multiplayer.get_unique_id())
	else:
		_rpc_loaded.rpc_id(1)


func get_player_name(peer_id: int) -> String:
	return players.get(peer_id, {}).get("name", "Unknown")


func _make_info(player_name: String) -> Dictionary:
	return {"name": player_name.left(Config.tuning.max_name_length), "role": &""}


func _set_players(list: Dictionary) -> void:
	players = list
	players_changed.emit()


func _on_connected_to_server() -> void:
	_rpc_register.rpc_id(1, local_name)


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	join_failed.emit()


func _on_server_disconnected() -> void:
	host_left.emit()
	leave()


func _on_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if GameState.phase == GameState.Phase.LOBBY:
		players.erase(peer_id)
		_rpc_set_players.rpc(players)
	else:
		peer_left.emit(peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var is_full := players.size() >= Config.tuning.max_players
	if is_full or GameState.phase != GameState.Phase.LOBBY:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	players[peer_id] = _make_info(player_name)
	_rpc_set_players.rpc(players)


@rpc("authority", "call_local", "reliable")
func _rpc_set_players(list: Dictionary) -> void:
	_set_players(list)


@rpc("authority", "call_local", "reliable")
func _rpc_load_match(assignment: Dictionary) -> void:
	match_assignment = assignment
	get_tree().change_scene_to_file(MATCH_SCENE)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_loaded() -> void:
	if multiplayer.is_server():
		_host_peer_loaded(multiplayer.get_remote_sender_id())


func _host_peer_loaded(peer_id: int) -> void:
	if peer_id not in _loaded_peers:
		_loaded_peers.append(peer_id)
	if _loaded_peers.size() >= players.size():
		all_peers_loaded.emit()
```

**Main menu** (`main_menu.tscn`, a `Control` scene): name field, address
field (default `127.0.0.1`), buttons *Play solo*, *Host*, *Join*, a
player list fed by `Net.players_changed`, and a *Start* button only the
host sees. *Play solo* = `Net.play_offline()` then
`Net.host_start_match(assignment)`. Show `Net.join_failed` as a line of
text. The mouse must be visible in the menu
(`Input.mouse_mode = Input.MOUSE_MODE_VISIBLE` in `_ready`).

**`match.gd` start-up, on every peer:** `GameState.reset()`, build the
ship from `Net.match_assignment`, bake navigation, then
`Net.report_loaded()`. **On the host only**, wait for
`Net.all_peers_loaded`, then spawn players (M3.2), set up the loot deck
and call `_rpc_start_match.rpc()` (`call_local`), which calls
`GameState.start_match()` everywhere.

### Tuning (`@export_group("Network")`)

`default_port` 24565, `max_name_length` 20.

### What was built (and where it differs from the plan above)

- `autoload/net.gd`, `scripts/ui/main_menu.gd` (the menu and lobby are built in
  code; `scenes/ui/main_menu.tscn` is just the root), `scripts/match/room_assignment.gd`
  (the host makes the room assignment and sends it to everyone) and
  `scripts/ui/overview_camera.gd` (a shared top-down camera, also used by F4).
- The menu is now the project's main scene. To run `match.tscn` directly,
  open it and press F6: it is a solo match.
- `Net.host_start_match` loads the match locally and sends an RPC to the others
  (no `call_local`), so solo play never depends on RPCs.
- `match.gd` waits for `Net.all_peers_loaded` on the host, then adds the host's
  player, the rules and the clock. Other players see the ship from above with a
  note until M3.2 adds their characters.
- On the end screen, R goes back to the menu in a network game and restarts the
  match in solo play.

### Owner checks

- Two windows: host in one, join in the other; both lists show both names.
- A third window joining after the match started is refused.
- *Start* loads the ship in both windows. (Players do not appear yet.)
- *Play solo* still works exactly as before.

---

## M3.2 Player spawning and movement sync

*Concepts:* `MultiplayerSpawner` (creates the same node on every peer),
`MultiplayerSynchronizer` (copies chosen properties from one peer to the
rest), multiplayer authority (which peer is allowed to send).

### Design

- `match.tscn` gets a `MultiplayerSpawner` named `PlayerSpawner` with
  `spawn_path = ../Players`. `match.gd` sets its `spawn_function` in
  `_ready` on every peer; the host calls `spawn(data)` once per player.
- The player root stays under the host's authority (so host-to-owner RPCs
  use `"authority"`). Two children are handed to the owning peer:
  `PlayerInput` and a new `MovementSync` synchronizer.
- A character only simulates movement on its owner's machine. Everyone
  else just receives the transform.

```gdscript
# In match.gd


func _spawn_player(data: Dictionary) -> Node:
	var player: PlayerCharacter = PLAYER_SCENE.instantiate()
	player.name = "Player%d" % data.peer_id
	player.peer_id = data.peer_id
	player.position = data.position
	return player


func _host_spawn_players() -> void:
	var index := 0
	for peer_id: int in Net.players:
		var spawn := {"peer_id": peer_id, "position": _spawn_points[index]}
		_player_spawner.spawn(spawn)
		index += 1
```

```gdscript
# In player_character.gd

## The network peer that controls this character. Set before it is added.
var peer_id: int = 1


func _enter_tree() -> void:
	# The owner sends this character's input and movement; the host owns
	# everything else about it.
	$PlayerInput.set_multiplayer_authority(peer_id)
	$MovementSync.set_multiplayer_authority(peer_id)


## True on the machine of the player who controls this character.
func is_local() -> bool:
	return peer_id == multiplayer.get_unique_id()
```

`MovementSync` in `player.tscn`:

```text
[sub_resource type="SceneReplicationConfig" id="Repl_player"]
properties/0/path = NodePath(".:position")
properties/0/spawn = true
properties/0/replication_mode = 1
properties/1/path = NodePath(".:rotation")
properties/1/spawn = true
properties/1/replication_mode = 1
properties/2/path = NodePath("Head:rotation")
properties/2/spawn = true
properties/2/replication_mode = 1
properties/3/path = NodePath(".:is_crouching")
properties/3/spawn = true
properties/3/replication_mode = 2
properties/4/path = NodePath(".:is_sprinting")
properties/4/spawn = true
properties/4/replication_mode = 2

[node name="MovementSync" type="MultiplayerSynchronizer" parent="."]
replication_config = SubResource("Repl_player")
```

(`replication_mode` 1 = always, 2 = only when changed.)

### Edits to `player_character.gd`

- `_ready`: if `is_local()`, make the camera current and hide the body
  mesh; otherwise `camera.current = false`, `input_source.enabled =
  false`, `input_source.set_process_unhandled_input(false)`, and show a
  capsule `Body` mesh (add it to `player.tscn`).
- `_process` (look) and the movement part of `_physics_process` run only
  when `is_local()`.
- Split `_physics_process` into `_local_step` (input, movement,
  interaction, item use) and `_host_step` (sprint noise from the synced
  `is_sprinting`, wound timers). The host runs `_host_step` for every
  player; on the host's own character both run.
- Non-local characters set the capsule height from the synced
  `is_crouching` so hit shapes match.
- `GameState.get_player_by_peer(peer_id) -> PlayerCharacter`: add it.

### What was built (and where it differs from the plan above)

- `PlayerSpawner` is in `match.tscn`; `match.gd` sets `spawn_function` on every
  machine, and the host spawns one character per player at the Cryo Bay spawn
  points. Solo play adds the character directly and never uses the spawner.
- `PlayerCharacter` has `peer_id`, `is_local()`, and splits its physics into
  `_local_step` (input and movement on the owner's machine) and `_remote_step`
  (body size only). The host makes sprint noise for every character from the
  synced `is_sprinting`.
- Only `MovementSync` is handed to the owning peer. `PlayerInput` stays under
  the host and is simply switched off on characters you do not control.
- Until M3.3, only the host's own character can pick up, search or use items.
- Until M3.4 (doors are not synced), a client's character walks through doors
  (it drops the door bit of its collision mask).
- `GameState.get_player_by_peer()` is added. A death ends the match only when
  nobody is left alive (M3.5 does the real flow).

### Owner checks

- Each window shows the other player as a capsule moving smoothly,
  turning and crouching.
- Each window controls only its own character.
- Sprinting in the client window raises zone noise on the host's debug
  overlay (noise is host-only, so the client's overlay shows 0).

---

## M3.3 Player actions over RPC, private state to the owner

Convert every `request_*` from Phase 2 using the pattern in README 4.3.
Requests that live on the player node check that the sender is that
player's owner.

```gdscript
# In player_character.gd: the shape every player request takes.


func request_drop(hand: int) -> void:
	if multiplayer.is_server():
		_host_drop(hand)
	else:
		_rpc_drop.rpc_id(1, hand)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_drop(hand: int) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == peer_id:
		_host_drop(hand)


func _host_drop(hand: int) -> void:
	if is_dead or hand < 0 or hand > Inventory.OFF_HAND:
		return
	# Take the stack from the inventory and spawn a pickup (see M3.4).
	pass
```

Requests on world objects find the player from the sender:

```gdscript
# In interactable.gd: replaces the Phase 2 request_interact.


func request_interact(player: PlayerCharacter) -> void:
	if multiplayer.is_server():
		_host_interact(player)
	else:
		_rpc_interact.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_interact() -> void:
	if not multiplayer.is_server():
		return
	var player := GameState.get_player_by_peer(multiplayer.get_remote_sender_id())
	if player:
		_host_interact(player)
```

### Conversion table

| Request (client to host) | Host checks | Result goes to |
| --- | --- | --- |
| `request_fire(hand, origin, direction)` | Alive; hand holds a hitscan item with rounds; cooldown passed; `origin` within `fire_origin_tolerance` of the head | Ray and damage on the host; `_rpc_shot_effects.rpc()` to everyone (flash, sound); new inventory to the owner |
| `request_use_on_self(hand)` | Alive; item is a medkit or bandage | Wounds and inventory to the owner |
| `request_reload(hand)` | Has an ammo box; gun not full | Inventory to the owner |
| `request_swap_hand_slot(hand, slot)`, `request_swap_hands()` | Indexes in range | Inventory to the owner |
| `request_drop(hand)` | Hand not empty | Pickup spawned for everyone; inventory to the owner |
| `Interactable.request_interact()` | Alive; in reach; `can_interact` | Depends on the object (M3.4) |
| `Interactable.request_use_item(hand)` | Same, plus the item prompt is not empty | Depends on the object |

The client still runs the hold timers and the spread roll; the host
trusts the hold time (good enough for a friends game; note it in
`docs/later.md` as a possible hardening).

### Private state

Wounds and inventory change only on the host. After every change the host
sends the owner a full copy; other clients get nothing (GDD: nobody else
sees your wounds or items).

```gdscript
# In player_character.gd


## Host only: call after this player's wounds or inventory changed.
func _host_send_private_state() -> void:
	if is_local():
		return
	_rpc_private_state.rpc_id(peer_id, wounds.to_dict(), inventory.to_dict())


@rpc("authority", "call_remote", "reliable")
func _rpc_private_state(wound_state: Dictionary, inventory_state: Dictionary) -> void:
	wounds.apply_dict(wound_state)
	inventory.apply_dict(inventory_state)
```

- Add `to_dict()` / `apply_dict()` to `PlayerWounds` (light count, effect
  and dressed arrays, `is_dead`) and `Inventory` (hands and slots as
  `ItemStack.to_dict()` or `null`, `usable_hands`). `apply_dict` ends
  with `changed.emit()` so the HUD refreshes.
- Connect `wounds.changed` and `inventory.changed` to
  `_host_send_private_state` on the host only. On clients those signals
  only refresh the HUD.
- `show_message(text)` becomes `_rpc_message.rpc_id(peer_id, text)`.
- Death is public: the host calls `_rpc_died.rpc()` (`call_local`), which
  runs `_on_wounds_died` on every peer.

### Tuning

`fire_origin_tolerance` 1.5 (metres between the reported shot origin and
the host's idea of the player's head).

### What was built (and where it differs from the plan above)

- The requests live on `ItemUser` (not `PlayerCharacter`): `request_drop`,
  `request_use_on_self`, `request_reload`, `request_swap_hand_slot`,
  `request_swap_hands`, `request_fire`. On the host they run at once; on a
  client they become an RPC that the host accepts only from the character's
  owner.
- `HitscanWeapon.update_trigger` now only decides *whether* a shot happens and
  returns its pellet directions (the client rolls the spread). `apply_shot`
  does the ray casts, ammo and noise on the host. `_host_fire` checks the fire
  rate, the origin (`fire_origin_tolerance`) and the pellet count.
- Shot effects: the host's own gun plays its own flash and sound; for every
  other shot `ShotEffects` plays a flash and sound at the shooter's head on
  all machines. The hit marker goes to the shooter with an RPC.
- Private state: `to_dict` / `apply_dict` on `Inventory` and `PlayerWounds`. A
  client asks for its first copy when its character appears; after that the
  host sends a new copy on every change, to the owner only. Messages and
  deaths follow the plan (`_rpc_message`, `_rpc_died`).
- `ItemUser` keeps a hand's view when the item kind is unchanged, so a gun's
  trigger state survives the inventory copy arriving.
- Clients now get the HUD and debug overlay. The debug wound and door keys
  (F5 to F8) work on the host only.
- **Not yet shared (M3.4):** interacting with doors, crates and stations
  (still host only), dropped items and pickups, aliens, the clock.

### Owner checks

- The client can shoot the dummy and Crawlers; kills happen in both
  windows; both hear and see the shot.
- The client's HUD shows its own ammo, wounds and items correctly; the
  host's HUD is unaffected by the client's.
- The client can use a medkit, reload, stow, swap and drop.
- Shots pass through the other player without effect.

---

## M3.4 Aliens, doors, pickups and stations synced

### Names first

Give every generated node that uses RPCs a fixed name before `add_child`:

| Node | Name |
| --- | --- |
| Room furnishing | `Room_<slot id>` |
| Door | `Door_<slot id>` |
| Search spot | `Search_<slot id or seg index>_<n>` |
| Vent (M4.1) | `Vent_<slot id or seg index>` |

Nodes inside furnishing scenes already have fixed names. Pickups and
aliens are created by spawners, which keep names in step by themselves.

### Aliens

- `match.tscn`: `AlienSpawner` (`MultiplayerSpawner`, `spawn_path =
  ../Aliens`) with a spawn function taking `{"alien_id", "position"}`.
  `match.spawn_alien(alien_id, position)` (host) calls
  `_alien_spawner.spawn(...)` and returns the node.
- Each alien scene gets a `MultiplayerSynchronizer` syncing `.:position`
  and `.:rotation` (mode 1), authority left on the host.
- `alien.gd` `_ready`: `set_physics_process(multiplayer.is_server())`. AI,
  senses and damage run on the host only. Freeing the alien on the host
  removes it everywhere.
- `HealthComponent.take_damage` is only ever called on the host.

### Doors, search spots, stations

Host changes state, then broadcasts the whole public state:

```gdscript
# In door.gd


## Host only: call after any change to open / welded / locked.
func _host_broadcast() -> void:
	_rpc_state.rpc(is_open, is_welded, lock_seconds)


@rpc("authority", "call_remote", "reliable")
func _rpc_state(open: bool, welded: bool, seconds: float) -> void:
	is_welded = welded
	lock_seconds = seconds
	set_open(open)
	state_changed.emit()
```

Clients count `lock_seconds` down locally for the prompt text. Do the
same for: `SearchSpot.enabled`, the ammo locker's refills, the gun rack,
the pod socket (pods unlocked is public once it happens), pod seats and
launch countdowns.

### Pickups

`ItemSpawner` (`spawn_path = ../Items`) with a spawn function taking
`{"stack": ItemStack.to_dict(), "position"}`. Taking a pickup frees it on
the host.

### Owner checks

- A Crawler is in the same place in both windows and attacks whichever
  player it sees.
- A door opened, welded or locked by one player changes for both.
- A crate searched by one player is empty for the other; the found item
  goes only to the finder.
- A dropped item appears for both and only one of them can take it.
- The ammo locker's three refills are shared.

---

## M3.5 Match flow, death and spectating, disconnects

- **Clock:** the host sends `_rpc_clock.rpc(clock)` (unreliable) once a
  second; clients add `delta` in between.
- **End of match:** `GameState.end_match` on the host broadcasts
  `_rpc_match_ended.rpc(reason, results)`; `results` is an array of
  `{name, fate}` for the end screen (M5.5 adds objectives).
- **Phase 2's "you escaped ends the match" rule goes away.** A launched
  pod marks its occupants `ESCAPED` (they spectate). The match ends when
  nobody is awake aboard (GDD "nobody left awake") or at the jump. Add to
  `PlayerCharacter`: `enum Fate { AWAKE, DEAD, SLEEPING, ESCAPED }`,
  `var fate`, and make `is_awake()` return `fate == Fate.AWAKE`. Fate
  changes are public RPCs.
- **Spectating:** when the local player is no longer awake, switch the
  view to another awake player's camera; left mouse cycles. When nobody
  is left, show a free view of the Cryo Bay until the end screen.
- **Disconnects** (GDD "Disconnecting"): on `Net.peer_left`, the
  character stays where it is and can still be hurt. The host starts a
  `disconnect_grace_seconds` timer; when it runs out the character dies
  and becomes a searchable body (bodies are M5.6; until then it just
  dies). Sleepers and escapees are unaffected.
- **Reconnecting** within the 5 minutes is in the GDD but needs a full
  state snapshot for a peer that joins mid-match (ship, doors, pickups,
  its own private state). Build it as the last step of this milestone
  only if the rest is solid; otherwise write it into `docs/later.md` and
  tell the owner it is deferred.
- **Host leaves:** everyone returns to the menu with a message.

### Tuning

`disconnect_grace_seconds` 300.0, `clock_sync_interval` 1.0.

### Owner checks

- Both clocks stay within a second of each other for 10 minutes.
- One player dies: they spectate the other; the match goes on.
- One player launches a pod: they spectate; the match ends when the other
  dies, escapes or the jump comes; both see the same end screen.
- Closing the client window mid-match leaves its character standing; a
  Crawler can still attack it.

### Gate 3

2 to 4 people play a full match on a LAN (or with port forwarding of UDP
24565). No desync: doors, aliens and pickups agree in every window. Fix
desync before adding anything; the development plan's fallback is to
drop to 2-4 players and co-op only.
