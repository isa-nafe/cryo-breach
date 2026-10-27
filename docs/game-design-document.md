# Cryo Breach: Game Design Document

Oct 27, 2026 · @Isa

The rulebook for Cryo Breach: 3-6 crew wake from cryosleep on the cargo ship *Meridian*, the ship is overrun, and each player tries to survive while pursuing a secret objective. Players cannot shoot each other, so betrayal happens through doors, noise, ship systems and explosions. Every number here is a first-pass tuning value; the rules themselves are decided.

## At a glance

These are the rules you chose; every later section expands one of them.

| Topic | Rule |
| --- | --- |
| Players | 3-6, semi-co-op, everyone plays for their own result |
| Match length | 30-45 minutes; the ship jumps to hyperspace at 40:00 |
| Roles | 6 roles that differ only in starting gear |
| Player vs player | Bullets and melee never hurt players; explosions and fire hurt everyone in the room |
| Death | Permanent; the dead spectate |
| Health | No HP: light and serious wounds; 3 serious wounds kill |
| Objectives | Each player gets a crew and a personal objective and must commit to one at 10:00 |
| Traitor | None; everyone plays their own mission |
| Ways out | Escape pods (enough seats for everyone) or cryosleep until the ship arrives |
| Aliens | Pulled at random from a shared pool on each encounter; a blank pull goes back in |
| Pool | Only shrinks: kills remove aliens, aliens that flee go back in |
| Alien types | Larva, Crawler, Adult, Breeder (a stronger Adult), Queen |
| Encounters | Driven by noise; loud rooms pull aliens |
| Infection | Alien hits give hidden contamination cards that do nothing until checked; an infected card kills you only if you go into cryosleep with it |
| Hazards | Fires, malfunctions, power outages, hull breaches |
| Map | Fixed layout; the shuffled rooms' types change each match and stay unknown until visited |
| Map knowledge | Personal only: you see the rooms you have visited |
| What others see | Only your character and a name badge: no role, wounds or contamination |
| Weapons | Few guns, scarce ammo, melee always possible |
| Inventory | 2 hands + 4 slots |
| Crafting | Only at the Workshop's workbench |
| Voice | Proximity voice; a radio item talks ship-wide |
| End | Hyperspace jump at 40:00, or the self-destruct if armed and not cancelled |
| Sabotage | Door control, noise lures, system tampering, pod control, grenades and fire |

## Match flow

A match is one 40-minute clock. Everything that matters happens at fixed minute marks, plus random ship events every 3-5 minutes.

*[Diagram: match timeline · 0:00 to 40:00. See the online version of this doc.]*

1. **0:00 Wake up.** All players start in the Cryo Bay holding their role's gear. Each player privately receives two objectives. Engine state and the ship's course are unknown.
2. **0:00-1:30 Grace period.** No encounters and no ship events, so players can learn the controls and split up.
3. **1:30 The noise director switches on.** From now on, noise can pull aliens (see Noise and encounters).
4. **About 5:00, then every 3-5 minutes: a ship event.** A fire, malfunction, power outage or hull breach in a random place.
5. **10:00 Commit.** Every player must pick one of their two objectives; whoever has not picked gets one at random. The other is discarded.
6. **20:00 Cryopods unlock.** Players may now go into cryosleep. Arming the self-destruct also unlocks them early.
7. **30:00 Jump warning.** Ship-wide announcement: 10 minutes to the hyperspace jump.
8. **35:00 Final warning.** Announcement and alarm lighting.
9. **40:00 Hyperspace jump.** Anyone still awake aboard dies. The game then works out who survived and who met their objective (see Escaping and the end of the match).

**The match can end early** in two ways:

- **The ship is destroyed** by the self-destruct or by integrity reaching 0. Everyone aboard dies, including sleepers; pods already launched are safe.
- **Nobody is left awake aboard** because everyone is dead, asleep or gone in a pod. The game jumps straight to the 40:00 resolution.

Escape pods can launch at any time once they are unlocked (see Escaping and the end of the match).

## The ship

The *Meridian* has 12 rooms on a central spine corridor running from the Bridge at the front to the Pod Bay at the back. Five rooms are fixed and always in the same place; the seven other slots get a different room type every match.

