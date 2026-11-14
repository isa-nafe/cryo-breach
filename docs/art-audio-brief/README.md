# Cryo Breach: art and audio brief

Written 13 Nov 2026 for the graphic designer and the sound designer. Read this
page first, then your own brief:

| File | For |
| --- | --- |
| `README.md` (this page) | Everyone: the game, the look, shared rules, tools, delivery |
| `art-brief.md` | Graphic designer: 3D models, textures, UI, effects, animations |
| `audio-brief.md` | Sound designer: sound effects, ambience, music, announcements |

## 1. The game in one minute

Cryo Breach is a first-person sci-fi horror game for 3 to 6 players, built in
**Godot 4.7**. The crew wakes from cryosleep on the cargo ship *Meridian*. The
ship is overrun by aliens. Everyone has a secret objective and nobody can
shoot another player, so the tension comes from noise, doors, fire and
betrayal. A match lasts 40 minutes.

Three things the art and sound must always support:

1. **Noise attracts death.** Loud things (gunshots, sprinting, explosions)
   must *sound* loud and be easy to tell apart from quiet things. Sound is
   gameplay information here, not decoration: a player should be able to hear
   an alien coming, hear a vent rattle before an alien climbs out, and hear
   a door being forced two rooms away.
2. **Paranoia.** Players are weak and cannot trust each other. The ship is
   dark, with small pools of coloured light. Quiet is scary.
3. **Secrets stay secret.** Other players must never learn your role, your
   wounds or your infection by looking at you. See section 4.

The ship is not a copy of any existing game. **Never use names, art,
characters, creature designs or sounds from the *Nemesis* board game, the
*Alien* films or any other franchise.** Aliens are original (see the art
brief). If an asset looks like it came from a film, redo it.

## 2. The look

- **Low-poly, clean surfaces, strong lighting.** Simple shapes, flat colours,
  a little roughness variation. No photo textures. The atmosphere comes from
  light, fog and sound, not from model detail.
- **Dark ship, small pools of coloured light**: red alarm, cold blue panel,
  green terminal, amber warning. Each room has a readable mood.
