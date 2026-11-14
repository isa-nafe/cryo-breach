# Checklist: Phases 1 and 2, before Phase 3

Work through this in Godot before starting multiplayer. Phase 3 changes how
every action works, so a bug found now takes minutes to fix and a bug found
with two windows open takes hours.

How to use it: tick each box as you check it. If something fails, write what
you saw under "Problems" at the bottom (or in `docs/playtest-notes.md`) and
send it to Claude. Use the exact words from the Output panel when there is an
error.

Press F5 to run the game: the main menu opens, and **Play solo** starts a match.
To run one scene directly, open it and press F6 (`scenes/match.tscn` is a solo
match; `scenes/main.tscn` is the Phase 1 test scene).

## Keys you need

| Key | What it does |
| --- | --- |
| W A S D, Shift, Ctrl or C, Space | Move, sprint, crouch, jump |
| Mouse, Esc | Look; Esc frees the mouse, click to take it back |
| E (hold) | Use what you are looking at |
| Left / right mouse | Use the item in the main / off hand |
| 1 to 4, X, G | Swap a slot with the main hand (0.75 s), swap hands, drop |
| R (hold) | Reload from an ammo box (restart on the end screen) |
| F | Helmet lamp |
| F3 / F4 | Hide the debug overlay / top-down view of the ship |
| F5 / F6 / F7 | Debug: add a light wound / a serious wound / heal light wounds |
| F8 | Debug: lock the door you are looking at for 60 s |

## 0. Start-up

- [ ] The project opens with no red errors in the Output panel.
- [ ] F5 opens the menu; Play solo starts you in the Cryo Bay, with no errors
      or warnings in the Output panel (a few yellow lines are fine; write them
      down).
- [ ] The debug overlay shows FPS, state, speed, zone, lamp, "Scene  Match
      running", and the clock at the top counts up from 00:00.
- [ ] FPS stays near 60 while you walk through the whole ship.
- [ ] Pressing R on the end screen a few times restarts cleanly each time
      (items, crates, doors and the clock all reset).

## 1. Movement and the debug overlay

- [ ] Mouse look works and stops at straight up and straight down.
- [ ] Walking shows about 3.5 m/s; sprinting about 5.5 m/s; crouching about
      1.8 m/s and the camera drops.
- [ ] Jump works, and you cannot jump while crouched.
- [ ] You cannot stand up under a low gap while crouched (try the doorways).
- [ ] F toggles the helmet lamp; F3 hides and shows the overlay.
- [ ] The Zone line names the room you are in ("Cryo Bay", "Medbay"...) and
      "Corridor N" in corridors.
- [ ] Holding Shift and W for 4 seconds in a row raises the zone's noise by
      1; it drops by 1 about every 15 seconds. Crouch-walking adds nothing.

## 2. The ship (press F4 for the top-down view)

- [ ] F4 shows the whole ship from above with no ceilings and looks like your
      diagram: the Bridge at the left, the tall Cryo Bay in the middle, three
      D-shaped engines in a column at the right. Press F4 again to return.
- [ ] 21 rooms and no overlapping rooms.
- [ ] Engine B has doors to the two rooms beside it and none to the Cryo Bay.
- [ ] Walk every corridor you can: floors are continuous and walls close up at
      every bend (no gaps, no wall across the way).
- [ ] You cannot leave the ship or fall through a floor anywhere.
- [ ] Every room has a floor and ceiling you cannot see through, with no light
      leaking through the walls.
- [ ] Each corridor has a door in the middle of its longest straight piece.
- [ ] *Debug > Visible Navigation* (editor menu, while the game runs): blue
      floor in every room and corridor, joined through every doorway.

## 3. Items and the inventory

You start with the pistol in your main hand. A row of items lies on the floor
of the Cryo Bay near the middle: 2 ammo boxes, a medkit, 3 bandages, a keycard
and a welder.

- [ ] The bottom of the screen shows "Main: Pistol (8)", the off hand and
      slots 1 to 4; "Pistol 8 / 8" is bottom-right.
- [ ] Looking at an item within 2.5 m shows "Take ..."; holding E for 0.5 s
      picks it up. Items go into the free hand first, then slots.
- [ ] Picking up the 3 bandages makes one stack of 3.
- [ ] Press 1: the pistol goes into slot 1 after 0.75 s; press 1 again and it
      comes back with its ammo count unchanged.
- [ ] X swaps the two hands. G drops the main-hand item in front of you and
      you can pick it up again.
- [ ] The power cell (see section 7) fills both hands, cannot be stowed, and
      the prompt says "No room" while another item is in a hand.

## 4. The pistol, wounds and healing

