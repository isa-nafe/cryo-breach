# Art brief: 3D models, textures, UI, effects, animation

For the graphic designer. Read `README.md` in this folder first: it has the
look, the colour palette, the fixed hex-room dimensions, the rules about what
art must not give away, the tools, and the file rules.

**Priority:** **P1** = needed soon for the playable build, **P2** = needed for
the full game, **P3** = polish, can be cut. **Budget** = triangles per object.
Roughly 150 models and 100 icons, plus about 100 animations, by release.

---

## 1. The ship kit (P1: do this first)

Everything is built from modular pieces. The game assembles the ship in code,
so pieces must fit exactly: use the dimensions in the README (hex side 6 m,
wall panel 3 m x 3.5 m, door 2 m x 2.4 m, corridor 4 m wide x 3 m high,
modules 4 m long). Build on a 1 m grid with the origin on the floor.

### Hexagonal room pieces

| Asset | Details | Budget | Prio |
| --- | --- | --- | --- |
| `env_hex_wall_panel` | 3 m x 3.5 m, 0.2 m thick, plain hull panel with trim. Two make one side. Two or three visual variants (plain, vented, pipe-run). | 150 | P1 |
| `env_hex_wall_door_side` | A full 6 m side with a centred 2 m x 2.4 m door opening and a door frame. Door frame holds a small light (red/green/orange states, see Doors). | 300 | P1 |
| `env_hex_wall_corner_post` | Pillar that hides the 120 degree seam where two sides meet. | 80 | P1 |
| `env_hex_floor` | One whole hexagonal floor (side 6 m), a floor plate pattern in 2 m squares. | 100 | P1 |
| `env_hex_ceiling` | Matching ceiling hexagon with a light fixture cut-out and a vent opening. | 120 | P1 |
| `env_room_large_floor`, `env_room_large_ceiling` | The Cryo Bay: a tall oval, 17 m wide and 34 m long (the floor, ceiling and curved wall). | 300 | P2 |
| `env_room_engine_floor`, `env_room_engine_ceiling` | The engine rooms: a D shape, 14.4 m x 20 m, flat wall on the left, rounded on the right, machine-hall feel. | 250 | P2 |
| `env_room_cockpit_floor`, `env_room_cockpit_ceiling` | The Bridge: an oval about 12 m x 22 m, with a big window wall at the front. | 250 | P2 |
| `env_hex_wall_window` | Wall panel with a window onto space (the Bridge and Cryo Bay use it). | 150 | P2 |
| `env_hex_wall_damaged` | Variants: scorched, cracked (for after fires and explosions). | 150 | P3 |

### Corridor pieces

| Asset | Details | Budget | Prio |
| --- | --- | --- | --- |
| `env_corridor_straight_4m` | A straight corridor module: 2 m wide, 2.4 m high, 4 m long, with floor, two walls and ceiling in one piece, pipes and a light strip. Corridors are 2 to 19 m of straight run between bends: pieces are cut to length by the code, so also give a stretchable variant. 2 or 3 variants. | 300 | P1 |
| `env_corridor_bend` | A bend that can be turned to any angle from 10 to 90 degrees, 2 m wide, with a rounded or mitred outer wall. | 300 | P1 |
| `env_corridor_door_collar` | The frame around a room's doorway where a corridor meets the room wall: a 2 m x 2.4 m opening in the 0.2 m wall. | 200 | P1 |
| `env_sealed_side_panel` | A blank wall section for a room side that has no doorway (rooms have 3 to 4 of these). | 100 | P2 |

### Doors

| Asset | Details | Budget | Prio |
| --- | --- | --- | --- |
| `env_door_slab` | The sliding slab, 2 m x 2.4 m, door orange, with a thick edge and a small status light. The code slides it up. | 200 | P1 |
| `env_door_state_lights` | Three light colours on the frame: **green** open/unlocked, **red** locked, **amber** welded or forced. Emissive materials are enough. | 20 | P1 |
| `env_door_weld_seam` | A separate mesh or decal: a rough bead of welding across the door edge, shown only when welded. | 60 | P1 |
| `env_door_forced` | Optional: a half-open, buckled door for when a Breeder or Queen has broken it. | 250 | P3 |

### Hazard and system pieces that attach to the kit