*[Diagram: Meridian layout · 12 rooms, 3 power sections. See the online version of this doc.]*

Every room opens onto the spine corridor, so the corridor is the noisiest, most-travelled place on the ship.

**Fixed rooms**

| Room | Power section | What you do there |
| --- | --- | --- |
| Bridge | Fore | Set the course (Earth, Mars Station or Deep Space; starts at random and unknown until checked). Arm or cancel the self-destruct. Read ship integrity. Holds the one Data Core. |
| Cryo Bay | Fore | Starting room. 6 cryopods, unlocked from 20:00. |
| Engine Room A | Aft | Check, repair or damage engine A. |
| Engine Room B | Aft | Check, repair or damage engine B. Each engine starts working or damaged at random, and at least one starts damaged. |
| Pod Bay | Aft | 3 escape pods with 2 seats each, and the power socket that unlocks them. |

**Shuffled rooms.** Each match fills the 7 slots with the 5 essential rooms plus 2 drawn at random from the 5 optional ones.

| Room | In every match? | What you do there |
| --- | --- | --- |
| Medbay | Yes | Scanner (5 s, unlimited uses): privately checks your contamination cards and throws away the clean ones. Surgery pod (12 s: remove one serious wound *or* remove all contamination cards). Rest bed (8 s: heal all light wounds). |
| Workshop | Yes | The workbench: the only place to craft. |
| Armory | Yes | Ammo locker with 3 refills shared by the whole crew. A rack with one random gun (pistol or shotgun). |
| Security | Yes | Door terminal: lock any door for 60 s (20 s cooldown). Pod terminal: lock one pod for 60 s. |
| Generator | Yes | Breakers to cut or restore power to each section (5 s). Always holds one power cell. |
| Storage | No | 6 search spots instead of the usual 2-3. Holds a second power cell. |
| Comms | No | Ship-wide broadcast microphone. Holds 2 radios. |
| Lab | No | Analyse an Alien Sample (15 s): every weapon deals +25% damage to aliens for the rest of the match. Uses up the sample. |
| Fire Control | No | Put out the fire in any one room from here (60 s cooldown). |
| Air Control | No | Seal a breach in any room from here, or vent a room into space (60 s cooldown; see Sabotage). |

**Knowing the map.** A shuffled room's type is revealed only when you step inside; doors carry no labels. Your map starts with the hull outline and the Cryo Bay, and adds each room when you enter it. Nobody else sees your map, so sharing what you found means telling people, truthfully or not.

**Doors**

| State | How it gets there | Who gets through |
| --- | --- | --- |
| Open or closed | Anyone, instantly, silently | Players and all aliens |
| Locked | Security terminal, 60 s | Players with a keycard; Breeders break it in 5 s; Queens instantly |
| Welded | Welder, 4 s; stays until cut open with a welder (4 s) | Breeders break it in 10 s; Queens in 3 s |

**Vents** are for aliens only. Every room and corridor segment has one vent, and aliens crawl to a neighbouring room or segment in 5 s, ignoring doors. A welder seals a vent in 4 s; Larvae, Crawlers and Adults can no longer use it, Breeders and Queens break through in 10 s.

**Corridor.** The spine corridor is split into 5 segments between the room columns. Segments count as places for noise and encounters, but fires and breaches only happen in rooms.

**Power sections.** Fore (Bridge, Cryo Bay, slots 1-3), Mid (slots 4-7) and Aft (both engines, Pod Bay). In a section without power the lights go out (helmet lamps only), terminals stop working, every lock in that section releases, and doors must be forced open by hand (3 s, noisy). Cryopods and escape pods run on emergency power and keep working.

## Players

Roles differ only in starting gear; once the match starts, anyone can use any item.

**Roles.** Each role can be taken by one player per match, first come first served in the lobby.

