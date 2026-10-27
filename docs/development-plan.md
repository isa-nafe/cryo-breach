# Game Development Plan: Cryo Breach (working title)

Oct 27, 2026 · @Isa

A phased plan to build a 3-6 player, semi-co-op sci-fi horror FPS in Godot, sized for a solo beginner: ship a playable solo slice first, then add networking, then the hidden-objective layer.

## Vision

Three to six players wake from cryosleep on a dying cargo ship, find it overrun by aliens, and must decide whether to cooperate, abandon each other, or sabotage each other to reach their secret goals.

The game is *inspired by* Nemesis, not a copy of it. Names, characters, art and exact rules from the board game belong to Awaken Realms, so we use an original ship, original crew and original alien species. That also keeps the game safe to share or sell later.

**Design pillars**

1. **Paranoia over power.** Players are weak. Ammo, health and time are scarce, so every shot has a cost.
2. **Noise attracts death.** Loud actions (gunfire, running, forced doors) draw aliens; quiet play is rewarded.
3. **Everyone has a secret.** Each player holds a private objective. Some require the crew to survive, some require others to die.
4. **Short, tense sessions.** A full run takes 30-45 minutes, so it is testable with friends and finishable as a solo project.

**What we borrow vs. change**

| Nemesis board game idea | In our FPS |
| --- | --- |
| Wake from hibernation, ship under attack | Same opening: pod bay, flickering lights, a first alien encounter within 3 minutes |
| Noise tokens draw intruders to rooms | A noise meter per room; loud actions raise it, aliens path toward the loudest room |
| Secret corporate and personal objectives | Two secret objectives per player; commit to one at minute 10 |
| Escape pods and engines as the way out | Escape pods unlocked by a power cell, or cryosleep until the ship arrives |
| Turn-based card play | Real-time first-person movement, shooting and interaction |

## Scope reality check

A 3-6 player semi-co-op game with hidden objectives is the hardest version of this idea for a first project, because every feature (AI, doors, loot, objectives) must also work over a network. The plan below keeps your goal but changes the order: build and polish the game offline, then add networking, then add the secret-objective layer.

Assumption: you can spend about 8-10 hours a week. At that pace, expect roughly 12-18 months to reach a playable multiplayer version; a solo-playable slice should take 4-5 months. These are estimates, not promises, and beginners usually run over.

**Three rules that keep the project alive**

1. **One small map first.** Build 6-8 rooms, not a whole ship. More rooms later reuse the same systems.
2. **Server-authoritative from day one.** Even in solo play, the game runs as a host with one local player, so multiplayer is an addition, not a rewrite.
3. **Test with bots.** You cannot always find 4 friends. A simple crew-bot that follows and sometimes lies lets you test hidden objectives alone.

**Cut line**

| Tier | What is in | When |
| --- | --- | --- |
| Must | Move, shoot, 1 alien type, doors, 1 key item, 1 escape ending, 6-8 rooms | Phases 1-2 |
| Must | Host/join over LAN or direct IP, 2-4 players in one session | Phase 3 |
| Should | Noise system, 2 alien behaviours, secret objectives, 5-6 players | Phases 4-5 |
| Later | Online matchmaking, voice chat, more maps, character classes, cosmetics | After release 1.0 |

## Game design

The full rules now live in `docs/game-design-document.md`; when this plan and that document disagree, the design document wins.

In short:

- **Players and goals.** 3-6 players, each with a crew and a personal objective, committing to one at minute 10. There is no traitor; everyone plays their own mission.
- **No shooting each other.** Bullets and melee pass through players. Betrayal runs through doors, noise lures, ship systems, pods, grenades and fire.
- **The alien pool.** Noise triggers encounters, each pulling a random alien (Larva, Crawler, Adult, Breeder or Queen) or a Blank from a shared pool that only shrinks when aliens are killed.
- **Wounds, not HP.** Three light wounds make a serious one; three serious wounds kill. Death is permanent. Alien hits give hidden contamination cards that do nothing until checked; an infected card kills you only if you go into cryosleep with it.
- **The ship.** A fixed 12-room layout whose 7 shuffled rooms change type every match. Each player has their own map, plus four hazards: fire, malfunctions, outages and breaches.
- **Getting out.** Escape pods, unlocked with a power cell, or cryosleep, which only works if the engines are fixed, the course is Earth, the ship survives and the Cryo Bay is safe at the 40:00 jump.

The Phase 2 vertical slice builds 8 of the 12 rooms with fixed room types; shuffling and the remaining rooms arrive in Phases 4-5.

## Technical architecture

