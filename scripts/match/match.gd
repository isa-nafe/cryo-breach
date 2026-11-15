extends Node3D
## The game world for one match. Every player builds the ship from the same
## room assignment. The host then adds a character for every player, its own
## HUDs and the rules, and starts the clock. A `MultiplayerSpawner` makes the
## same characters appear on every machine.
##
## Running this scene directly (not from the menu) is a solo match.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/debug_hud.tscn")

## The scenes aliens are made from, by alien id.
const ALIEN_SCENES := {&"crawler": preload("res://scenes/aliens/crawler.tscn")}
const END_SCREEN_SCENE := preload("res://scenes/ui/end_screen.tscn")

## Aliens the crew has killed this match.
var crew_kills: int = 0

## What the match is doing, shown on the debug overlay.
var status: String = "Match running"

var _client_overview: OverviewCamera
var _client_label: Label

@onready var _players: Node3D = $Players
@onready var _player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var _aliens: Node3D = $Aliens
@onready var _navigation: NavBaker = $Navigation
@onready var _ship: ShipBuilder = $Navigation/Ship


func _ready() -> void:
	if Net.players.is_empty():
		Net.play_offline()
	GameState.reset()
	var assignment := Net.match_assignment
	if assignment.is_empty():
		assignment = RoomAssignment.make_phase2()
	_ship.build(assignment)
	_navigation.bake()
	# Every machine builds a character the same way when the host spawns it.
	_player_spawner.spawn_function = _spawn_player
	if multiplayer.is_server():
		# The host waits until every player has built the ship.
		Net.all_peers_loaded.connect(_host_start, CONNECT_ONE_SHOT)
	else:
		_player_spawner.spawned.connect(_on_player_spawned)
		_show_client_view()
	Net.report_loaded()


## Builds one player's character. Runs on every machine (it is the
## spawner's spawn function); `data` comes from `_host_start`.
func _spawn_player(data: Dictionary) -> Node:
	var player: PlayerCharacter = PLAYER_SCENE.instantiate()
	player.peer_id = int(data["peer_id"])
	player.name = "Player%d" % player.peer_id
	player.position = data["position"]
	return player


## Host only: adds a character for every player, then the HUDs and the rules,
## and starts the match everywhere.
func _host_start() -> void:
	var bay_node: Node3D = _ship.furnishings[&"cryo_bay"]
	var spawn_points: Array[Node] = bay_node.get_node("SpawnPoints").get_children()
	var host_player: PlayerCharacter = null
	var index := 0
	for peer_id: int in Net.players:
		var marker := spawn_points[index % spawn_points.size()] as Marker3D
		var player := _add_player({"peer_id": peer_id, "position": marker.global_position})
		TestKit.give(player)
		player.died.connect(_on_player_died)
		if peer_id == multiplayer.get_unique_id():
			host_player = player
		index += 1
	var bay_zone: Zone = _ship.room_zones[&"cryo_bay"]
	var bay := bay_zone.global_position
	TestKit.scatter(get_tree(), Vector3(bay.x, 0.0, bay.z))
	# The HUDs need the player to exist, so they are added after it.
	for scene: PackedScene in [HUD_SCENE, DEBUG_HUD_SCENE]:
		var hud := scene.instantiate()
		hud.player_path = host_player.get_path()
		add_child(hud)
	GameState.loot_deck.setup(load("res://data/loot_table.tres") as LootTable, 1)
	_place_power_cell()
	GameState.match_ended.connect(_on_match_ended)
	var director := TimerDirector.new()
	director.setup(spawn_alien)
	add_child(director)
	GameState.start_match()
	if Net.is_networked():
		_rpc_start_match.rpc()


## Host only. In a network game the spawner copies the character to every
## other machine; solo play adds it directly so it never depends on the network.
func _add_player(data: Dictionary) -> PlayerCharacter:
	if Net.is_networked():
		return _player_spawner.spawn(data) as PlayerCharacter
	var player := _spawn_player(data) as PlayerCharacter
	_players.add_child(player)
	return player


## A client's own character has arrived: leave the waiting view.
func _on_player_spawned(node: Node) -> void:
	var player := node as PlayerCharacter
	if player == null or not player.is_local():
		return
	_client_overview.set_active(false)
	var player_name := Net.get_player_name(multiplayer.get_unique_id())
	_client_label.text = (
		"Connected as %s. You can walk and look around; " % player_name
		+ "doors, items and shooting come in the next updates."
	)


## What a player who is not the host sees until their character arrives: the
## whole ship from above.
func _show_client_view() -> void:
	_client_overview = OverviewCamera.new()
	add_child(_client_overview)
	_client_overview.set_active(true)
	var layer := CanvasLayer.new()
	_client_label = Label.new()
	_client_label.text = "Connected to the host. Waiting for the match to start..."
	_client_label.position = Vector2(Config.tuning.menu_spacing, Config.tuning.menu_spacing)
	layer.add_child(_client_label)
	add_child(layer)


## The host tells the other players the match has started.
@rpc("authority", "call_remote", "reliable")
func _rpc_start_match() -> void:
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
	# Until M3.5 the match ends when nobody is left alive.
	await get_tree().create_timer(Config.tuning.death_end_delay).timeout
	if GameState.get_awake_players().is_empty():
		GameState.end_match(&"died")


func _on_match_ended(reason: StringName) -> void:
	var screen := END_SCREEN_SCENE.instantiate()
	add_child(screen)
	screen.show_result(reason, GameState.get_clock_text(), crew_kills)