| Asset | Details | Budget | Prio |
| --- | --- | --- | --- |
| `env_vent_floor` | Floor vent grate, 0.8 m square. States: **normal**, **rattling** (shakes; animated by the code), **welded** (a metal plate over it). Every room and every corridor has one. | 150 | P1 |
| `env_vent_wall` | Wall-mounted version, same states. | 150 | P2 |
| `env_alarm_light` | Rotating or pulsing red light fixture. | 100 | P1 |
| `env_light_strip` | Long thin ceiling light (emissive). | 40 | P1 |
| `env_lamp_panel` | Ceiling panel light, square. | 60 | P1 |
| `env_breach_hole` | A jagged hull hole with stars beyond it, shown during a hull breach. | 300 | P2 |
| `env_pipes_set` | Set of 5 to 8 pipe and cable pieces to dress walls and ceilings. | 100 each | P2 |
| `env_search_crate`, `env_search_locker`, `env_search_cabinet` | The searchable containers (about 0.7 m). Each needs a **closed** and a **searched** (open, rummaged) state. | 200 each | P1 |

---

## 2. Room props: one landmark per room (P1 for rooms in the first build, P2 for the rest)

Rooms must be **recognisable the moment you step in**, from props alone (no
labels: see README section 4). Each room has 1 or 2 big landmark props plus its
working stations. Stations are what the player uses (hold E); make them
chunky, readable and clearly interactive, with a small screen or light.

Rooms are hexagons (side 6 m): keep props against the walls so the centre of
the room stays open, and leave a 2 m wide path clear from the door.

