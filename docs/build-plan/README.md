# Cryo Breach: build plan

Written 10 Nov 2026. This is the step-by-step plan for building the whole game
described in `docs/game-design-document.md` (the GDD). It is written so that a
Claude Sonnet session can build one milestone at a time without needing any
other context than this folder, `CLAUDE.md` and the GDD.

| File | Covers |
| --- | --- |
| `README.md` (this file) | How to work, decisions, architecture, milestone index |
| `phase-1-first-fight.md` | Pistol, health, wounds, HUD, navigation, first Crawler |
| `phase-2-solo-slice.md` | Match clock, generated ship, interaction, inventory, doors, loot, escape ending |
| `phase-3-networking.md` | Host and join, synced players and aliens, RPC conversion |
| `phase-4-tension.md` | Alien pool, noise director, all alien types, hazards, ship systems, crafting |
| `phase-5-objectives.md` | Roles, infection, cryosleep, self-destruct, objectives, resolution, bots |
| `phase-6-polish.md` | Menus, settings, art and sound pass, export |

## 1. How to work through this plan (read this first, every session)

1. **One milestone per session.** Milestones are numbered `M1.1`, `M1.2`, ...
   Do them in order. Each one is sized to be tested by the owner in one
   sitting. Do not start the next one in the same session unless the owner
   asks.
2. **Before writing code** read: `CLAUDE.md`, section 3 and 4 of this file,
   the milestone's own section, and the GDD sections the milestone names.
   The GDD wins over this plan if they disagree; stop and ask the owner
   before changing a rule.
3. **Code blocks in this plan are a starting point, not gospel.** Blocks
   marked `# FILE:` are complete files that passed `gdparse` and `gdlint`,
   but **none of this plan's code has been run in Godot** (there is no Godot
   binary on the machine it was written on). If something does not work in
   the engine, fix the code and keep the behaviour the milestone describes.
4. **Every number goes in data.** For each new number: add an `@export`
   with a `##` doc comment to `scripts/data/tuning.gd`, add the same value
   to `data/tuning.tres`, and read it through `Config.tuning`. Each
   milestone lists its new tuning values.
5. **Check your work** before saying a milestone is done:

   ```bash
   python -m gdtoolkit.parser $(git ls-files -co --exclude-standard '*.gd')
   ```

   ```bash
   python -m gdtoolkit.linter $(git ls-files -co --exclude-standard '*.gd')
   ```

   If `godot` is on the PATH, also run these two (the first refreshes the
   `class_name` cache, which is required after adding a new `class_name`
   script; without it the second command reports "Could not find type"):

   ```bash
   godot --headless --path . --import
   ```

   ```bash
   godot --headless --path . --quit-after 120
   ```

6. **Finish each milestone with:** the milestone's box ticked in section 5
   of this file; the "Where we are" section of `CLAUDE.md` updated; the
   README controls table updated if keys changed; and a short "things to
   try in Godot" list for the owner copied from the milestone's *Owner
   checks*. Say plainly that the code has not been run in Godot if it has
   not. Commit only when the owner asks.
7. **The owner is a beginner.** When a milestone introduces a Godot concept
   (listed under *Concepts*), explain it in two or three sentences in your
   final message.
8. **Never use Nemesis names, art or characters.** Add every outside asset
   to `assets/CREDITS.md` the day it is added. This plan needs no outside
   assets until Phase 6; placeholder sounds are generated in code.

**Prompt the owner can paste into a new Sonnet session:**

> Read `CLAUDE.md` and `docs/build-plan/README.md`. Then build the first
> unticked milestone in the milestone index, following its section in the
> phase file exactly. Run the checks, tick the milestone, and finish with
> the list of things I should try in Godot.

## 2. Where the project is today

- Phase 1, Week 1 is written but **has never been run in Godot**: player
  controller, grey-box Cryo Bay, zone noise, debug HUD.
- Milestone `M1.0` below is the owner running the first-run checklist in
  the project README. Nothing else should be built on top until that
  passes, because every later milestone depends on the controller working.
