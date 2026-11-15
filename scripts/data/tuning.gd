class_name Tuning
extends Resource
## Every gameplay number in Cryo Breach lives in a Tuning resource.
##
## The values used by the game are the ones saved in res://data/tuning.tres.
## Open that file in the Inspector to change them; no code changes needed.
## The defaults below match the Game Design Document and are only used if a
## value is missing from the .tres file.
##
## Rule from the design doc: when a new system needs a number (a timer, a
## speed, a chance, a count), add it here instead of writing it in code.

@export_group("Player movement")
## Normal walking speed, in metres per second.
@export var walk_speed: float = 3.5
## Sprinting speed. Sprinting makes noise.
@export var sprint_speed: float = 5.5
## Crouch-walking speed. Crouch-walking is silent.
@export var crouch_speed: float = 1.8
## Upward speed when jumping, in metres per second.
@export var jump_velocity: float = 4.0
## How fast you reach your target speed on the ground (m/s per second).
@export var ground_acceleration: float = 30.0
## Fraction of ground acceleration available in the air (0 = none, 1 = full).
@export_range(0.0, 1.0) var air_control: float = 0.25
## Radians turned per pixel of mouse movement.
@export var mouse_sensitivity: float = 0.0025
## How far up or down you can look, in degrees.
@export var max_look_pitch_degrees: float = 85.0

@export_group("Player body")
## Height of the collision capsule when standing, in metres.
@export var stand_height: float = 1.8
## Height of the collision capsule when crouching.
@export var crouch_height: float = 1.1
## How fast the body changes height when crouching or standing (m/s).
@export var crouch_transition_speed: float = 6.0
## Distance from the top of the capsule down to the eyes.
@export var eye_offset_from_top: float = 0.15

@export_group("Noise")
## Maximum noise a room or corridor segment can hold.
@export var noise_max: float = 10.0
## Every this many seconds, each zone's noise drops by 1.
@export var noise_drain_interval: float = 15.0
## While sprinting, add noise every this many seconds.
@export var sprint_noise_interval: float = 3.0
## Noise added per sprint interval.
@export var sprint_noise_amount: float = 1.0

@export_group("Weapons")
## How long the muzzle flash light stays on.
@export var muzzle_flash_seconds: float = 0.05
## Length of the generated gunshot sound.
@export var placeholder_shot_seconds: float = 0.12
## Seconds before a destroyed target dummy returns.
@export var dummy_respawn_seconds: float = 3.0

@export_group("Wounds")
## Every this many light wounds become one serious wound.
@export var light_wounds_per_serious: int = 3
## Serious wounds that kill a player.
@export var serious_wounds_to_die: int = 3
## Speed with a Limp (25% slower, no sprint).
@export var limp_speed_multiplier: float = 0.75
## Weapon spread with Shaky aim (50% more).
@export var shaky_aim_spread_multiplier: float = 1.5
## Bleeding gives one light wound every this many seconds.
@export var bleed_interval: float = 60.0
## Camera height above the floor after death.
@export var dead_eye_height: float = 0.3
## How long the hit marker shows.
@export var hit_marker_seconds: float = 0.12

@export_group("Aliens")
## Noise of at least this much in one go counts as loud (a gunshot does, a sprint tick does not).
@export var loud_noise_threshold: float = 2.0
## Seconds between path updates while chasing.
@export var alien_repath_interval: float = 0.25
## How quickly aliens turn to face their direction.
@export var alien_turn_speed: float = 10.0
## Seconds without sight before an alien gives up a chase.
@export var alien_lose_target_seconds: float = 3.0
## Seconds to wait for the navigation bake before spawning aliens anyway.
@export var nav_bake_timeout_seconds: float = 5.0
## Phase 1 only: seconds before the first Crawler.
@export var first_crawler_delay: float = 10.0
## Phase 1 only: seconds between a kill and the next Crawler.
@export var crawler_respawn_delay: float = 8.0

@export_group("Match flow")
## Seconds at the start with no encounters or ship events.
@export var grace_period: float = 90.0
## Seconds into the match when players must commit to an objective.
@export var commit_time: float = 600.0
## Seconds into the match when cryopods unlock.
@export var cryo_unlock_time: float = 1200.0
## Seconds into the match of the "10 minutes to the jump" announcement.
@export var jump_warning_time: float = 1800.0
## Seconds into the match of the final warning and alarm lighting.
@export var final_warning_time: float = 2100.0
## Seconds into the match when the ship jumps to hyperspace.
@export var jump_time: float = 2400.0
## Most players in a match.
@export var max_players: int = 6