| Role | Starting gear | What the gear pulls you toward |
| --- | --- | --- |
| Captain | Pistol (8 rounds), Keycard, Radio | Opening locked doors, coordinating the crew |
| Soldier | Assault rifle (20 rounds, two-handed), Knife, Grenade | Fighting; the grenade is the crew's most dangerous item |
| Mechanic | Toolkit, Welder, O2 mask | Repairing engines and rooms, sealing breaches and vents |
| Medic | Medkit ×2, Bandage ×2, Handheld scanner (2 charges) | Keeping people alive, checking for infection |
| Scout | Motion tracker, Noisemaker ×2, Knife | Finding rooms first, luring aliens away (or toward others) |
| Scientist | Stun baton, Chemicals ×2, Rag | Crafting at the Workshop; carries the parts for a fire bomb |

Everyone also has a dim helmet lamp and can punch (5 damage), so melee is always possible.

**Inventory: 2 hands + 4 slots**

- Only items in your hands can be used. Moving an item between a hand and a slot takes 0.75 s.
- Two-handed items (assault rifle, shotgun, extinguisher, power cell) fill both hands.
- Small items stack up to 3 in one slot: ammo, bandages, chemicals, rags, duct tape, batteries, noisemakers.
- Dropping is instant; picking up takes 0.5 s.
- To give an item, offer it to a player within 2 m; they must accept. Items can never be taken from a living player.
- A dead player's body keeps all their items and can be searched like a container.

**Wounds and death (no HP)**

- **Light wound.** Every third light wound becomes a serious wound, and the light count resets to 0.
- **Serious wound.** Each one gives a random effect: *Limp* (25% slower, no sprint), *Shaky aim* (50% more weapon spread), *Broken arm* (one hand unusable, so no two-handed items) or *Bleeding* (one light wound every 60 s).
- **Death.** The third serious wound kills. The dead spectate and can only talk to other dead, sleeping or escaped players.
- **Disconnecting.** A disconnected player's character stays where it was and can still be hurt by aliens and hazards. Reconnecting within 5 minutes puts you back in control. After 5 minutes the character dies, and its body keeps all its items. Sleepers and players in a launched pod are unaffected.
- You see your own wounds and contamination cards on the HUD. Other players see only your character and a name badge when they look at you within 10 m: no role, no wounds, no contamination.

| Treatment | Time | Effect |
| --- | --- | --- |
| Medkit (item) | 3 s | Heals all light wounds |
| Bandage (item) | 3 s | Dresses one serious wound: its effect stops, but it still counts toward death |
| Medbay rest bed | 8 s | Heals all light wounds |
| Medbay surgery pod | 12 s | Removes one serious wound completely (noisy) |

**What can hurt a player**

| Source | Effect |
| --- | --- |
| Another player's bullets or melee | Nothing: they pass through players |
| Larva | Latches on for 3 s: no wound, but 2 contamination cards |
| Crawler | 1 light wound per hit |
| Adult | 1 serious wound per hit |
| Breeder | 1 serious wound per hit and a 1.5 s knockdown |
| Queen | 2 serious wounds per hit |
| Grenade or pipe bomb | 1 serious wound to every player in the room, including the thrower |
| Burning room | 1 light wound every 4 s inside |
| No air (hull breach) | After 10 s, 1 light wound every 3 s; an O2 mask gives 60 s of air |
| Room vented into space | 1 serious wound unless wearing an O2 mask |

## Objectives

You win if you survive **and** meet the objective you committed to; several players can win, or none. Surviving means being alive at the end, either in a launched pod or in cryosleep (without an infected card) on a ship that arrives safely.

**How objectives work**

1. At 0:00 every player privately gets one crew objective and one personal objective, with no repeats across the table.
2. Objectives that name a role pick a different role that is in this match.
3. At 10:00 you commit to one; the other is discarded. If you don't choose, the game picks one at random.
4. Your objective stays on your HUD. Nobody else ever sees it until the end screen, which reveals every objective and who met it.
5. Kills count for whoever dealt the last damage, including from a grenade or a fire they started.

**Crew objectives** (lean toward helping others)

| Name | Survive, and... |
| --- | --- |
| Strength in numbers | at least 2 other players also survive |
| Bring her home | the ship arrives at Earth: both engines working, course set to Earth, ship not destroyed |
| Pest control | the crew kills at least 5 aliens in total (4 with 3 players) |
| Save the ship | the ship is not destroyed |
| Clean bill of health | no sleeper dies of infection |
| Bodyguard | the named role also survives |
| Sleep together | you survive in cryosleep along with at least one other sleeper |
| Full house | at least one pod launched, and every pod that launched carried 2 players |