| Room | Props and stations | Prio |
| --- | --- | --- |
| **Bridge** (fixed) | Navigation console (three-position course display), ship status panel (integrity and crew-count display), self-destruct console with a keycard slot and a cover, a pedestal holding the Data Core, a big forward viewscreen | P1 |
| **Cryo Bay** (fixed) | 6 cryopods, each with four states: **closed empty**, **open**, **closed with a sleeper** (frosted glass, a silhouette inside), **malfunctioning** (sparks, red light). A bay control console. | P1 |
| **Engine Room A and B** (fixed) | A big engine core: states **working** (steady glow) and **damaged** (smoke, flicker). An engine console. A and B should be recognisably different. | P2 |
| **Pod Bay** (fixed) | 3 escape pods, each with 2 seats, hatch **open**/**closed**, red or green status light, and a launching state. A pod power **socket** (two-handed power cell goes in), off and on states. | P1 |
| **Medbay** | Scanner booth (an upright body scanner), surgery pod, rest bed | P1 |
| **Workshop** | Workbench with tools (crafting happens here) | P2 |
| **Armory** | Ammo locker (shows full / empty), wall gun rack (one gun or empty) | P1 |
| **Security** | Door-control terminal with a map screen, pod-control terminal | P2 |
| **Generator** | Large generator unit, a breaker panel with three switches (Fore, Mid, Aft; on and off) | P1 |
| **Storage** | Shelving and stacks of crates (the room has six search spots) | P2 |
| **Comms** | Broadcast microphone console, radio rack | P2 |
| **Lab** | Sample analyser machine with a tray for the Alien Sample | P2 |
| **Fire Control** | Control console with a ship-section diagram, sprinkler pipes | P2 |
| **Air Control** | Console and a large vent fan | P2 |

Each station also needs a **disabled state** ("malfunction" or "no power"):
screens dark or showing an error, and a small red light. One shared
"disabled" overlay material is fine.

---

## 3. Items (30 items, P1 for the first 7)

For every item, the same asset three ways:

1. **World model** (what lies on the floor and in a container): under 500
   triangles, about 20 to 60 cm, simple and instantly recognisable.
2. **Icon**: 128 x 128 PNG, transparent background, shown in the inventory.
3. **Hand model** (what the player sees in their hand): only for items that
   can be held and used. It can be the world model with more detail (up to
   1,000 triangles).

First 7 (P1): **pistol, ammo box, medkit, bandage, keycard, welder, power
cell.**

| Group | Items |
| --- | --- |
| Weapons (11) | Knife, stun baton, welder (also a tool), pipe club (crafted), pistol, assault rifle (two-handed), shotgun (two-handed), grenade, pipe bomb (crafted), fire bomb (crafted), noisemaker |
| Medical (3) | Medkit, bandage, handheld scanner |
| Tools (6) | Keycard, toolkit, extinguisher (two-handed), O2 mask, radio, flashlight |
| Detection (1) | Motion tracker (with a small screen for blips) |
| Objective items (3) | Power cell (two-handed, glowing), Data Core, Alien Sample (organic, glowing a little) |
| Crafting parts (6) | Chemicals (bottle), rag, duct tape, pipe, battery, ammo box |

Notes:

- **Weapons look different from each other in silhouette**, not just in
  colour, because players see them at a glance.
- Stackable items (ammo, bandages, chemicals, rags, duct tape, batteries,
  noisemakers) only need one model; the count is drawn by the game.
- The **pistol, assault rifle and shotgun** need a muzzle point (an empty
  object named `muzzle`) for the flash effect.
- **Thrown items** (grenade, pipe bomb, fire bomb, noisemaker) should look like
  a held version and a lying version that is the same model.

---

## 4. Crew (P2)

**One shared body model** for all six crew, so one set of animations works for
everyone.

| Asset | Details | Budget | Prio |
| --- | --- | --- | --- |
| `crew_base` | Adult humanoid in a plain flight suit and helmet with a front lamp. Gloves, boots. No visible role gear, no insignia. A face is optional: a tinted visor is enough. | 2,000 | P2 |
| `crew_rig` | Standard humanoid skeleton with Mixamo-compatible bone names so Mixamo animations can be applied. Empty "socket" bones for a held item in each hand (`hand_main`, `hand_off`). | | P2 |
| Colour tags (6) | A shoulder stripe and helmet band in six distinct colours: crimson, azure, lime, gold, violet, white. One per player slot. A texture swap or a small separate mesh per colour. | | P2 |
| `crew_body_dead` | The crew model lying in two or three death poses (searchable corpse). | 2,000 | P2 |
| `crew_cryo_sleeper` | The model lying in a cryopod (for sleeping players). | 2,000 | P3 |
| `fp_arms` | First-person arms and gloves for the hand view, same suit, 500 triangles. | 500 | P1 |

**Remember:** nothing about the model may reveal the player's role, wounds or
infection (README section 4).

---

## 5. Aliens (P2 for the first, the rest by the end of Phase 4)

Five original alien types. The same creature must be recognisable at a glance
in the dark, by silhouette and by how it moves.

**Do not copy any film alien or any board-game creature.** Avoid: a long smooth
elongated skull, an inner extending jaw, acid blood, a spiked tail like the
films, and the Nemesis intruder body shapes. Make your own species. Suggested
design direction (change it if you have a better idea, but keep the roles):

| Type | Role | Design direction | Budget | Prio |
| --- | --- | --- | --- | --- |
| **Larva** | Tiny, fast, latches onto a crew member, then flees | About 30 cm; pale, many thin legs, a leech-like or spider-like body, a clamp mouth. Skitters at floor level. | 400 | P2 |
| **Crawler** | The first and commonest hunter; fast; hunts by sight | About 1 m long, low and wide, six limbs, clustered eyes at the front (they glow faintly so the player sees it looking). | 1,200 | P1 |
| **Adult** | Slow, heavy, **blind**; hunts by sound only | About 2.2 m, hunched, no eyes at all; instead big fan-like hearing membranes on the head. It must look obvious that it cannot see. | 1,800 | P2 |
| **Breeder** | A stronger Adult; breaks doors | Bulkier (2.5 m), armour plates, egg-sac-like growths on the back; visibly an older, evolved Adult. | 2,000 | P2 |
| **Queen** | Boss, 400 health | About 4 m, many limbs, a crest or crown shape, big and slow-moving; it sees and hears. May go up to 2,500 triangles with the owner's approval. | 2,500 | P2 |

All aliens: dark red-brown flesh (palette colour *Alien flesh*) with one
bioluminescent accent colour per type so they read in the dark. Each needs a
**vent-friendly pose**: the Crawler and Larva climb out of a 0.8 m floor vent.

**Alien drops:** `item_alien_sample` is dropped by the Adult, Breeder and
Queen when killed.

---

## 6. Animation

Animations are exported inside the `.glb` of the model they belong to. Use
short clear names, lowercase with underscores.

### Crew (shared skeleton) (P2)

| Group | Animations |
| --- | --- |
| Movement | `idle`, `walk`, `walk_back`, `strafe_left`, `strafe_right`, `sprint`, `crouch_idle`, `crouch_walk`, `jump`, `land` |
| Holding | `hold_one_hand` (pistol), `hold_two_hand_rifle`, `hold_two_hand_carry` (power cell, extinguisher) |
| Actions | `melee_swing` (2 variants), `throw`, `use_hold` (hold at a console), `search_container`, `weld`, `repair`, `heal_self`, `reload` |
| Reactions | `hit_light`, `hit_serious`, `knockdown`, `get_up`, `death_a`, `death_b` |
| Pods | `climb_into_pod`, `sit_in_pod` |

About 30 animations. Mixamo covers about half; the rest can be made in
Blender.

### First-person arms (P1)

`idle`, `fire_pistol`, `fire_rifle`, `fire_shotgun`, `reload_pistol`,
`reload_rifle`, `reload_shotgun`, `melee`, `throw`, `use_item`, `weld`,
`heal`, `draw` and `stow` (each 0.75 s), `carry_two_hand`. Walking bob and
sway are done by the code.

### Aliens (P1 for the Crawler, P2 for the rest)

Per type: `idle`, `move` (and `run` where it differs), `attack` (two variants
for the big ones), `hurt`, `stunned`, `death`. Plus:

| Type | Extra animations |
| --- | --- |
| Larva | `latch_on`, `flee` |
| Crawler | `climb_out_of_vent`, `enter_vent` |
| Adult | `charge`, `flee` |
| Breeder | `charge`, `slam_door` (about 5 s of hammering at a locked door), `knockdown_attack` |
| Queen | `roar`, `slam_door`, `ground_stomp`, `flee` |

About 45 animations in all.

### Props and environment animations (P1 to P2)

| Asset | Animation |
| --- | --- |
| Door | `open`, `close` (about 0.3 s each; the code can also slide it) |
| Vent | `rattle` (loopable), `open_burst` |
| Cryopod | `open`, `close`, `freeze_over` |
| Escape pod | `hatch_open`, `hatch_close`, `launch` (leaves the bay) |
| Engine | `working_loop`, `damaged_loop` |
| Alarm light | `pulse` |
| Terminal screens | simple state images: `idle`, `working`, `error`, `off` |

---

## 7. Textures and materials (P1)

No photo textures. Flat colours from the palette, with small details painted
or generated in Material Maker.

| Material | Used on |
| --- | --- |
| Hull panel (painted metal) | Walls: 3 colour variants (light, mid, dark) |
| Floor plate and grate | Floors; walkable grate variant with a dark underlay |
| Pipe and cable | Dressing |
| Glass and visor | Cryopods, windows, helmets (see-through, slight cyan) |
| Emissive screen | Terminals: four states (idle blue-green, working amber, error red, off) |
| Door orange | Doors |
| Alien flesh | All aliens, plus a variant for a wet or injured look |
| Fabric / suit | Crew |
| **Hazard stripe** | Yellow and black stripes for edges and floor markings |

One small **trim sheet** (a single image with many strips of detail) is
better than many separate textures: use it on as many pieces as you can.

### Decals (P2)

Scorch marks (after explosions), char (after fire), bullet impact on metal,
alien goo trail, frost on glass, a cracked-glass overlay. Each a transparent
PNG, 512 x 512 or smaller.

**No text and no room names on any texture** (README section 4). Arrows and
generic hazard icons are fine.

---

## 8. Effects (sprite sheets and textures) (P1 for the first 4)

The programmer builds the particle systems in Godot. You supply the textures
and, where listed, short sprite sheets (PNG, transparent background, 4 x 4
frames of 128 x 128 unless noted).

| Effect | What to supply | Prio |
| --- | --- | --- |
| Muzzle flash | Three flashes (pistol, rifle, shotgun) | P1 |
| Bullet impact | Spark puff on metal; green-red splat on alien flesh | P1 |
| Fire | Flame sheet and a smoke sheet (loopable). Fire burns a whole room for 3 minutes, so it must look good large | P1 |
| Explosion | A fireball sheet and a shockwave ring | P1 |
| Welding sparks and electric sparks | One bright spark sheet; a blue-white arc | P2 |
| Steam and air rush | Soft smoke puffs (hull breach, vents) | P2 |
| Extinguisher foam | White foam burst | P2 |
| Vent dust | Small dust and grit puff for a vent opening | P2 |
| Noisemaker pulse | A thin expanding ring | P2 |
| Pod launch | Engine flare and exhaust | P2 |
| Cryo frost | Frost and breath puff | P3 |
| Hyperspace jump | Full-screen stretched star streaks, plus a white flash | P2 |
| Motion-tracker blip | A small glowing dot and a ping ring | P2 |
| Light cookies | A soft spotlight shape for the helmet lamp and a wider one for the flashlight | P2 |
| Space | Star panorama (equirectangular or cubemap), plus three viewscreen images: Earth, Mars Station, deep space | P2 |

---

## 9. UI and icons

Style: **terminal-like**: monospace type, thin lines, palette colours, a small
amount of glow. Everything must be readable in a dark room. Keep a safe margin
so the HUD works at 1280 x 720 and larger. Prefer fonts under the **OFL**
licence (Google Fonts).

### In-game HUD (P1 unless noted)

| Asset | Details |
| --- | --- |
| Crosshair | 2 or 3 variants, plus a hit marker (shown when you hit an alien) |
| Hand and slot frames | Frames for the 2 hands and 4 slots, empty and selected |
| Hold bar | Progress bar for hold-to-use actions |
| Key glyphs | E, left mouse, right mouse, R, X, G, F, 1, 2, 3, 4 |
| Item icons | The 30 item icons from section 3 |
| Wound icons | Light wound, serious wound, and the four serious-wound effects: **Limp**, **Shaky aim**, **Broken arm**, **Bleeding** (P2) |
| Contamination | Icon for a contamination card: unchecked, and checked-infected (P2) |
| Match clock | A clock frame and digits style |
| Announcement banner | A wide banner style for ship announcements (P2) |
| Prompt box | A small panel behind interaction text |
| Air meter | A circular or bar meter for O2 mask air left (P2) |
| Screen overlays | Damage vignette, low-air vignette, knockdown blur, alarm tint (P2) |

### Maps and cards (P2)

| Asset | Details |
| --- | --- |
| Hull map | A vector outline of the ship (12 hex rooms and the 15 corridors between them) for the personal map |
| Room icons (15) | One small icon each for the 15 room types: Bridge, Cryo Bay, Engine A, Engine B, Pod Bay, Medbay, Workshop, Armory, Security, Generator, Storage, Comms, Lab, Fire Control, Air Control. They appear only on a player's own map after they visit the room |
| Objective icons (17) | 8 crew and 9 personal objectives: Strength in numbers, Bring her home, Pest control, Save the ship, Clean bill of health, Bodyguard, Sleep together, Full house; Alone in the dark, Grudge, Corporate secrets, Specimen, Exclusive, Hunter, Early exit, Cold storage, Quarantine |
| Objective card frame | A card layout with an icon area, a title and text; a crew version and a personal version (different colours) |
| Terminal choice menu | A panel, a button and a progress bar in the terminal style |

### Menus and screens (P2 to P3)

| Asset | Details | Prio |
| --- | --- | --- |
| Logo | "Cryo Breach", horizontal and square versions | P2 |
| Main menu background | A dark ship scene or a 3D render of the Cryo Bay | P2 |
| Lobby | Six role cards (Captain, Soldier, Mechanic, Medic, Scout, Scientist), each with an emblem and a one-line summary. Roles are public in the lobby only. | P2 |
| End screen | Win and lose banner styles; a row layout for each player's fate and objective | P2 |
| Buttons | Normal, hover, pressed, disabled | P2 |
| Loading and pause screens | Simple | P3 |
| Game icon | A square icon for the window and the game list | P2 |
| Store capsule art, trailer thumbnails | | P3 |

---

## 10. Lighting reference (guidance for the programmer, not assets)

The programmer will light the rooms; please design your materials to look
right under these moods:

| Place | Light |
| --- | --- |
| Corridor | Cold, dim white-blue |
| Cryo Bay | Cyan |
| Bridge | Cold blue with green screens |
| Medbay | Green-white, clean |
| Armory | Amber |
| Engines | Orange |
| Pod Bay | Red |
| Power outage | Only the player's helmet lamp |
| Alarm (35:00) | Pulsing red everywhere |

---

## 11. Summary of what to deliver

| Category | About |
| --- | --- |
| Ship kit pieces | 25 |
| Room props and stations | 40 |
| Items (world + icon + hand) | 30 |
| Crew model, rig, colour tags, bodies | 1 model + 6 colour tags + 2 body poses |
| Alien models | 5 |
| Crew animations | 30 |
| Alien animations | 45 |
| First-person animations | 15 |
| Prop animations | 15 |
| Materials and decals | 12 materials + 6 decals |
| Effect sprite sheets | 20 |
| UI and icons | about 100 |

Do the **P1** items first and tell the owner when each batch is ready; the
game is tested with every batch, and feedback comes back quickly.
