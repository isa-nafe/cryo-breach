extends Node3D
## Phase 1 test scene: spawns one Crawler at a time in the corridor and
## sends it toward the player, so the first fight happens without hunting
## for it. Scene needs children "Navigation" (NavBaker), "Aliens" (Node3D)
## and "AlienSpawn" (Marker3D).

const CRAWLER_SCENE := preload("res://scenes/aliens/crawler.tscn")

## What the test scene is doing, shown on the debug overlay.
var status: String = "Baking navigation..."

var _nav_baked := false

@onready var _navigation: NavBaker = $Navigation
@onready var _aliens: Node3D = $Aliens
@onready var _spawn_point: Marker3D = $AlienSpawn


func _ready() -> void:
	var player := get_tree().get_first_node_in_group(&"players") as PlayerCharacter
	if player:
		TestKit.give(player)
	TestKit.scatter(get_tree(), Vector3.ZERO)
	_navigation.bake_finished.connect(_on_bake_finished)
	var waited := 0.0
	while not _nav_baked and waited < Config.tuning.nav_bake_timeout_seconds:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if not _nav_baked:
		push_warning("Navigation bake did not finish; aliens may not move.")
		status = "Navigation bake did NOT finish (aliens may not move)"
	_spawn_after(Config.tuning.first_crawler_delay)


func _on_bake_finished() -> void:
	_nav_baked = true
	status = "Navigation baked"


func _spawn_after(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	var crawler: Alien = CRAWLER_SCENE.instantiate()
	crawler.position = _spawn_point.position
	_aliens.add_child(crawler)
	crawler.died.connect(_on_crawler_died)
	# Head for where the player is now; it then hunts by sight and sound.
	var player := get_tree().get_first_node_in_group(&"players") as Node3D
	if player:
		crawler.go_to(player.global_position)
	status = "%s | Crawler is out" % status.split(" | ")[0]


func _on_crawler_died(_alien: Alien, _killer: Node) -> void:
	status = "%s | next Crawler soon" % status.split(" | ")[0]
	_spawn_after(Config.tuning.crawler_respawn_delay)