**Personal objectives** (lean toward yourself)

| Name | Survive, and... |
| --- | --- |
| Alone in the dark | you escape in a pod with nobody else in it |
| Grudge | the named role does not survive |
| Corporate secrets | you carry the Data Core (one exists, on the Bridge) |
| Specimen | you carry an Alien Sample (dropped by a killed Adult, Breeder or Queen) |
| Exclusive | at most 2 players survive in total, you included |
| Hunter | you personally killed at least 3 aliens |
| Early exit | your pod launched before 30:00 |
| Cold storage | you are the only surviving sleeper |
| Quarantine | the ship's course is anything but Earth at the jump, so the aliens aboard never reach Earth. Sleepers cannot survive that, so this mission needs a pod. |

Some combinations can make two players' goals impossible to meet together. That is deliberate: it is where the semi-co-op tension comes from.

## Aliens

Every alien on the ship lives in one hidden pool held by the host. Encounters pull from it at random, kills shrink it, and nothing ever adds to it.

**Pool rules**

1. The pool holds one token per alien plus one **Blank**.
2. On an encounter (see Noise and encounters), the host pulls one token at random.
3. **Alien token:** that alien crawls out of the nearest vent and is now active on the ship.
4. **Blank:** the vent rattles but nothing comes out. The Blank goes straight back into the pool.
5. **Killed:** the alien is gone for good, so the pool is one smaller.
6. **Fled:** an alien that escapes into a vent goes back into the pool, fully healed.
7. **Ship clear:** if only the Blank is left, every pull is blank and no more aliens come.
8. **Active cap:** at most one active alien per living, awake player (minimum 2). An encounter at the cap pulls nothing; instead the nearest active alien heads to that place.

**Starting pool by player count**

| Players | Larva | Crawler | Adult | Breeder | Queen | Blank | Total |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3 | 3 | 3 | 3 | 1 | 1 | 1 | 12 |
| 4 | 4 | 4 | 3 | 1 | 1 | 1 | 14 |
| 5 | 4 | 4 | 4 | 2 | 1 | 1 | 16 |
| 6 | 5 | 5 | 4 | 2 | 1 | 1 | 18 |

**Alien types**

For reference, players walk at 3.5 m/s, sprint at 5.5 m/s and crouch-walk silently at 1.8 m/s.

| Alien | Health | Speed (m/s) | Senses | Attack | Contamination | Doors | Flees |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Larva | 10 | 5 | Sight, 8 m | Latches on for 3 s, then flees | 2 cards per latch | Opens closed doors | Always, after latching |
| Crawler | 30 | 6 | Sight, 20 m cone; hears loud noise within 10 m | 1 light wound every 1.2 s | None | Opens closed doors | Never |
| Adult | 80 | 3, charges at 6 toward noise within 6 m | Hearing only, 20 m; cannot see | 1 serious wound every 2 s | 1 card per wound | Opens closed doors | 50% chance below 30% health |
| Breeder | 150 | 3.5 | Sight and hearing, 15 m | 1 serious wound and knockdown every 2.5 s | 1 card per wound | Breaks locks in 5 s, welds in 10 s | 50% chance below 30% health |
| Queen | 400 | 4 | Sight and hearing, 25 m | 2 serious wounds every 3 s | 1 card per wound | Breaks locks instantly, welds in 3 s | Always tries below 25% health |

**Behaviour.** An active alien that senses a player chases them. Otherwise it heads for the loudest place within two rooms, and if all is quiet it wanders through vents. Aliens avoid burning rooms and take 10 damage per second inside one. A killed Adult, Breeder or Queen drops one Alien Sample.

**Design notes.** The Adult cannot see, so a player who stands still or crouch-walks can slip past it. A Crawler outruns a sprinting player, so closing a door behind you matters. A Larva barely hurts, but it is the main source of infection and it keeps returning to the pool unless someone kills it.

## Noise and encounters