- **Shared palette of about 12 colours.** Proposed starting palette (the
  designer may adjust it, with the owner's approval, before building much):

| Name | Hex | Used for |
| --- | --- | --- |
| Hull light | `#8B939E` | Wall panels |
| Hull mid | `#5B6470` | Wall trim, props |
| Hull dark | `#2B3039` | Floors, ceilings, shadows |
| Floor plate | `#3A3F48` | Floor tiles and grates |
| Door orange | `#D9731A` | Doors (the current prototype colour) |
| Panel cyan | `#2FB5CF` | Cryopods, cold lights, screens |
| Alarm red | `#E63B2E` | Alarms, locks, danger |
| Terminal green | `#3DDC84` | Terminals, "OK" states, unlocked pods |
| Warning amber | `#F2B632` | Hazard stripes, caution lights |
| Medical white | `#E8ECEF` | Medbay, medkits |
| Alien flesh | `#730D0D` | Alien bodies (dark red-brown) |
| Void | `#050608` | Space, deep shadow |

## 3. The ship: hexagonal rooms joined by corridors

The ship is built from **hexagonal rooms** linked by **corridors**, in the
spirit of a board-game map. Each match has 12 rooms, chosen from 15 room
types (see the art brief for the list). Every room has **2 or 3 doorways**, one on any of its six sides, and each
doorway leads to a short straight corridor (4 m long) that joins it to the
neighbouring room. The corridors form a network with loops, from the Bridge at
the front to the Pod Bay at the back. A corridor runs straight along one of
six directions, 60 degrees apart, and has a door in its middle.

**Why this matters to you.** The game builds the ship from your pieces, in
code, from a table of room positions. So you make a **modular kit** (wall
panels, floor tiles, door frames, corridor pieces) that all fit one fixed
grid. We place them; you never model a whole room as one object.

Fixed dimensions (the code is built around these; tell the owner before
changing any):

| Piece | Size |
| --- | --- |
| Hex room, **side length** | **6.0 m** (so 12.0 m corner to corner, 10.39 m flat to flat) |
| Hex room, wall height | 3.5 m |
| Hex wall panel | 3.0 m wide x 3.5 m tall (two panels make one 6 m side) |
| Corner between two sides | 120 degrees, hidden by a corner post piece |
| Door opening | 2.0 m wide x 2.4 m tall, in the middle of one side (any of the six sides can have one) |
| Corridor width / height | 2.0 m / 2.4 m |
| Corridor length | 4.0 m between two rooms, with a door in the middle |
| Wall thickness | 0.2 m |
| Unit | 1 Godot unit = 1 metre |

**Special rooms.** The ship layout is the same every match and follows a
fixed diagram. Six rooms have their own shape and never move: the **Bridge**
(an oval about 12 m wide and 22 m long, across the ship), the **Cryo Bay** (a
tall oval, 17 m wide and 34 m long, in the middle of the ship) and the **three
engine rooms** (D shapes, 14.4 m x 20 m: a flat wall toward the ship, a
rounded end at the back). The Pod Bay and the other 15 rooms are regular
hexagons; the 15 shuffled ones get a different room type every match. Rooms
have 2 to 5 doorways.

**Corridors.** 28 corridors, each 2 m wide and 2.4 m high, between about 8 m
and 27 m long (14 m on average). They are straight pieces joined by bends of
up to 90 degrees, and each has one door in the middle of its longest piece.
So the kit needs straight modules plus a bend that can be turned to any angle.

The art brief lists every kit piece.

## 4. Things the art must NOT give away

These come straight from the game rules:

- **No room names or labels on doors, walls or corridors.** A player only
  learns what a room is by stepping inside. Props inside a room can identify
  it. (Signs that say "MEDBAY" above a door would break the game.)
- **Crew look the same.** Everyone wears the same suit. A player's *role*
  (Captain, Soldier...) and *wounds* and *infection* must never be visible on
  their body. Each player gets a different **colour tag** (shoulder stripe,
  helmet band) so people can tell crew apart; the colour is per player slot,
  not per role.
- **Aliens are not obviously weaker or stronger by size alone**: use silhouette
  and movement so each type is recognisable in the dark.
- **Hazards are visible to everyone** (fire, breach, outage), so they need
  clear visuals. Engine state, ship course and noise levels are *never*
  shown outside terminals.

## 5. Free and open-source tools

Prefer these. Use something else only if you already know it well and it
exports the same formats.

| Job | Tool | Notes |
| --- | --- | --- |
| 3D models, rigging, animation | **Blender** (blender.org) | Free, open source. Does everything in the art brief. |
| Painting textures, icons, UI | **Krita** (krita.org) | Free, open source. |
| Vector icons, logo, UI shapes | **Inkscape** (inkscape.org) | Free, open source. Exports SVG and PNG. |
| Procedural textures | **Material Maker** (materialmaker.org) | Free, open source, made with Godot. |
| UI mock-ups (optional) | **Penpot** (penpot.app) | Free, open source, runs in the browser. |
| Photo/raster editing (optional) | **GIMP** (gimp.org) | Free, open source. |
| Humanoid animations (shortcut) | **Mixamo** (mixamo.com) | Free with an Adobe account; not open source. Fine to ship inside a game. |
| Preview your work in the real engine | **Godot 4.7** (godotengine.org) | Free, open source. Import your assets and look at them under game lighting. |
| Sound editing | **Audacity** (audacityteam.org) | Free, open source. |
| Music and layered sound (DAW) | **Ardour** (ardour.org) or **LMMS** (lmms.io) | Free, open source. |
| Quick retro and UI sounds | **jsfxr** (sfxr.me) or **ChipTone** (sfbgames.itch.io/chiptone) | Free, in the browser. |
| Synthesised drones and sci-fi tones | **Surge XT** (surge-synthesizer.github.io) and **VCV Rack** (vcvrack.com) | Free, open source. |
| Batch converting audio | **FFmpeg** (ffmpeg.org) | Free, open source, command line. |
| Version control | **Git** with **Git LFS** | The owner will show you how; or ask for a shared folder instead. |

Not open source but acceptable for sound design if you already own them:
Reaper, Vital.

## 6. Ready-made assets you may use (check the licence of every file)

Using a free, ready-made asset is encouraged, as long as it is **CC0 (public
domain)** or another licence that allows commercial use without attribution
problems. Check the licence file in every download. If there is no clear
licence, do not use it.

| Need | Where to look |
| --- | --- |
| Modular sci-fi kits, props, UI, 3D | **Kenney** (kenney.nl), **Quaternius** (quaternius.com) |
| General game art | **OpenGameArt** (opengameart.org): filter by CC0 |
| Sound effects | **Freesound** (freesound.org): filter by *Creative Commons 0*; **Kenney audio**; **OpenGameArt** audio |
| Large royalty-free sound libraries | **Sonniss GDC game audio bundles**: free for commercial use; read their licence page |
| Fonts | **Google Fonts** (OFL licence): for example *Share Tech Mono*, *Rajdhani*, *Exo 2* |
| Humanoid animations | **Mixamo** |

Pre-made models usually need to be **recoloured to our palette and checked
against our polygon budgets**. Ready-made kits rarely fit a hexagonal grid, so
expect to build the hex wall kit yourself.

## 7. Rules for every file

- **Credits, the same day.** Every outside asset (anything not made by you or
  the owner) goes in `assets/CREDITS.md` with its author, source link and
  licence. Fixing this later is painful. Your own work: credit yourself there
  too, with licence "made for Cryo Breach".
- **Naming:** lowercase, underscores, no spaces: `env_hex_wall_panel.glb`,
  `icon_item_medkit.png`, `sfx_door_slide_01.wav`. A number at the end
  (`_01`, `_02`) means variations of the same sound or image.
- **Folders** (inside the game project):

```text
assets/
  models/      env/  props/  items/  crew/  aliens/
  textures/    (shared materials, decals, particle sprites)
  ui/          icons/  hud/  menus/  fonts/
  audio/       sfx/  ambient/  music/  ui/  voice/
  CREDITS.md
```

- **Keep your source files** (`.blend`, `.kra`, `.svg`, `.aup3`, `.ardour`)
  in a shared folder outside the game project; put only the **exported**
  files in `assets/`. The owner will tell you where the shared folder is.
- **Formats:**

| Kind | Format |
| --- | --- |
| 3D models and animations | **glTF 2.0 binary (`.glb`)**, exported from Blender |
| Images, icons, decals, sprite sheets | **PNG** (RGBA where transparency is needed) |
| Vector UI | SVG (kept as source) plus PNG export |
| Short sound effects | **WAV**, 16-bit, 44.1 kHz |
| Loops, ambience, music | **OGG Vorbis**, quality 6 |

- **3D export rules:** 1 unit = 1 m; Y is up; origin at the middle of the
  floor under the object (doors: at the bottom centre of the doorway);
  apply all transforms before export; no hidden objects; one material per
  surface type from the shared palette. Face the front of a model toward
  **-Z** after import: export one test model first and the owner will check
  its orientation in Godot, then you copy that setup for everything else.
- **Never put a role, room name or objective in a file name or texture.**

## 8. How the work is ordered

The game is built in phases. You will not be asked for everything at once; the
order below matches what the programmer needs next.

| When | Art | Audio |
| --- | --- | --- |
| **Now (Phase 2-3)**: the game is grey boxes | Test export (section 9), then the hex room kit, corridor kit, doors, the first 7 items | Test export, then a "starter 20" of the most important sounds |
| **Phase 4**: danger and ship systems | Aliens, remaining items and weapons, room props, hazards, effects | Alien sounds, weapons, ship systems, alarms, ambient layers |
| **Phase 5**: secrets and roles | Crew model and colour tags, objective cards, HUD icons, lobby screens | Announcements, UI, stingers |
| **Phase 6**: polish | Final lighting pass, animation polish, logo, menus, store art | Mix pass, music, final loudness check |

Each brief marks assets **P1** (needed for the playable build soon), **P2**
(needed for the full game) or **P3** (polish, can be cut).

## 9. First week: prove the pipeline

Do these small tests before building lots of assets, so any problem shows up
early.

**Graphic designer**

1. Model one **hex wall panel** (3 m x 3.5 m) and one **door-frame panel**
   (same size, with a 2 m x 2.4 m opening). Export both as `.glb`.
2. Make a 128 x 128 PNG icon for the **medkit** with a transparent
   background.
3. Send them to the owner, who will put them in the game and report back on
   scale, orientation and colour.

**Sound designer**

1. Make or find three sounds: a **pistol shot**, a **door sliding open**, and
   a **vent grate rattling** (the cue that an alien is about to appear).
   Export as 44.1 kHz 16-bit WAV, dry (no reverb), peaking at -3 dB.
2. Send them to the owner, who will put them in the game and check how they
   sound next to each other.

Questions go to the owner. The rules of the game are in
`docs/game-design-document.md` if you need to understand *why* something is
needed.