- Godot is not installed on the owner's machine yet (checked 10 Nov 2026).
  Installing Godot 4.7 and adding it to the PATH as `godot` lets Claude run
  the headless checks itself.

## 3. Decisions this plan makes

The GDD fixes the rules. These are the engineering calls and the few rule
interpretations the GDD leaves open. The ones marked **ask** should be
confirmed with the owner when their milestone comes up; until then build
the default.

| # | Decision | Default in this plan | Status |
| --- | --- | --- | --- |
| D1 | Ship layout (the GDD diagram is not in the exported docs) | Spine corridor along X, fore at -X. Bridge caps the fore end, Pod Bay the aft end. Each of the 5 segments has one room on each side: seg 1 = slots 1, 2; seg 2 = Cryo Bay, slot 3; seg 3 = slots 4, 5; seg 4 = slots 6, 7; seg 5 = Engine A, Engine B. This matches the existing Cryo Bay scene (segment 2, opposite slot 3) and the GDD power sections. | **ask** (compare with the online diagram) |
| D2 | How rooms are built | Generated in code from data (`ShipLayout` + `RoomType` resources) as box walls with `StaticBody3D` colliders, not hand-made CSG scenes. Room shuffling needs this anyway and it is far more reliable to write without the editor. Each room type has a small furnishing scene for its stations. The hand-made `cryo_bay.tscn` is used only in Phase 1. | decided |
| D3 | Who moves a player in multiplayer | The owning client moves its own character and syncs the transform; the host owns every rule (wounds, items, doors, aliens, noise, secrets). No client-side prediction to write, no input lag. The cost is that a cheating client could teleport, which is acceptable for a friends game. | **ask** at M3.2 |
| D4 | The 8 rooms of the Phase 2 slice | Bridge, Cryo Bay, Engines A, B and C, Pod Bay, Medbay, Armory, Generator (changed by D20 and D21: the slice opens slots 1, 5 and 7 so the rooms join up). The other 4 slots are generated but sealed. | decided |
| D5 | Hand controls (GDD says only "2 hands + 4 slots") | Left mouse uses the main hand, right mouse uses the off hand, `1`-`4` swap a slot with the main hand (0.75 s), `X` swaps hands, `G` drops the main hand item, `E` interacts. | **ask** at M2.4 |
| D6 | Blank pull vs "meter drops to 3" | On a Blank the meter is halved (not set to 3); zone and ship cooldowns still start. | **ask** at M4.1 |
| D7 | Encounter at the active cap | Counts as an encounter: meter drops to 3 and cooldowns start, nearest active alien is sent to that zone. | decided |
| D8 | Quarantine objective when the ship is destroyed | Literal reading: met only if the course is not Earth at the end. A destroyed ship with course Earth does not count. | **ask** at M5.5 |
| D9 | "Sleep together" | The other sleeper must also survive. | decided |
| D10 | Voice chat (proximity, radio, broadcast) | After 1.0, as the development plan's cut line says. Until then the radio and Comms room exist as items and rooms, and voice noise is not simulated. | decided |
| D11 | Phase 1 HUD "health bar" in the development plan | A wound display instead; the GDD has no HP for players. `HealthComponent` is for aliens only. | decided (CLAUDE.md) |
| D12 | Match clock visibility | Every player sees the clock on the HUD. | decided |
| D13 | Players below 3 (solo testing) | Tables indexed by player count clamp to the 3-player column. | decided |
| D14 | Can a two-handed item go in a slot? | No. It must be carried in both hands or dropped. | **ask** at M2.4 |
| D15 | How an ammo box is used | Hold R for 2 s with the gun in a hand; the box can be anywhere in the inventory (a two-handed rifle leaves no hand free for it). | **ask** at M2.4 |
| D16 | How the blind Adult finds players | It hears sprinting within its 20 m hearing range and walking within 6 m; crouch-walking and standing still are silent to it. | **ask** at M4.2 |
| D17 | Which rooms a fire can spread to | Rooms joined by a corridor to the burning room, when that corridor's door is open (changed for the room network, D20). | **ask** at M4.3 |
| D18 | Room types are secret until visited | The map UI hides them, but every client receives the room assignment at match start so all peers build the same ship. A modified client could read it. | known gap, revisit in M6.4 |
| D20 | Room shape and map | The owner wants **hexagonal rooms with 1 to 3 doors each, joined by short corridors, like the board game's map** (not one long corridor). Built in **M2.8** (reworked 14 Nov 2026): 12 rooms (side 6 m) on a hexagonal lattice, 15 corridors of 4 m, each corridor its own noise place with one door in the middle. The arrangement is original, not a copy of the board; the design doc and art brief were updated. The vents, fires and noise rules treat corridors as before. | decided |
| D21 | Three engines, 13 rooms, special room shapes | The owner chose **three engines** (design doc change: all three must work, at least one starts damaged) and **12 to 14 rooms**, so the ship had 13 (superseded by D22: 21 rooms). The layout is the same every match. The Bridge (a cockpit narrowing to a nose), Cryo Bay (the biggest room) and engines (long) have their own shapes; the shuffled rooms are regular hexagons. A shape is six distances (`ShipLayout.SHAPES`), so every side still faces a corridor direction. The arrangement is original, not a trace of the board. | decided |
| D22 | Layout copied from the owner's diagram | The owner sent a ship diagram (cockpit, hibernatorium, 3 engines, 16 hexagons, winding corridors) and asked for the layout to match it. Built in M2.8 (third version, 15 Nov 2026): **21 rooms, 28 corridors**, room positions measured from the diagram, bent corridors, per-room polygon shapes (Bridge = cockpit blob, Cryo Bay = tall oval, engines = D shapes). Our names and look stay ours (Bridge, Cryo Bay); only the arrangement follows the diagram. The Pod Bay is the hexagon beside Engine C. **15 shuffled slots** are filled with all 10 room types plus 5 Crew Quarters (design doc changed: no more 'two of five optional rooms'). Rooms have 2 to 5 doors. | decided |
| D19 | Reconnecting within 5 minutes | The 5-minute death timer is built in M3.5; rejoining mid-match is attempted last and may be deferred. | known gap, revisit in M6.4 |