@export_group("Debug overview")
## Height of the F4 top-down camera above the floor, in metres.
@export var overview_camera_height: float = 100.0
## How many metres of ship the F4 camera shows from top to bottom.
@export var overview_camera_size: float = 90.0
## Ambient light while the F4 camera is on (fog is switched off), so the ship shows.
@export var overview_ambient_energy: float = 3.0
## Where the F4 camera is along the ship (X), in metres from the Bridge.
@export var overview_camera_x: float = 65.0

@export_group("Interaction")
## How far the player can reach, in metres.
@export var interact_range: float = 2.5
## Extra reach the host allows, to forgive network lag.
@export var interact_range_slack: float = 1.0

@export_group("Inventory")
## Slots besides the two hands.
@export var inventory_slots: int = 4
## Time to move an item between a hand and a slot.
@export var hand_slot_swap_seconds: float = 0.75
## Time to pick an item up.
@export var pickup_seconds: float = 0.5
## Time to reload a gun from an ammo box.
@export var ammo_reload_seconds: float = 2.0
## How far in front of the player a dropped item lands.
@export var drop_distance: float = 1.0
## Edge length of the grey-box item on the floor, in metres.
@export var pickup_size: float = 0.3

@export_group("Doors")
## Time to weld a door or vent shut, or cut it open.
@export var weld_seconds: float = 4.0
## How long a Security terminal lock lasts.
@export var door_lock_seconds: float = 60.0
## How long the door takes to slide.
@export var door_slide_seconds: float = 0.3
## Distance at which an alien deals with a closed door.
@export var alien_door_reach: float = 1.5

@export_group("Stations")
## Time to search a container.
@export var search_seconds: float = 2.0
## Noise added by searching.
@export var search_noise: float = 1.0
## Medbay rest bed: time to heal all light wounds.
@export var rest_bed_seconds: float = 8.0
## Medbay surgery pod: time to remove a serious wound.
@export var surgery_seconds: float = 12.0
## Noise added by surgery.
@export var surgery_noise: float = 2.0
## Armory ammo locker: refills for the whole crew.
@export var armory_refills: int = 3
## Armory ammo locker: time to refill a gun.
@export var ammo_locker_seconds: float = 2.0
## Armory gun rack: time to take the gun.
@export var gun_rack_seconds: float = 0.5
## How long a message such as "Found: Medkit" stays on screen.
@export var message_seconds: float = 2.5

@export_group("Escape")
## Time to put a power cell in the Pod Bay socket.
@export var pod_socket_seconds: float = 5.0
## Time to climb into an escape pod.
@export var pod_board_seconds: float = 2.0
## How long E must be held in a pod to start (or abort) the launch.
@export var pod_launch_hold_seconds: float = 1.0
## Length of the launch countdown.
@export var pod_launch_seconds: float = 10.0
## Noise added when a launch starts.
@export var pod_launch_noise: float = 5.0
## How far from the pod you land when you climb out.
@export var pod_exit_distance: float = 1.5
## Seconds between the death and the end screen.
@export var death_end_delay: float = 1.0
## Phase 2 only: seconds between Crawler spawns after the grace period.
@export var slice_spawn_interval: float = 60.0
## Phase 2 only: most Crawlers alive at once.
@export var slice_max_aliens: int = 2

@export_group("Network")
## The port a host listens on and a client connects to (UDP).
@export var default_port: int = 24565
## Longest player name, in characters.
@export var max_name_length: int = 20
## Width of the menu column, in pixels.
@export var menu_width: float = 360.0
## Space between menu items, in pixels.
@export var menu_spacing: int = 10
## Size of the title text on the menu.
@export var menu_title_size: int = 40
## Furthest the host lets a reported shot origin be from the shooter's head, in metres.
@export var fire_origin_tolerance: float = 1.5
## A client may fire this fraction of a weapon's fire interval early (network jitter).
@export var fire_rate_tolerance: float = 0.8
## Colour of the muzzle flash shown for other players' shots.
@export var shot_effect_color: Color = Color(1, 0.8, 0.4, 1)
## Brightness of the muzzle flash shown for other players' shots.
@export var shot_effect_energy: float = 3.0
## Reach of the muzzle flash shown for other players' shots, in metres.
@export var shot_effect_range: float = 6.0
