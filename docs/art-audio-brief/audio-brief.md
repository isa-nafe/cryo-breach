# Audio brief: sound effects, ambience, music, announcements

For the sound designer. Read `README.md` in this folder first (the game, the
mood, the tools, the file rules, and what the art must not give away).

**Priority:** **P1** = needed soon for the playable build, **P2** = needed for
the full game, **P3** = polish, can be cut. Roughly 250 sounds by release; the
**starter 20** (section 9) comes first.

---

## 1. Sound is gameplay in this game

Noise is the central mechanic: loud actions pull aliens, and players must
learn to play quietly. So:

1. **Loudness has meaning.** A shotgun blast must be clearly louder and more
   "dangerous" than a pistol, a pistol louder than a footstep. Players judge
   how much noise they are making by what they hear.
2. **Some sounds are warnings.** The most important sounds in the game are
   the **vent rattle** (an alien is about to come out), **alien footsteps**
   (an Adult is close), **a door being forced or hammered** (a Breeder is at a
   locked door) and the **alarms**. These must cut through the mix and be easy
   to place in 3D.
3. **Silence is a tool.** Do not fill every moment. Quiet rooms with a low
   hum, drips and creaks are scarier than constant music.
4. **Nothing gives away secrets.** Terminal and system sounds must be the same
   whoever uses them. In particular, **damaging an engine must sound exactly
   like repairing it** (use the same sound set). Scanning and surgery sounds
   must not reveal results.

The audio is mixed on four buses: **Effects**, **Ambient**, **Music**, and
**UI**. Deliver sounds *dry*: no reverb baked in, because the game adds room
reverb itself.

---

## 2. Technical rules

| Rule | Value |
| --- | --- |
| Short effects | WAV, 16-bit, 44.1 kHz |
| Loops, ambience, music | OGG Vorbis, quality 6, seamless loop (no click at the loop point) |
| Sounds that play in the world (3D) | **Mono**. The game positions them. |
| UI, music, stingers, announcements | Stereo |
| Peak level | Short effects peak at -3 dBFS; music at -6 dBFS; leave headroom |
| Loudness | Keep sounds of the same kind at the same perceived level; the owner will balance the mix in-game |
| Variations | Anything that repeats (footsteps, impacts, vent rattles, door sounds, alien calls) needs **3 to 5 variations** so it does not sound mechanical. Name them `_01`, `_02`... |
| Length | Keep effects short and trim silence at the start so they play instantly |
| Names | `sfx_pistol_shot_01.wav`, `amb_room_medbay_loop.ogg` (lowercase, underscores, a number for variations) |
| Folders | `assets/audio/sfx`, `ambient`, `music`, `ui`, `voice` |
| Copyright | Never use sounds from films, TV, other games or music libraries without a CC0 or commercial-use licence; no *Alien* or *Nemesis* sounds. List every outside sound in `assets/CREDITS.md`. |

---

## 3. The player

| Sound | Variations | Notes | Prio |
| --- | --- | --- | --- |
| Footsteps: walk | 4 per surface | Surfaces: **metal floor**, **grate**. Quiet and soft; the player is trying to be silent. | P1 |
| Footsteps: sprint | 4 per surface | Heavier and faster; clearly louder than a walk. | P1 |
| Footsteps: crouch | 3 | Almost silent: a faint soft tap. | P2 |
| Jump and land | 1 + 3 | Land with a thud on metal. | P2 |
| Breathing | 3 loops | Calm, heavy (after sprinting), low air (O2 running out). | P2 |
| Wounded | 3 | A light wound (a grunt) and a serious wound (a cry). Gender-neutral so it fits any player. | P1 |
| Death | 2 | | P1 |
| Knocked down and getting up | 2 | A Breeder hit: a heavy thump, then a scramble. | P2 |
| Helmet lamp click | 2 | On and off. | P1 |
| Pick up, drop, stow, swap | 3 each | A soft shuffle; a short clack for hard items. Heavier for the two-handed items (power cell, rifle). | P1 |
| Inventory / hand swap | 2 | The 0.75 s swap: a soft gear shuffle. | P1 |
| Gear on body | Optional loop | Faint rustle when moving. | P3 |

---

## 4. Weapons and items