## 4. Target architecture

### 4.1 Folder map (final state)

```text
autoload/
  config.gd            Config: tuning (exists)
  game_state.gd        GameState: match clock, zone and player registries (M2.1)
  net.gd               Net: hosting, joining, player list (M3.1)
data/
  tuning.tres          every number
  weapons/*.tres       WeaponData
  aliens/*.tres        AlienData
  items/*.tres         ItemData
  rooms/*.tres         RoomType
  recipes/*.tres       RecipeData
  objectives/*.tres    ObjectiveData
  roles/*.tres         RoleData
  ship_layout.tres     ShipLayout
scenes/
  main.tscn            Phase 1 test scene; becomes the boot scene in M3.1
  match.tscn           the actual game world (M2.1)
  player/ aliens/ items/ world/ rooms/furnish/ ui/
scripts/
  core/        input_setup, layers, placeholder_sounds, host helpers
  data/        Resource classes (Tuning, WeaponData, AlienData, ItemData, ...)
  components/  HealthComponent
  player/      PlayerCharacter, InputSource, PlayerInput, BotInput,
               PlayerWounds, Inventory, PlayerInteractor
  weapons/     HitscanWeapon, MeleeWeapon, Thrown
  aliens/      Alien and behaviours, AlienPool, NoiseDirector
  world/       Zone, ShipBuilder, Door, Vent, Interactable, stations/
  match/       ShipState, LootDeck, ContaminationDeck, EventDirector,
               ObjectiveRules, MatchResolver
  ui/          HUD, debug HUD, lobby, end screen, map
```

### 4.2 Physics layers

