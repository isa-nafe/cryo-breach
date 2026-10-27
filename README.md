# Cryo Breach

A semi-co-op sci-fi horror FPS for 3-6 players, built in Godot 4.7.
The full rules are in `docs/game-design-document.md` and the schedule is in
`docs/development-plan.md` (copies of the docs on claude.ai). `CLAUDE.md`
gives Claude Code the context it needs to work on this project.

This is the **Week 1** build: a first-person controller in a grey-box Cryo Bay
with the spine corridor outside it.

## Open it

1. Install **Godot 4.7** (the standard version, not .NET) from
   https://godotengine.org/download.
2. Start Godot. In the Project Manager click **Import**, pick this folder's
   `project.godot`, then **Import & Edit**.
3. Press **F5** (or the play button, top right) to run the game.

The first import takes a few seconds while Godot creates its `.godot` folder.

## Controls

| Key | Action |
| --- | --- |
| W A S D or arrows | Move |
| Mouse | Look |
| Shift | Sprint (makes noise) |
| Ctrl or C | Crouch (silent, fits under low gaps) |
| Space | Jump |
| F | Helmet lamp on/off |
| F3 | Show/hide the debug overlay |
| Esc | Free the mouse; click the window to take it back |

## First-run checklist

These scripts were written and checked with a GDScript parser and linter,
but not yet run in Godot. Please check each item and write down anything that
fails in `docs/playtest-notes.md`:

- [ ] The project imports with no red errors in the Output panel.
- [ ] Pressing F5 starts you in the Cryo Bay, between two rows of pods.
- [ ] Mouse look works and stops at straight up and straight down.
- [ ] WASD moves you; the debug overlay shows about 3.5 m/s walking and
      5.5 m/s sprinting.
- [ ] Crouching lowers the camera and shows about 1.8 m/s.
- [ ] Jumping works; you cannot jump while crouched.
- [ ] The overlay shows "Cryo Bay" in the room and "Spine corridor,
      segment 2" in the corridor.
- [ ] Sprinting raises the zone's noise by 1 every 3 seconds; it then drops
      by 1 every 15 seconds.
- [ ] F toggles the helmet lamp; Esc frees the mouse.

## Changing numbers

Every gameplay number lives in `data/tuning.tres`. Double-click it in the
FileSystem panel and edit the values in the Inspector. No code changes needed.
When a new system needs a number, add it to `scripts/data/tuning.gd` first.

## How the code is organized

| Folder | What lives there |
| --- | --- |
| `autoload/` | `config.gd`, available everywhere as `Config` (`Config.tuning`) |
| `data/` | Data resources: `tuning.tres` now; rooms, items and aliens later |
| `scenes/` | `main.tscn`, plus `player/`, `rooms/` and `ui/` scenes |
| `scripts/core/` | Engine-level helpers, such as the default key bindings |
| `scripts/data/` | Resource classes, such as `Tuning` |
| `scripts/player/` | The character and its input |
| `scripts/world/` | Zones (rooms and corridor segments) |
| `scripts/ui/` | HUD scripts |
| `assets/` | Models, textures, audio; list every outside asset in `CREDITS.md` |
| `docs/` | Playtest notes and design notes |

Three choices here follow the design document's "building it right" rules:

1. **Input is separate from the body.** `PlayerInput` turns the keyboard
   and mouse into an `InputState`; `PlayerCharacter` only reads that
   `InputState`. A network peer or a bot can drive the same character later.
2. **Everything is room-based.** Each room and corridor segment is a `Zone`
   (an `Area3D`) with its own noise meter. Fire, breaches, power and vents
   will attach to zones too.
3. **Numbers live in data.** Speeds, heights and noise timings come from
   `Config.tuning`.

Physics layers are named in Project Settings: 1 world, 2 players, 3 aliens,
4 zones. Players sit on layer 2; zones detect layers 2 and 3.

## Set up Git

Install Git from https://git-scm.com, then run these in this folder:

```
git init
git add .
git commit -m "Week 1: project setup and first-person controller"
```

To back it up, create a **private** repository on GitHub and follow the
"push an existing repository" commands it shows you.

## Next: Week 2

A hitscan pistol, a reusable health component, the navigation mesh, and the
first Crawler that chases you. See the Game Development Plan.