The game is built in **Godot 4** with **GDScript**: it is free, light enough for a low-poly FPS, and has multiplayer built in. Install the latest stable 4.x release (the 4.7 series at the time of writing). Since Godot 4.6, new 3D projects use the Jolt physics engine by default, which is more stable and faster than the older built-in one ([source](https://alternativeto.net/news/2026/1/godot-4-6-debuts-modern-theme-jolt-physics-node-ids-and-libgodot-embed)).

| Part | Choice | Why |
| --- | --- | --- |
| Engine and language | Godot 4.x, GDScript | Fast to learn, instant iteration, small downloads |
| Physics | Jolt (default in new 3D projects) | Good for character controllers and doors |
| Level building | `CSGBox3D` for grey-boxing, then `GridMap` with a modular kit | Rooms in hours, not days |
| Enemy movement | `NavigationRegion3D` and `NavigationAgent3D` | Built-in pathfinding around doors and corridors |
| Networking | `ENetMultiplayerPeer`, `MultiplayerSpawner`, `MultiplayerSynchronizer`, `@rpc` | Godot's built-in high-level API; no extra libraries |
| Version control | Git and a private GitHub repo | Backups and the ability to undo mistakes |
| Models and audio | Blender, Audacity | Free tools |

*[Diagram: network layout · 1 host, up to 5 clients, 3 message types. See the online version of this doc.]*

The host owns every game rule; clients send their input up and receive world state, plus their own private goal, back.

**Networking rules to follow from the first line of code**

1. **The host is the authority.** Clients ask ("I fire"); the host decides ("you hit"). Never let a client decide damage, loot or door state.
2. **Two message kinds.** Continuous state such as positions and rotations goes through `MultiplayerSynchronizer`; one-off events such as damage or picking up an item go through `@rpc` functions. This split is the recommended pattern in Godot tutorials ([source](https://gtstu.com/?p=4966)).
3. **Secrets never broadcast.** Each objective is stored only on the host and sent as an RPC to its owner, never in a synced property.
4. **Separate input from the body.** The player scene reads input into a small data object, so a bot or a remote player can drive the same character.
5. **Start on a local network or direct IP.** Online matchmaking and relay servers come after the game is fun; port forwarding is enough for friend testing.

## Roadmap

Phases 1-2 give you a game you can play alone by about month 5. Phases 3-5 turn it into the multiplayer game you described. Phase 6 makes it shippable. Month ranges are estimates for 8-10 hours a week and will move.

*[Diagram: roadmap · 6 phases, 6 gates, about 16 months at 8-10 hours a week. See the online version of this doc.]*

Each phase has a different learning focus, so you are never building and learning something huge at the same time.

| Phase | You build | You learn |
| --- | --- | --- |
| 1. Foundations | First-person controller, pistol, Crawler, one room | Scenes, nodes, signals, GDScript basics |
| 2. Solo vertical slice | 8-room ship, doors, keycards, items, escape ending | Level design, navigation, simple state machines, UI |
| 3. Co-op networking | Lobby, host and join, synced players and aliens, damage by RPC | Authority, `MultiplayerSpawner`, `MultiplayerSynchronizer`, debugging two game windows |
| 4. Tension systems | Noise per room, Stalker alien, scarce ammo and supplies, alarm lighting | Audio mixing, lighting, AI senses, tuning difficulty |
| 5. Secret objectives | Objective deck, private delivery to each player, win and lose checks, bots | Data-driven design, privacy in networking, balancing |
| 6. Polish and release | Art pass, sound pass, main menu, settings, save of options, export builds | Profiling, optimising, exporting for Windows and Linux |

## First two weeks

Goal: by the end of week 2 you can walk around a grey-box cryo bay, shoot, and be chased by one alien. Nothing else matters yet.

**Week 1: foundation**

- [ ] Install the latest stable Godot 4 from godotengine.org (the 4.7 series at the time of writing) and create a project named `cryo-breach`.
- [ ] Create a Git repository and add Godot's standard `.gitignore`; push to a private GitHub repo as your backup.
- [ ] Work through the official "Your first 3D game" tutorial in the Godot docs to learn nodes, scenes and GDScript basics.
- [x] Create the folder structure below.
- [x] Build a first-person controller: `CharacterBody3D`, camera, mouse look, WASD, sprint, jump.
- [x] Grey-box the cryo bay with `CSGBox3D` shapes (no art yet) and a few doors as plain boxes.

**Week 2: first fight**

- [ ] Add a hitscan pistol: a `RayCast3D` from the camera, with a muzzle flash and a placeholder sound.
- [ ] Make a target dummy with a `HealthComponent` script (health, `take_damage()`, `died` signal) and reuse that script on everything later.
- [ ] Bake a `NavigationRegion3D` over the cryo bay.
- [ ] Build the Crawler: a `CharacterBody3D` with a `NavigationAgent3D` that chases the player and does contact damage.
- [ ] Add a simple HUD (health bar, ammo count) and a restart-on-death flow.
- [ ] Play the result for 10 minutes and write three things that feel bad in a `playtest-notes.md` file.

**Suggested folder structure**

```text
res://
  scenes/        player, enemies, rooms, ui
  scripts/       reusable components (health, interact, noise)
  autoload/      game_state.gd, network.gd (added in phase 3)
  assets/        models, textures, audio
  docs/          design notes, playtest-notes.md
```

**Done when:** a stranger could pick up the build, understand how to move and shoot without help, and die to the Crawler in under two minutes.

## Art and audio pipeline

The look is low-poly with clean surfaces: simple shapes, a tight colour palette, and strong lighting doing most of the atmosphere. Lighting is cheap to produce and is what makes a ship feel scary, so spend your art effort there rather than on model detail.

**Style rules (write these in `docs/style-guide.md`)**

1. Under 2,000 triangles per character, under 500 per prop.
2. One shared palette of about 12 colours; metals and plastics use flat colours with a little roughness variation, no photo textures.
3. Dark ship, small pools of coloured light (red alarm, cold blue panel, green terminal) so each room has a readable mood.
4. Use fog, light shafts and screen-space effects for atmosphere instead of detailed geometry.

**Build the ship from a modular kit**

Make or download a small set of wall, floor, ceiling, door and corner pieces on a fixed grid (for example 4 m), then place them with Godot's `GridMap`. Eight rooms then cost days instead of weeks, and later maps reuse the kit.

**Where assets come from**

| Need | Source | Note |
| --- | --- | --- |
| Modular sci-fi kits, props, UI | Kenney, Quaternius | Both publish many CC0 (public domain) packs; verify each pack's licence file |
| Custom models | Blender (free) | Learn only low-poly modelling, not sculpting |
| Humanoid animations | Mixamo | Free with an Adobe account; fine to ship inside a game |
| Sound effects | Freesound, Kenney audio | Check each sound's licence; prefer CC0 |
| Music and drones | Free ambient packs, or later a paid composer | Dread comes from sparse sound, not melodies |

**Alien design**

Design your own creature so it is not read as a copy of the Nemesis intruders or the film xenomorph: change the silhouette, the movement and the way it senses the player. A creature that hunts by sound only (the Stalker) is both original and fits the noise mechanic.

**Licence habit.** Keep an `assets/CREDITS.md` file from day one listing every asset, its author and its licence. Fixing this late is painful.

## Risks and fallbacks

The biggest risk is not a technical one: it is losing motivation before the game is fun. Every phase therefore ends with something you can play and show.

| Risk | Warning sign | Fallback |
| --- | --- | --- |
| Multiplayer is too hard to debug | Players desync, doors open for some and not others | Drop to 2-4 players; keep co-op only and postpone hidden objectives |
| Scope creep | You add a new room, weapon or enemy before the last one is finished | Freeze features at each gate; new ideas go into a `later.md` list |
| Secret objectives leak to other players | A client can read another player's objective in the debug tools | Store objectives only on the host and send each one privately to its owner |
| Alien AI gets stuck or lags | Aliens freeze in doorways or all players see different positions | Simplify to waypoint patrols between rooms; run AI only on the host |
| Frame rate drops | Under 60 fps on your own machine | Bake lighting, limit shadow-casting lights, merge static meshes |
| Burnout | No work for two weeks | Shrink the next milestone to one evening of work and restart from a playable build |
| Asset licence trouble | An asset has no clear licence | Replace it with a CC0 asset or a grey-box placeholder before release |
| Version churn in the engine | Tutorials no longer match the editor | Pin one Godot version per phase and upgrade only between phases |

**Quality gates.** Do not start the next phase until the current one passes its playtest: a friend plays for 15 minutes without your help and can tell you what they were supposed to do.

## Sources

These come from web search results on 27 October 2026; I read the search excerpts, not the full pages. Asset licence notes (Kenney, Quaternius, Mixamo, Freesound) and the Nemesis game description are from general knowledge, so check each licence yourself before shipping.

- [Godot 4.6 debuts Modern theme, Jolt Physics, Node IDs, and LibGodot embed](https://alternativeto.net/news/2026/1/godot-4-6-debuts-modern-theme-jolt-physics-node-ids-and-libgodot-embed): Jolt became the default 3D physics engine for new projects in 4.6.
- [Godot Engine 4 4.6.2 APK listing, with later 4.7.x releases](https://www.apkmirror.com/apk/godot-foundation/godot-engine-4-2/): shows the 4.7 series released June to August 2026.
- [Godot 4 High-Level Multiplayer: Official Docs + Tutorial](https://gtstu.com/?p=4966): `MultiplayerSynchronizer` for continuous state, `@rpc` for one-off events.
- [Godot 4 ENetMultiplayerPeer: Multiplayer Tutorial for Beginners](https://gtstu.com/godot-4-multiplayer-tutorial-beginners/): host with `create_server`, join with `create_client`, set authority after spawning.
- [Godot 4 Multiplayer Overview (gist)](https://gist.github.com/Meshiest/1274c6e2e68960a409698cf75326d4f6): authority rules and per-peer visibility on synchronizers.