| Layer | Name | Bit value | Who is on it |
| --- | --- | --- | --- |
| 1 | world | 1 | Walls, floors, props |
| 2 | players | 2 | Player bodies |
| 3 | aliens | 4 | Alien bodies, target dummy |
| 4 | zones | 8 | (zones use layer 0, mask 6) |
| 5 | interactables | 16 | `Interactable` areas (M2.3) |
| 6 | doors | 32 | Door slabs (M2.5); kept off layer 1 so they do not cut the navigation mesh |

Use the constants in `scripts/core/layers.gd` (M1.1), never raw numbers.
Bullets use the mask `WORLD | ALIENS | DOORS`, which leaves players out:
that is how the "bullets never hurt players" rule is enforced.

### 4.3 The host-authority pattern (use it from Phase 2 on)

Single-player runs as a host with one local player. With no network peer
set, Godot's default offline peer makes `multiplayer.is_server()` return
`true` and `multiplayer.get_unique_id()` return `1`, so the same code path
works offline and online.

Every action that changes game rules is split in three:

1. `request_*`: called on the acting player's machine.
2. `_host_*`: runs only on the host, validates, changes state.
3. A sync step: public state through a `MultiplayerSynchronizer` or a
   broadcast RPC; private state through `rpc_id(owner_peer, ...)`.

```gdscript
# Pattern only. Lives on a node that exists on every peer (for example Door).


func request_toggle() -> void:
	if multiplayer.is_server():
		_host_toggle(multiplayer.get_unique_id())
	else:
		_rpc_toggle.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_toggle() -> void:
	if multiplayer.is_server():
		_host_toggle(multiplayer.get_remote_sender_id())


func _host_toggle(_peer_id: int) -> void:
	# Validate here: is the player alive, close enough, holding the item?
	pass
```

In Phase 2 write only `request_*` (calling `_host_*` directly) and
`_host_*`. Phase 3 adds the `@rpc` middle functions. Never put a secret
(alien pool, loot deck, contamination cards, objectives, engine states,
course, integrity, noise meters) in a synced property.

### 4.4 Data resources

| Class (`scripts/data/`) | One `.tres` per | Added in |
| --- | --- | --- |
| `Tuning` | the whole game | exists |
| `WeaponData` | weapon | M1.1 |
| `AlienData` | alien type | M1.3 |
| `ShipLayout`, `RoomType` | ship, room type | M2.2 |
| `ItemData` | item | M2.4 |
| `RecipeData` | crafting recipe | M4.6 |
| `RoleData` | role | M5.1 |
| `ObjectiveData` | objective | M5.5 |

Hand-written `.tres` files follow the shape of `data/tuning.tres`:
a `[gd_resource type="Resource" script_class="ClassName" load_steps=N
format=3]` header (`N` = number of `ext_resource` + `sub_resource` entries
plus 1), the script as an `ext_resource`, then `[resource]` with one
`name = value` line per exported property.

### 4.5 Input actions

Added in code by `scripts/core/input_setup.gd`. Final list:

| Action | Key | Added in |
| --- | --- | --- |
| move_*, sprint, crouch, jump, interact, toggle_lamp, toggle_debug, pause, fire, aim | (exist) | Week 1 |
| restart | R | M1.2 |
| slot_1 ... slot_4 | 1-4 | M2.4 |
| swap_hands | X | M2.4 |
| drop | G | M2.4 |
| use_off_hand | right mouse (replaces `aim`) | M2.4 |
| toggle_map | M or Tab | M4.5 |
| objectives | O | M5.5 |

### 4.6 Gotchas when writing Godot files by hand

- **`.tscn` files:** copy the style of the existing scenes. Node order
  matters: a parent must appear before its children. `parent="."` means a
  child of the root; the root has no `parent`. A child of an instanced
  scene's inner node cannot be added without `editable_children`, so put
  new nodes in the scene that owns them.
- **`class_name` cache:** Godot only learns a new `class_name` when the
  editor (or `godot --headless --import`) scans the project.
