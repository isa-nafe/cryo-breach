# Phase 6: polish and release

Goal: something that can be handed to strangers. No new rules. Read *Art
and audio pipeline* in `docs/development-plan.md` first. These
milestones are larger and looser than earlier ones; split each into
one-sitting pieces when you start it, and write the pieces into this
file.

---

## M6.1 Menus, settings, saved options

- **Main menu:** Play solo, Host, Join, Settings, Quit. Remember the last
  name and address.
- **Pause menu** (Esc in a match): Resume, Settings, Leave match. The
  game does not pause in multiplayer; solo may pause.
- **Settings:** mouse sensitivity, field of view, master / effects /
  music volume, fullscreen, key rebinding for every action in
  `input_setup.gd`.
- **Saving:** a `ConfigFile` at `user://settings.cfg`, loaded by `Config`
  at start. Player settings are **not** tuning: move `mouse_sensitivity`
  out of `Tuning` into the settings file with the tuning value as the
  default.

```gdscript
# Saving and loading options with ConfigFile.


func save_settings(sensitivity: float, fov: float) -> void:
	var file := ConfigFile.new()
	file.set_value("controls", "mouse_sensitivity", sensitivity)
	file.set_value("video", "fov", fov)
	file.save("user://settings.cfg")


func load_sensitivity(default_value: float) -> float:
	var file := ConfigFile.new()
	if file.load("user://settings.cfg") != OK:
		return default_value
	return file.get_value("controls", "mouse_sensitivity", default_value)
```

- **Remove debug keys** (wound keys, spawn keys, hazard keys) or put them
  behind `OS.is_debug_build()`.
- **How to play:** one screen with the controls and the five things a new
  player must know (noise, wounds, doors, pods, objectives).

Owner checks: settings survive a restart; rebinding works; a release
export has no debug keys.

---

## M6.2 Art pass with a modular kit

- Write `docs/style-guide.md` from the development plan's four style
  rules.
- Pick one CC0 sci-fi kit (Kenney or Quaternius; check the licence file
  in the download) and list it in `assets/CREDITS.md` the day it is
  added.
- Replace `ShipBuilder._box` walls with kit pieces: keep the collision
  boxes exactly as they are and swap only the visuals (one
  `MeshInstance3D` per wall panel on the kit's grid). Collision and
  navigation must not change, so gameplay stays tested.
- Replace station boxes with kit props; give each room type one clear
  landmark so it reads from the doorway.
- Aliens: original low-poly models (under 2,000 triangles), each with a
  distinct silhouette. Do not imitate Nemesis intruders or film
  creatures. Placeholder boxes are acceptable for 1.0 if the silhouettes
  differ.
- First-person hands and held items; simple third-person crew model with
  walk and crouch animation (Mixamo).
- Lighting: dark ship, small pools of coloured light per room type,
  volumetric fog if the frame rate allows.

Owner checks: every room is recognisable from its doorway; nothing
changed in how the game plays.

---

## M6.3 Sound pass

- Replace every `PlaceholderSounds` call with CC0 files (Kenney audio,
  Freesound CC0 only); list each in `assets/CREDITS.md`.
- Audio buses: Master, Effects, Music, Voice (for later).
- Priority sounds, in order: alien footsteps and vent rattles (they are
  gameplay information), gunshots, doors, alarms, announcements, wounds.
- A sparse ambient drone; silence is part of the mood.
- Announcements as text plus a tone are enough; recorded voice lines are
  optional.

---

## M6.4 Performance and export builds

- Target 60 fps on the owner's machine with 6 players and the alien cap.
  Measure with the built-in profiler (*Debugger > Profiler*) before
  changing anything.
- Usual fixes, in order: fewer shadow-casting lights (only the helmet
  lamp and one light per room), merge static wall meshes, bake lighting
  for static geometry, lower the navigation re-path rate.
- Export presets for Windows and Linux (*Project > Export*; needs the
  export templates installed once). Put builds in `/builds` (already in
  `.gitignore`).
- Test a release build over the internet with port forwarding (UDP
  24565) before giving it to anyone.
- Final pass over `docs/later.md`: decide what is 1.0 and what is not.
  Reconnecting mid-match (M3.5) and hiding the room assignment from
  clients (M4.5) are the two known gaps to decide on.

---

## After 1.0 (not planned in detail)

From the development plan's cut line: voice chat (proximity, radio,
Comms broadcast, the noise it makes, the dead channel), online
matchmaking or a relay so players do not need port forwarding, more
maps, cosmetics.