| Sound | Variations | Notes | Prio |
| --- | --- | --- | --- |
| Pistol shot | 4 | A sharp crack, medium loudness. | P1 |
| Assault rifle shot | 4 | Short and punchy; it will repeat quickly (about 8 rounds a second), so make it loop-friendly. | P2 |
| Shotgun blast and pump | 3 + 2 | The loudest gun. Deep and heavy. | P2 |
| Dry fire click | 2 | The gun is empty. | P1 |
| Reload | 1 per gun | Pistol, rifle, shotgun: mag out, mag in, slide or pump. About 2 s, matching the reload time. | P1 |
| Hit on alien | 3 | A wet, meaty impact. | P1 |
| Hit on wall or metal | 3 | A ricochet ping. | P1 |
| Melee swings and hits | 3 each | Punch, knife, stun baton (with an electric zap), pipe club, welder-as-weapon. | P2 |
| Stun baton discharge | 2 | A buzzing electric crack. | P2 |
| Grenade | pin pull, throw, bounce (3), **explosion** (3), distant explosion (3) | The explosion is the loudest sound in the game. Pipe bomb: same, rougher. | P2 |
| Fire bomb | ignite whoosh (2) | A burst of flame. | P2 |
| Noisemaker | land clatter, beep loop (15 s, the noise it makes), stop | It must be loud and clear: it is a lure. | P2 |
| Medkit and bandage | 1 each | 3 s of tearing and a soft spray; tape and wrapping. | P1 |
| Handheld scanner | 1 | A short beep sequence. The result must **not** change the sound. | P2 |
| Keycard | swipe, accepted, denied | | P1 |
| Toolkit repair | loop (8 to 15 s) | A ratchet and tinkering loop. **Repair and damage use this same set.** | P2 |
| Welder | start, loop, stop | A hissing flame with sparks; used to weld and cut doors. | P1 |
| Extinguisher | start, loop (10 s), stop | A pressurised spray. | P2 |
| Radio | click on, click off, static burst | | P2 |
| Motion tracker | ping (near, mid, far) | A soft sonar blip; faster and higher when something is close. | P2 |
| O2 mask | on, off, hiss loop | | P2 |
| Flashlight | on and off | | P2 |
| Power cell | pick up, insert (5 s) | A heavy energy hum rising to a clunk when it seats. | P1 |
| Search container | open, rummage (2 s), close | A metal lid, then paper and parts. | P1 |
| Crafting | 8 s loop, finish | Hammering, taping, assembling. | P2 |
| Ammo locker, gun rack | open, take | | P1 |

---

## 5. The ship and its systems

| Sound | Variations | Notes | Prio |
| --- | --- | --- | --- |
| **Door slide** | open (4), close (4) | A pneumatic slide. Doors are silent in the *rules* (opening a door adds no noise), so the sound should be low and short: audible only up close. | P1 |
| Door locked / denied | 2 | A buzz. | P1 |
| Door lock engaged (from Security) | 1 | A heavy bolt. Heard in the room. | P2 |
| Door weld and cut | loop, finish | Same as the welder. | P1 |
| Door forced open (no power) | 2 | A strained, grinding manual push. Loud: it makes noise. | P2 |
| Door hammered (Breeder or Queen) | 4 + a final break | Heavy slams on metal, then a breaking crunch. A warning sound. | P2 |
| **Vent rattle** | 5 | The grate shakes and something moves inside. Eerie and clearly **not** a mechanical sound. The key warning. | **P1** |
| **Alien emerges from a vent** | 3 | Metal scraping and wet movement, a louder version. | P1 |
| Vent crawl | 3 | An alien moving through the vent, heard through the walls. | P2 |
| Terminal select, confirm, cancel, error | 1 each | | P1 |
| Terminal working | loop | A soft processing hum while a timed action runs. | P2 |
| Terminal no power | 1 | A short dying whine. | P2 |
| Hull breach | alarm, door slam (2), air rush loop | A hiss and a roar of escaping air, with a metallic alarm. | P2 |
| Fire | loop (small), loop (big), ignite | Crackle and roar, for burning rooms (it burns 3 minutes). | P2 |
| Hazard alarm (room) | loop | A rhythmic warning for a room on fire or breached. | P2 |
| Malfunction | sparks (3), fizz | Electrical failure. | P2 |
| Power out and power on | 1 each | A power-down whine and a thunk; a power-up surge. | P2 |
| Generator breaker | 2 | A heavy switch. | P2 |
| Cryopod | open, close, freeze (hiss), thaw | The sleep and wake sounds. | P2 |
| Escape pod | boarding hatch, close, countdown beeps (10 s), launch roar, aborted | | P1 |
| Pod power-on | 1 | When the socket receives the power cell. | P1 |
| **Self-destruct** | armed, klaxon loop, minute chime (6 to 1), cancelled | A frightening, urgent sound. | P2 |
| **Hyperspace jump** | build-up (10 s), whoosh, silence | The end of the match. | P2 |
| Ship destroyed | explosion, shockwave, silence | | P2 |
| Alarm: final warning (35:00) | loop | A pulsing alarm, fits the red lighting. | P2 |

---

## 6. Aliens

Every alien needs sounds a player can **locate in 3D** and **identify by ear
alone**, because the Adult in particular cannot see and is found by sound.
Keep each type's voice unique and avoid film-creature sounds.

