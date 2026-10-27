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
- The live versions of both docs (with diagrams) are on claude.ai; these
  Markdown copies were exported on 27 Oct 2026 and may fall behind. Ask the
  owner to re-export if a rule seems out of date.

## Where we are

- **Week 1 (Phase 1) is done but untested.** The first-person controller,
  grey-box Cryo Bay, zone noise and debug HUD were written and checked with
  gdtoolkit, but have not yet been run in Godot. The README lists a first-run
  checklist; confirm it passes before building on top of it.
- **Next: Week 2.** Hitscan pistol, reusable `HealthComponent` (aliens only;
  players use the wound system), baked `NavigationRegion3D`, the first
  Crawler, a HUD and a restart-on-death flow.

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
