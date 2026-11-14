# Cryo Breach: notes for Claude

A semi-co-op sci-fi horror FPS for 3-6 players, inspired by (not copied from)
the Nemesis board game. Built in **Godot 4.7** with **GDScript**. The owner is
a solo beginner, so explain Godot concepts briefly when introducing them, and
keep changes small enough to test in one sitting.

## Source of truth

- `docs/game-design-document.md`: every game rule. If the code and this
  doc disagree, the doc wins; ask before changing a rule.
- `docs/development-plan.md`: phases, the current week's checklist and
  the networking rules.
- `docs/build-plan/README.md`: the milestone-by-milestone build plan
  with code for every phase. **Start every session there**: build the
  first unticked milestone in its index, and follow its working rules.
- `docs/art-audio-brief/`: instructions for the graphic designer and sound
  designer (asset lists, specs, tools). Update it when rules or rooms change.
- The live versions of both docs (with diagrams) are on claude.ai; these
  Markdown copies were exported on 27 Oct 2026 and may fall behind. Ask the
  owner to re-export if a rule seems out of date.

## Where we are

- **Phase 1 (M1.0-M1.3) passed the owner's checks in Godot.** Gate 1 (a
  stranger plays 15 minutes) is still open.
- **M2.1 passed the owner's checks.** `scenes/match.tscn` is the main
  scene; `scenes/main.tscn` is kept as the Phase 1 test scene with the
  Crawler (the match scene has no aliens until M2.7).
- **M2.2 (generated ship), M2.3 (interaction) and M2.4 (items and
  inventory) passed the owner's checks.**
- **M2.5 (doors) is accepted.**
- **M2.6 (loot, crates, Medbay/Armory/Generator stations) is accepted.**
  The addons/ folder is not ours (a Godot plugin the owner installed); lint
  with `git ls-files -co --exclude-standard '*.gd' | grep -v '^addons/'`.
- **M2.7 is written but untested:** `ShipState` (in `GameState`, host only),
  Pod Bay socket and 3 single-seat escape pods, launch countdown, end screen
  (pauses the game; R restarts), `TimerDirector` (temporary Crawler spawner,
  deleted in M4.1) and `match.spawn_alien`. A launched pod ends the match.
- **M2.8 (room network) is written but untested.** The ship follows the
  owner's diagram (decision D22): 21 rooms and 28 corridors, 15 shuffled
  slots, three engines. The layout comes from `tools/make_ship_layout.py`,
  which writes `scripts/data/ship_layout_data.gd`; `ShipBuilder` builds
  polygon rooms and bent corridors from it. In Phase 2 all rooms are open
  (extras are Crew Quarters). The design doc and art brief copies were
  updated: ask the owner to re-export the live design doc. Only the
  arrangement follows the diagram; names and look stay ours.
- A stray file `C:\AppData_placeholder\unused.txt` was created by mistake
  outside the project; the owner can delete that folder.
- **Next:** owner checks M2.7 and M2.8, then **Gate 2** (a friend plays 15
  minutes solo), then Phase 3 (M3.1).
  The checklist for this is `docs/phase-1-2-checklist.md`.

## Architecture rules (from the design doc; follow them in every change)

1. **Every number lives in data.** Add new values to
   `scripts/data/tuning.gd` (with a doc comment) and `data/tuning.tres`,
   then read them through `Config.tuning`. No magic numbers in gameplay code.
2. **Content is data.** Rooms, items, recipes, alien types, objectives and
   the loot deck become `Resource` classes plus `.tres` files.
3. **The host keeps all secrets.** The alien pool, loot deck,
   contamination cards, objectives, engine states, course and noise meters
   exist only on the host. Clients receive only what their character can see.
   Even single-player runs as a host with one local player.
4. **Everything is room-based.** Rooms and corridor segments are `Zone`
   nodes (`scripts/world/zone.gd`, an `Area3D`). Noise, fire, breaches,
   power and vents attach to zones; explosions hit everything in a zone.
5. **Input is separate from the body.** `PlayerInput` fills an
   `InputState`; `PlayerCharacter` only reads `InputState`. Bots and
   network peers will supply their own `InputState`.
6. **Player-vs-player rule.** Bullets and melee never damage players.
   Only explosions, fire and hazards can.

## Conventions

- GDScript 2 with static types everywhere (`var x: float`, `:=` where the
  type is obvious). `class_name` on reusable scripts. Private members start
  with `_`. Doc comments (`##`) on every exported or public member.
- Physics layers: 1 world, 2 players, 3 aliens, 4 zones. Zones use
  collision_layer 0 and mask players + aliens (6).
- Key bindings are created in code by `scripts/core/input_setup.gd`;
  actions defined in Project Settings > Input Map take priority.
- Scenes live in `scenes/`, scripts in `scripts/` mirrored by area.
- List every outside asset in `assets/CREDITS.md` the day it is added
  (prefer CC0). Never use Nemesis names, art or characters.

## Checking your work

There is no Godot binary in every environment. At minimum, before saying a
change is done:

```
pip install gdtoolkit==4.5.0
gdparse $(find . -name "*.gd")
gdlint $(find . -name "*.gd")
```

If Godot is installed, also run the project headless to catch scene and
script errors:

```
godot --headless --path . --quit-after 120
```

When code has not been run in Godot, say so plainly and give the owner a
short list of things to try.