| Type | Sounds | Notes |
| --- | --- | --- |
| **Larva** | skitter loop, hiss (2), latch squelch, flee shriek | Small, fast, high-pitched. |
| **Crawler** | scuttle loop, screech (3), attack (3), hurt (3), death (2) | Quick and chattering. |
| **Adult** | slow heavy footsteps (4), breathing loop, charge roar, attack (3), hurt (3), death (2), flee | The player must be able to hear it coming from far away. Make the footsteps clearly **heavier and slower** than a human's. |
| **Breeder** | footsteps (4), deep growl, door-slam sequence (see section 5), attack (3), hurt, death | A bigger, deeper Adult. |
| **Queen** | huge footsteps (4), roar (3, one for first sight), ground thump, attack (3), hurt, death | The scariest sound in the game. |
| All types | vent travel, vent emerge (see section 5) | |

Priorities: Crawler **P1**; Larva, Adult, Breeder, Queen **P2**.

---

## 7. Ambience, music and announcements

### Ambient loops (P2)

| Loop | Mood |
| --- | --- |
| Corridor | A low ship hum, distant creaks, drips |
| Cryo Bay | Cold hiss and soft machinery |
| Bridge | Quiet electronics, beeps |
| Engine Rooms | A deep, loud engine rumble; engine A and B slightly different |
| Pod Bay | Hollow, empty, an echoing metallic space |
| Medbay | A soft monitor beep, a clean hum |
| Workshop, Armory, Security, Generator, Storage, Comms, Lab, Fire Control, Air Control | One loop each; keep them distinct but low |
| Power-section hum | Fore, Mid, Aft: the sound of the lights and machines; **it fades out when that section loses power** |
| Outage ambience | Silence with only faint creaks |
| Distant sounds | Single events (a far bang, a far scream, a creak, a vent) for the code to play at random: 10 to 15 |

### Music (P2 to P3)

Sparse. Dread comes from space, not melody.

- **Calm:** an unsettling drone, barely any notes.
- **Tension:** layered on top when aliens are near or noise is high.
- **Danger:** when a player is hunted or wounded.
- **Final:** a driving, urgent layer in the last 5 minutes (from 35:00) and
  during the self-destruct countdown.
- Provide the layers as **stems** (separate files of the same length that play
  together and fade in and out), so the game can mix them.

### Stingers (P2)

Short musical hits for: an alien spotted, a player's death, escaping in a pod,
the ship being lost, a hyperspace jump, an objective being revealed. 2 to 6
seconds each.

### Announcements (P2)

A PA chime, then text on screen (a voice is optional): "10 minutes to the
hyperspace jump", "5 minutes", self-destruct armed, each minute of the
countdown, self-destruct cancelled, pod launch started, hull breach in a
section, fire in a section. If you record voices, use one calm, flat ship-AI
voice; ask the owner for the final line list.

### UI sounds (P2)

Menu hover, click, confirm, back, error; hit marker tick; item pick-up pop;
message pop; objective reveal; commit confirmed; lobby join and leave; match
start; end-screen win and lose.

---

## 8. Voice (P3 for now)

Proximity voice chat between players comes later (after release 1.0): the
game will carry the players' own voices, and it is not made by you. What
**you** would make are the character sounds (pain, effort, death) in section 3
and, optionally, the ship announcements in section 7.

---

## 9. The starter 20 (do these first)

These are the first 20 sounds the game needs to be tested properly:

1. Pistol shot (4 variations)
2. Dry fire click
3. Pistol reload
4. Footsteps, walk, metal (4)
5. Footsteps, sprint, metal (4)
6. Door slide, open and close
7. Door locked buzz
8. Vent rattle (5)
9. Alien emerges from a vent
10. Crawler scuttle loop
11. Crawler screech
12. Hit on alien (3)
13. Wounded grunt (light and serious)
14. Death
15. Pick up and drop (soft and hard)
16. Search container (open, rummage, close)
17. Medkit use
18. Welder (start, loop, stop)
19. Pod power-on, pod boarding, pod countdown beeps, pod launch
20. A corridor ambient loop

Send these to the owner as one batch. They will be put into the game and you
will get feedback on the mix and the balance, before you make more.

---

## 10. Summary of what to deliver

| Category | About |
| --- | --- |
| Player sounds | 30 |
| Weapon and item sounds | 70 |
| Ship and system sounds | 50 |
| Alien sounds | 35 |
| Ambient loops | 25, plus 12 distant-event sounds |
| Music stems and stingers | 8 stems and 8 stingers |
| Announcements and UI | 40 |
| Total | about 250 files |

Do **P1** first and tell the owner when each batch is ready; the game is
tested with every batch.