- [ ] Left mouse fires the pistol once per click (flash and sound). Each shot
      adds 2 noise to the zone and the ammo count drops. The shot cannot hurt
      you or pass through closed doors.
- [ ] At 0 rounds the pistol does nothing.
- [ ] Hold R for 2 s with an ammo box in your inventory: the pistol refills
      and one box is used up.
- [ ] F5 three times: the light wounds go 1, 2, then back to 0 with one serious
      wound that has a named effect.
- [ ] Limp: slower, cannot sprint. Shaky aim: shots scatter more. Broken arm:
      the off-hand item is dropped and a two-handed item cannot be held.
- [ ] Medkit: hold left mouse 3 s with light wounds, and they heal and the
      medkit is gone. With no light wounds nothing is used up.
- [ ] Bandage: 3 s, dresses one serious wound (its effect stops).
- [ ] F6 until three serious wounds: the screen shows "You died", the camera
      drops, you cannot move.

## 5. Doors

- [ ] E opens and closes a corridor door instantly with no noise. Open doors
      are see-through and bullets pass; closed doors are not.
- [ ] With the welder in a hand, a closed door shows "[Left mouse] Weld shut";
      holding for 4 s welds it ("Welded shut", E does nothing). Doing it again
      cuts it open.
- [ ] F8 on a door: "Locked (59 s)" counting down; it opens only with the
      keycard in a hand, and unlocks by itself after 60 s.

## 6. Searching and the stations

The Medbay is slot 3 (left of the Cryo Bay, via the room to its lower left),
the Generator is slot 9 (bottom of the ship), the Armory is slot 11 (upper
right of the Cryo Bay). Use F4 to find them.

- [ ] A crate shows "Search"; holding E for 2 s adds 1 noise and shows
      "Found: ..." or "Empty". A searched crate cannot be searched again.
- [ ] Across the ship you find a keycard, medkits, bandages and ammo boxes,
      and many crates are empty (the loot deck is small).
- [ ] Medbay rest bed (8 s): heals light wounds; it refuses when you have none.
- [ ] Medbay surgery pod (12 s, +2 noise): removes one serious wound; it
      refuses when you have none.
- [ ] Armory ammo locker (2 s): refills the pistol in your hand; it works 3
      times, then says "Ammo locker empty".
- [ ] Armory gun rack: gives one pistol, once.
- [ ] Generator: a power cell lies in the middle of the room.
- [ ] Stations and crates are not blocked by walls or props, and you can walk
      around every prop.

## 7. The escape

- [ ] Take the power cell (stow the pistol first with 1) to the Pod Bay (the
      hexagon beside the lowest engine). With the cell in a hand, the socket
      shows "[Left mouse] Insert power cell"; holding 5 s unlocks the pods:
      the message "Escape pods unlocked" appears and the pods turn red to
      green.
- [ ] A pod shows "Pod locked" before that and "Board" after. Holding E for
      2 s seats you.
- [ ] Seated: a short tap of E climbs you out beside the pod; holding E for
      1 s starts a 10 s launch countdown (shown on screen) and adds 5 noise.
- [ ] Holding E again during the countdown aborts it.
- [ ] At zero the end screen shows "You escaped", your time and aliens killed.
      R restarts.
- [ ] Set `jump_time` to 30 in `data/tuning.tres` and run: at 0:30 the screen
      shows "Left behind at the jump". Put it back to 2400 afterwards.

## 8. Aliens

- [ ] After 1:30, a Crawler appears about once a minute in a room without you,
      never more than two at once (wait, or lower `grace_period` to test).
- [ ] A Crawler stands still until it sees you (20 m cone) or hears a shot
      within 10 m. Then it chases at 6 m/s and gives a light wound every
      1.2 s in reach.
- [ ] Two pistol hits kill it. The hit marker flashes on a hit.
- [ ] It opens closed doors by itself and stops at welded or locked ones.
- [ ] It does not walk through walls or get stuck in doorways or at bends.
- [ ] In `scenes/main.tscn` (F6) the Phase 1 test scene still works: the
      target dummy takes 3 hits, and a Crawler walks up to you after 10 s.

## 9. Gate 2: another person

- [ ] A friend plays for 15 minutes with no help from you. Afterwards they can
      say what they were meant to do (find the power cell, reach the pods).
- [ ] Write down what confused them under "Problems" below.

## Problems found

Write each problem as: what you did, what you expected, what happened (and the
Output panel text if there is any).

1.
2.
3.

## Ready for Phase 3 when

- Every box above is ticked, or the unticked ones are written down as known
  problems and you and Claude agree they can wait.
- Nothing in the Output panel is an error.
- The last full run (spawn to escape) worked from start to end.
