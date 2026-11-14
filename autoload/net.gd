extends Node
## Hosting, joining and the list of players, available everywhere as `Net`.
##
## Rule for every network message in this project: the host (peer id 1) owns
## all game rules; clients only ask. Solo play is a host with nobody else
## connected: with no network peer, Godot uses an "offline" peer for which
## `multiplayer.is_server()` is true and the peer id is 1.

## Emitted on every peer when the player list changes.
signal players_changed
## Emitted on a client when joining fails.
signal join_failed
## Emitted on the host when every peer has loaded the match scene.
signal all_peers_loaded
## Emitted on the host when a client drops during a match.
signal peer_left(peer_id: int)

const MATCH_SCENE := "res://scenes/match.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

## Peer id -> {"name": String, "role": StringName}. Same on every peer.
var players: Dictionary = {}
## The name this player typed in the menu.
var local_name: String = "Crew"
## Slot id -> room type id for the match being loaded.
var match_assignment: Dictionary = {}
## A message for the menu to show once (for example "The host left").
var notice: String = ""

var _loaded_peers: Array[int] = []


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## True when this game is connected to other players (as host or client).
func is_networked() -> bool:
	return multiplayer.multiplayer_peer is ENetMultiplayerPeer


## Starts a solo game: a host nobody can join.
func play_offline() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_set_players({1: _make_info(local_name)})


func host_game(port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, Config.tuning.max_players - 1)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	_set_players({1: _make_info(local_name)})
	return OK


func join_game(address: String, port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


## Drops the connection and goes back to the menu.
func leave() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	_loaded_peers.clear()
	match_assignment = {}
	GameState.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


## Host only: sends everyone into the match. `assignment` maps slot id ->
## room type id, so every peer builds the same ship.
func host_start_match(assignment: Dictionary) -> void:
	_loaded_peers.clear()
	_load_match(assignment)
	if is_networked():
		_rpc_load_match.rpc(assignment)


## Every peer calls this when its match scene is ready.
func report_loaded() -> void:
	if multiplayer.is_server():
		_host_peer_loaded(multiplayer.get_unique_id())
	else:
		_rpc_loaded.rpc_id(1)


func get_player_name(peer_id: int) -> String:
	return players.get(peer_id, {}).get("name", "Unknown")


func _make_info(player_name: String) -> Dictionary:
	return {"name": player_name.left(Config.tuning.max_name_length), "role": &""}


func _set_players(list: Dictionary) -> void:
	players = list
	players_changed.emit()


func _on_connected_to_server() -> void:
	_rpc_register.rpc_id(1, local_name)


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	join_failed.emit()


func _on_server_disconnected() -> void:
	notice = "The host left the game."
	leave()


func _on_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if GameState.phase == GameState.Phase.LOBBY:
		players.erase(peer_id)
		_rpc_set_players.rpc(players)
	else:
		peer_left.emit(peer_id)


## A client asks the host to add it to the player list.
@rpc("any_peer", "call_remote", "reliable")
func _rpc_register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var is_full := players.size() >= Config.tuning.max_players
	if is_full or GameState.phase != GameState.Phase.LOBBY or _loaded_peers.size() > 0:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	players[peer_id] = _make_info(player_name)
	_rpc_set_players.rpc(players)


@rpc("authority", "call_local", "reliable")
func _rpc_set_players(list: Dictionary) -> void:
	_set_players(list)


@rpc("authority", "call_remote", "reliable")
func _rpc_load_match(assignment: Dictionary) -> void:
	_load_match(assignment)


func _load_match(assignment: Dictionary) -> void:
	match_assignment = assignment
	get_tree().change_scene_to_file(MATCH_SCENE)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_loaded() -> void:
	if multiplayer.is_server():
		_host_peer_loaded(multiplayer.get_remote_sender_id())


func _host_peer_loaded(peer_id: int) -> void:
	if peer_id not in _loaded_peers:
		_loaded_peers.append(peer_id)
	if _loaded_peers.size() >= players.size():
		all_peers_loaded.emit()