Every room and corridor segment has a hidden noise meter from 0 to 10. Loud actions fill it, time drains it, and a loud place is where aliens come out.

**Noise per action**

| Action | Noise added to the place you are in |
| --- | --- |
| Walking, crouch-walking, opening or closing a door | 0 |
| Sprinting | +1 every 3 s |
| Talking on proximity voice | +1 every 5 s of speech |
| Sending a radio message | +1 per message |
| Searching a container, melee hit | +1 |
| Forcing an unpowered door | +2 |
| Repairing, surgery, crafting | +2 |
| Pistol shot | +2 |
| Assault rifle | +1 per round |
| Shotgun shot | +4 |
| Explosion | +6 |
| Noisemaker | +3 every 5 s for 15 s, in the place it lands |
| Pod launch sequence | +5 |
| Room alarm during a fire or breach | +1 every 10 s |

Each meter drains by 1 every 15 s.

**What triggers an encounter**

1. **Threshold.** A place that reaches 10 triggers an encounter at once.
2. **Rolls.** Every 30 s, each place with an awake player in it rolls: the chance is 4% per point of noise (5 noise = 20%, 0 noise = never).
3. After an encounter, that place's meter drops to 3 and it cannot trigger again for 45 s. The whole ship has at most one encounter every 20 s.

**Resolving an encounter**

- If the active cap is reached, nothing is pulled; the nearest active alien heads to that place.
- Otherwise the host pulls a token from the pool. An alien climbs out of that place's vent. A Blank makes the vent rattle, halves the meter and goes back into the pool.
- Separately, active aliens react to individual sounds within their hearing range (see Aliens), so a gunshot near a hunting Adult brings it straight to you.

*[Diagram: one encounter · from noise to a pulled alien. See the online version of this doc.]*

Only a kill shrinks the pool; an alien that flees and the Blank both go back in.

## Infection

Infection is invisible and does nothing during the match. It only matters if you go into cryosleep carrying it.

- **Contamination cards.** A Larva latch gives you 2 cards; each wound from an Adult, Breeder or Queen gives 1; Crawlers give none. Cards come from a hidden deck of 24, of which 9 are infected, and discarded cards are shuffled back in.
- **No effect.** A card does nothing to you: no symptoms, no penalty, no sound. Your HUD shows only how many unchecked cards you hold, and nobody else can see them.
- **Checking.** The Medbay scanner (5 s, unlimited) or a handheld scanner (one charge) checks all your cards at once. Clean cards are thrown away; infected cards stay, now marked as infected. Only you see the result.
- **Removing.** The Medbay surgery pod removes all your contamination cards, checked or not, in 12 s and causes 1 light wound. Surgery is the only cure.
- **The cost.** When the match resolves, every sleeper's cards are revealed. A sleeper holding one infected card, checked or not, dies. Pod escapees are never checked.

## Ship systems and hazards

The ship decays on its own: a random event hits about every 3-5 minutes from 5:00, and players must keep up with repairs while chasing their objectives.

**Random events.** Fire 30%, malfunction 30%, power outage 20%, hull breach 20%. Each hits a random room, or a random section for an outage.

| Hazard | What it does | How to fix it | Cost to integrity |
| --- | --- | --- | --- |
| Fire | 1 light wound every 4 s to players inside; aliens take 10 damage per second and avoid the room. Every 30 s, 30% chance to spread to each neighbouring room whose door is open. Burns out after 3 minutes and leaves the room malfunctioning. | Extinguisher (10 s, 3 uses each) or Fire Control | −1 per minute per burning room |
| Malfunction | The room's function stops (see below) | Toolkit, 8 s, noisy | None |
| Power outage | One section goes dark (see The ship) | Generator breaker, 5 s | None |
| Hull breach | The room's doors slam shut and the air drains: after 10 s inside, 1 light wound every 3 s without an O2 mask | Welder (6 s) or Air Control | −2 per minute per open breach |

Fires also start from fire bombs, and an explosion has a 25% chance to set its room alight.

**What a malfunction breaks.** Terminals and stations in that room stop working. Two cases matter most: a malfunctioning engine room counts as a damaged engine, and a malfunctioning Cryo Bay accepts no new sleepers and kills everyone sleeping in it if it is still broken at the jump. A malfunctioning Pod Bay cannot launch pods.