- **`@onready` and `_ready` order:** children are ready before their
  parent. A parent may set a child's values in its own `_ready`.
- **Physics queries** (`intersect_ray`, `test_move`) are only safe inside
  `_physics_process`.
- **`await` in a node that may be freed** is fine: the coroutine is
  dropped with the node.
- **gdlint** enforces 100-character lines, definition order (signals,
  enums, constants, exports, public vars, private vars, `@onready`), and
  an underscore prefix on unused arguments.
- **Navigation:** a `NavigationAgent3D` gives nonsense until the
  navigation map has synced once. Always guard with `_navigation_ready()`
  as in `alien.gd` (M1.3).

## 5. Milestone index

Tick a box when the milestone's checks pass **and** the owner has confirmed
its *Owner checks* in Godot.

**Phase 1: first fight** (`phase-1-first-fight.md`)

- [x] M1.0 Owner runs the Week 1 first-run checklist; fix what fails
- [x] M1.1 Layers, HealthComponent, target dummy, hitscan pistol
- [x] M1.2 Wound system, HUD, death and restart
- [x] M1.3 Navigation mesh and the first Crawler
- [ ] Gate 1: a stranger can move, shoot and die to the Crawler in under 2 minutes

**Phase 2: solo vertical slice** (`phase-2-solo-slice.md`)

- [x] M2.1 GameState, match scene, match clock
- [x] M2.2 Ship generated from data (12 slots, 8 open rooms, zones, navigation)
- [x] M2.3 Interaction system (look, prompt, hold to use)
- [x] M2.4 Items and inventory (2 hands + 4 slots), pickups, HUD
- [x] M2.5 Doors (open, closed, locked, welded), keycard, welder
- [x] M2.6 Loot deck, search containers, room stations for the slice
- [ ] M2.7 Escape pods, power cell, hyperspace jump, end screen
- [x] M2.8 Room network laid out like the owner's diagram: 21 rooms, 28 corridors (decisions D20, D21, D22)
- [ ] Gate 2: a friend plays 15 minutes solo and can say what they were meant to do

**Phase 3: co-op networking** (`phase-3-networking.md`)

- [ ] M3.1 Net autoload, main menu, lobby, host and join
- [ ] M3.2 Player spawning and movement sync
- [ ] M3.3 Player actions over RPC, private state to the owner
- [ ] M3.4 Aliens, doors, pickups and stations synced
- [ ] M3.5 Match flow over the network, death and spectating, disconnects
- [ ] Gate 3: 2-4 players finish a match on a LAN without desync

**Phase 4: tension systems** (`phase-4-tension.md`)

- [ ] M4.1 Alien pool, vents, noise director
- [ ] M4.2 Larva, Adult, Breeder, Queen
- [ ] M4.3 Fire, hull breach, malfunction, power outage, integrity, event director
- [ ] M4.4 Engines, navigation console, breakers, Security terminals
- [ ] M4.5 Remaining rooms, room shuffle, personal map
- [ ] M4.6 Remaining weapons and items, crafting, full loot deck
- [ ] M4.7 Lighting and sound mood pass
- [ ] Gate 4: quiet play is visibly safer than loud play

**Phase 5: secret objectives** (`phase-5-objectives.md`)

- [ ] M5.1 Roles, lobby role pick, starting gear
- [ ] M5.2 Contamination deck, scanners, surgery
- [ ] M5.3 Cryosleep and the full pod rules
- [ ] M5.4 Self-destruct
- [ ] M5.5 Objectives: deal, commit, track, resolve, end screen
- [ ] M5.6 Giving items, bodies, name badges, bots
- [ ] Gate 5: a 3-6 player match plays start to finish with secrets intact

**Phase 6: polish and release** (`phase-6-polish.md`)

- [ ] M6.1 Menus, settings, saved options
- [ ] M6.2 Art pass with a modular kit
- [ ] M6.3 Sound pass
- [ ] M6.4 Performance and export builds
