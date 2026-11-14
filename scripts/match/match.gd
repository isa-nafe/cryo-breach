extends Node3D
## The game world for one match. Builds the level, adds the player and the
## HUDs, then starts the clock.
##
## The ship is generated from data by ShipBuilder. Phase 2 uses a fixed room
## assignment (all 21 rooms open); M4.5 shuffles the rooms.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/debug_hud.tscn")

## Phase 2 rooms for some shuffled slots (the rest are Crew Quarters). M4.5
## replaces this with a random shuffle of every room type.
const PHASE2_ROOMS := {
	&"slot_3": &"medbay",
	&"slot_9": &"generator",
	&"slot_11": &"armory",
}

## The scenes aliens are made from, by alien id.
const ALIEN_SCENES := {&"crawler": preload("res://scenes/aliens/crawler.tscn")}
const END_SCREEN_SCENE := preload("res://scenes/ui/end_screen.tscn")

## Aliens the crew has killed this match.
var crew_kills: int = 0

## What the match is doing, shown on the debug overlay.
var status: String = "Match running"

@onready var _players: Node3D = $Players
@onready var _aliens: Node3D = $Aliens
@onready var _navigation: NavBaker = $Navigation
@onready var _ship: ShipBuilder = $Navigation/Ship


func _ready() -> void:
	GameState.reset()
	_ship.build(_make_assignment())
	_navigation.bake()
	var spawn_points: Node3D = _ship.furnishings[&"cryo_bay"].get_node("SpawnPoints")
	var player: PlayerCharacter = PLAYER_SCENE.instantiate()
	player.position = (spawn_points.get_child(0) as Marker3D).global_position
	_players.add_child(player)
	TestKit.give(player)
	var bay_zone: Zone = _ship.room_zones[&"cryo_bay"]
	var bay := bay_zone.global_position
	TestKit.scatter(get_tree(), Vector3(bay.x, 0.0, bay.z))
	# The HUDs need the player to exist, so they are added after it.
	for scene: PackedScene in [HUD_SCENE, DEBUG_HUD_SCENE]:
		var hud := scene.instantiate()
		hud.player_path = player.get_path()
		add_child(hud)
	GameState.loot_deck.setup(load("res://data/loot_table.tres") as LootTable, 1)
	_place_power_cell()
	player.died.connect(_on_player_died)
	GameState.match_ended.connect(_on_match_ended)
	var director := TimerDirector.new()
	director.setup(spawn_alien)
	add_child(director)
	GameState.start_match()


## The Generator always holds one power cell (GDD "Generator").
func _place_power_cell() -> void:
	var generator: Node3D = _ship.furnishings.get(&"generator")
	if generator == null:
		return
	var spawn: Marker3D = generator.get_node("PowerCellSpawn")
	var stack := ItemStack.create(Config.get_item(&"power_cell"))
	Pickup.spawn(get_tree(), stack, spawn.global_position)


## Makes an alien and puts it in the world. Host only. The noise director
## (M4.1) uses this too.
func spawn_alien(alien_id: StringName, at: Vector3) -> Alien:
	var scene: PackedScene = ALIEN_SCENES.get(alien_id)
	if scene == null:
		push_warning("No scene for alien type %s" % alien_id)
		return null
	var alien: Alien = scene.instantiate()
	alien.position = at
	_aliens.add_child(alien)
	alien.died.connect(_on_alien_died)
	return alien


func _on_alien_died(_alien: Alien, _killer: Node) -> void:
	crew_kills += 1


func _on_player_died() -> void:
	# Phase 2 only: in a solo match your death ends it. Phase 3 changes this.
	await get_tree().create_timer(Config.tuning.death_end_delay).timeout
	GameState.end_match(&"died")


func _on_match_ended(reason: StringName) -> void:
	var screen := END_SCREEN_SCENE.instantiate()
	add_child(screen)
	screen.show_result(reason, GameState.get_clock_text(), crew_kills)


## Slot id -> room type id for every slot of the ship: the fixed rooms are
## themselves, the shuffled slots get their Phase 2 room or Crew Quarters.
func _make_assignment() -> Dictionary:
	var assignment := {}
	for slot: Dictionary in ShipLayoutData.SLOTS:
		if slot.fixed != &"":
			assignment[slot.id] = slot.fixed
		else:
			assignment[slot.id] = PHASE2_ROOMS.get(slot.id, &"quarters")
	return assignment