**Integrity.** The ship starts at 100. Each explosion costs 1 more. Below 25 the self-destruct arms itself; at 0 the ship is destroyed. Only the Bridge shows the number.

**Engines.** Checking an engine at its terminal takes 2 s and only you see the result. Repairing takes a toolkit, 15 s and makes noise. Damaging it takes a toolkit, 10 s and looks and sounds exactly like repairing.

**Navigation.** Setting the course on the Bridge takes 5 s: Earth, Mars Station or Deep Space. The starting course is random, only the person at the console sees the current one, and the last setting before the jump counts.

**Self-destruct**

- **Arm:** at the Bridge, 10 s hold, needs a Keycard. It also arms itself when integrity drops below 25.
- **Countdown:** 6 minutes, with a ship-wide announcement every minute.
- **Side effect:** arming unlocks all escape pods and cryopods at once, and they stay unlocked.
- **Cancel:** at the Bridge, 10 s hold, no keycard needed, until 1:00 is left. After that it cannot be stopped.
- **Detonation:** the ship is destroyed. If the countdown is still running at the 40:00 jump, the ship is destroyed during the jump.
- After a cancel, it cannot be armed again for 2 minutes.

## Items, weapons and crafting

There is never enough of anything. Guns are few, an ammo box is one reload, and most useful tools have to be found, traded for or crafted.

**Weapons**

| Weapon | Hands | Damage to aliens | Capacity | Noise |
| --- | --- | --- | --- | --- |
| Punch | 1 | 5 | Unlimited | +1 per hit |
| Knife | 1 | 15 | Unlimited | +1 per hit |
| Stun baton | 1 | 5, and stuns for 3 s (not the Queen) | 6 charges | +1 per hit |
| Welder | 1 | 20 | Unlimited | +1 per hit |
| Pipe club (crafted) | 1 | 25 | Unlimited | +1 per hit |
| Pistol | 1 | 20 per shot | 8 rounds | +2 per shot |
| Assault rifle | 2 | 12 per round, automatic | 20 rounds | +1 per round |
| Shotgun | 2 | 8 pellets of 8 (up to 64 up close) | 4 shells | +4 per shot |
| Grenade or pipe bomb | Thrown | 120 to every alien in the room; 1 serious wound to every player in it | Single use | +6 |
| Fire bomb (crafted) | Thrown | Sets the room on fire | Single use | +3 |

An **ammo box** fully reloads one pistol, rifle or shotgun in 2 s. The Armory locker holds 3 reloads for the whole crew.

**Other items**

| Item | Hands | Use |
| --- | --- | --- |
| Medkit | 1 | Heals all light wounds, 3 s |
| Bandage | 1 | Dresses one serious wound, 3 s |
| Handheld scanner | 1 | Checks your own contamination cards; one charge per use |
| Keycard | 1 | Opens locked doors; needed to arm the self-destruct; never used up |
| Toolkit | 1 | Repairs malfunctions; repairs or damages engines |
| Welder | 1 | Welds and cuts doors and vents, seals breaches |
| Extinguisher | 2 | Puts out a room's fire in 10 s; 3 uses |
| O2 mask | Any slot | 60 s of air; refills when you are back in air |
| Radio | 1 | Push-to-talk to every other radio holder |
| Motion tracker | 1 | Shows anything moving within 15 m, aliens and players alike; 3 minutes of use per battery |
| Flashlight | 1 | Much brighter than the helmet lamp |
| Noisemaker | Thrown | A lure (see Noise and encounters) |
| Power cell | 2 | Unlocks the escape pods when put in the Pod Bay socket |
| Data Core, Alien Sample | 1 | Objective items; the sample can also be analysed in the Lab |
| Chemicals, Rag, Duct tape, Pipe, Battery | 1 | Crafting parts. A battery also recharges a motion tracker or stun baton anywhere, instantly. |

**Crafting.** Only at the Workshop workbench, 8 s per recipe, +2 noise. Both ingredients must be in your inventory.

| Ingredients | Result |
| --- | --- |
| Chemicals + Rag | Fire bomb |
| Chemicals + Pipe | Pipe bomb (works like a grenade) |
| Battery + Duct tape | Noisemaker |
| Pipe + Duct tape | Pipe club |
| Rag + Duct tape | Bandage |
| Battery + Handheld scanner | Scanner with 2 more charges |

**Searching.** Shuffled rooms have 2-3 containers (Storage has 6); fixed rooms and corridor segments have 1 each. Each search takes 2 s, makes 1 noise and draws one card from a shared loot deck. Containers beyond the deck are empty.

| Loot card | 3 players | 4-5 players | 6 players |
| --- | --- | --- | --- |
| Ammo box | 4 | 4 | 5 |
| Medkit | 2 | 2 | 2 |
| Bandage | 2 | 2 | 3 |
| Chemicals | 2 | 2 | 3 |
| Rag | 1 | 2 | 2 |
| Duct tape | 2 | 3 | 3 |
| Pipe | 1 | 2 | 2 |
| Battery | 2 | 2 | 3 |
| Grenade | 1 | 1 | 1 |
| Keycard | 1 | 1 | 1 |
| Toolkit | 1 | 1 | 1 |
| Extinguisher | 1 | 2 | 2 |
| O2 mask | 1 | 1 | 1 |
| Flashlight | 1 | 1 | 1 |
| **Total** | **22** | **26** | **30** |

If the Captain or the Mechanic is not in the match, their Keycard or Toolkit is added to the loot deck, so those key tools always exist. If the Comms room is not drawn, one Radio is added too, so the Captain's radio has someone to talk to.

## Sabotage and communication

Players cannot shoot each other, so conflict runs through the ship itself. Every tool below has a counter, and terminals never show who used them.

**Sabotage tools**

| Tool | How | Counter |
| --- | --- | --- |
| Lock a door | Security terminal, lasts 60 s, 20 s cooldown | A Keycard; cutting that section's power releases its locks; wait it out |
| Weld a door or vent | Welder, 4 s | Another welder cuts it open in 4 s |
| Lure aliens | Throw a noisemaker, or make noise near someone | Move away quietly; kill the alien |
| Cut power to a section | Generator breaker, 5 s | Restore it at the same breaker |
| Damage an engine | Toolkit, 10 s; looks like a repair | Check the engine again and repair it |
| Change the course | Bridge, 5 s | Check the course again before the jump |
| Arm the self-destruct | Bridge, 10 s, needs a Keycard | Cancel it at the Bridge before 1:00 is left |
| Lock a pod | Security terminal, lasts 60 s | Wait it out |
| Launch a pod early | Any seated player starts the 10 s launch, leaving behind anyone not seated | Anyone seated in that pod can hold to abort during the 10 s |
| Vent a room | Air Control: the room opens to space for 15 s, then reseals | An O2 mask; aliens inside take 60 damage and flee, players without a mask take 1 serious wound |
| Explosives and fire | A grenade, pipe bomb or fire bomb thrown into a room with players in it | Stay out of rooms where someone is fighting |
| Information | Lie about your map, scan results, objective or what you found | Check for yourself |

**Talking**

- **Proximity voice:** heard within 15 m, muffled to 7 m through a closed door. Talking adds noise (see Noise and encounters).
- **Radio:** push-to-talk to everyone carrying a radio anywhere in their inventory. Each message adds 1 noise where you are.
- **Comms broadcast** (if the Comms room is in the match): everyone on the ship hears you; adds 2 noise.
- **No text chat** for living players.
- **The dead, sleeping and escaped** share a separate voice channel that the living never hear.
- **Crew count:** the Bridge status panel shows how many crew are still alive and awake, without names.

## Escaping and the end of the match

There are two ways out. A pod is a sure escape if you can reach and launch it. Cryosleep is a bet that the crew left behind will leave the ship in good order.

**Escape pods**

- 3 pods with 2 seats each, all in the Pod Bay.
- **Locked at the start.** Carry a power cell (two-handed) to the Pod Bay socket and insert it (5 s), or arm the self-destruct. Once unlocked, the pods stay unlocked.
- **Boarding** takes 2 s, and you can get out any time before launch.
- **Launching:** a seated player holds to start a 10 s launch sequence (+5 noise). Anyone seated in that pod can abort it. A malfunctioning Pod Bay cannot launch.
- Aliens cannot get into a pod, but one in the Pod Bay can still attack people boarding.
- Players in a launched pod are out of danger and spectate; they survive no matter what happens to the ship and are never checked for infection.

**Cryosleep**

- 6 cryopods in the Cryo Bay, unlocked from 20:00 or as soon as the self-destruct is armed.
- Getting in takes 5 s and cannot be undone. Sleepers spectate and cannot be harmed during the match.
- Whether sleepers live is decided only at the jump.

**Resolving the match** (at 40:00, or as soon as the match ends early)

1. Everyone still awake aboard dies.
2. If the self-destruct is running or integrity is 0, the ship is destroyed and every sleeper dies.
3. If either engine is damaged, or the course is not Earth, the ship is lost and every sleeper dies.
4. If the Cryo Bay has an alien in it, is on fire or is malfunctioning, every sleeper dies.
5. Every sleeper's contamination cards are revealed, and a sleeper holding an infected card dies. Pod escapees are not checked.
6. Each survivor's committed objective is checked, and the end screen shows everyone's objective, fate and result.

*[Diagram: end-of-match resolution · who survives. See the online version of this doc.]*

## Tuning values and open questions

The rules above are fixed; the numbers will change after playtests. Below are the calls I made where you didn't specify. Change any of them now, before code depends on them.

**Decisions made on your behalf**

| Decision | Why | Alternative |
| --- | --- | --- |
| Jump at 40:00 after a 1:30 grace period | Fits your 30-45 minute target | 35:00 for shorter matches |
| Cryopods unlock at 20:00 | Stops players hiding in cryo in the first minute | Unlocked from the start |
| One Blank in the pool | You described a single blank pull | More Blanks make a calmer game |
| Contamination deck of 24 cards, 9 infected; a Larva gives 2 cards, other wounds 1 | About a third of cards are infected, so every unchecked card is a real gamble | More or fewer infected cards |
| Pod escapees are never checked for infection | You described the check as happening in cryosleep | Check pod escapees too, as the board game does |
| Surgery is the only cure; the Antiviral recipe is gone | You named surgery as the way to remove infection | Keep the Antiviral as a rarer second cure |
| Scanners only check yourself | Keeps infection fully private | A handheld scanner can check another player |
| Name badges show when you look at a player within 10 m | You asked for a name badge and nothing else | Always visible at any range |
| A Larva always flees after latching | Keeps it cycling back into the pool, so contamination stays a threat | It stays and fights |
| Objectives target roles, not player names | Roles are fixed per match and shown in the lobby, though never above heads in the game | Target a random player |
| Door locks last 60 s | Stops one player trapping another for the whole match | Locks last until undone |
| Grenades wound the thrower too | Makes using explosives a real decision | The thrower is safe |
| A power cell unlocks the pods | Gives the endgame a two-handed carry mission | Pods are always unlocked |
| Two engines, at least one starting damaged | Guarantees repair work for sleepers | One engine, or three like the board game |
| Course options Earth, Mars Station, Deep Space | Only Earth keeps sleepers alive, and the Quarantine mission wants anything else, so the course is contested | Earth only |
| Bridge shows how many crew are alive | Gives some information without breaking the personal map | No crew count at all |

**Building it right from the start.** These rules shape the code, so set the project up this way from day one:

1. **Every number lives in data, not code.** Keep a tuning resource (for example `res://data/tuning.tres`) and read every timer, speed, chance and count from it.
2. **Content is data.** Rooms, items, recipes, alien types, objectives and the loot deck are each Godot `Resource` files, so a new item or objective needs no new code.
3. **The host keeps all secrets.** The pool, loot deck, infection, objectives, engine states, course and noise meters exist only on the host. Clients get only what their own character can see.
4. **Everything is room-based.** Each room and corridor segment is an `Area3D` zone with its own noise meter, fire state, breach state, power section and vent. Explosions, fire damage and venting hit everything inside a zone.
