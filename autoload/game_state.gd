extends Node
## The state of the current match, available everywhere as `GameState`.
##
## The host advances the clock and decides when the match ends. Phase 3
## sends the clock and the end of the match to clients.

## Emitted when the match begins.
signal match_started
## Emitted once when the match ends. `reason` is &"jump", &"destroyed",
## &"nobody_awake" or (Phase 2 only) &"escaped" / &"died".
signal match_ended(reason: StringName)
## Emitted when the clock passes a named time (see Tuning "Match flow").
signal time_mark(mark: StringName)

enum Phase { LOBBY, PLAYING, ENDED }

var phase: Phase = Phase.LOBBY
## Seconds since the match started.
var clock: float = 0.0
## Why the match ended (valid once phase is ENDED).
var end_reason: StringName = &""
## Every room and corridor segment in the ship.
var zones: Array[Zone] = []
## Every player character in the match, alive or not.
var players: Array[PlayerCharacter] = []

## The shared loot deck. Host only: never sent to clients.
var loot_deck := LootDeck.new()

## Facts about the ship only the host knows (pods unlocked, integrity...).
var ship_state := ShipState.new()

var _marks_done: Dictionary = {}


func _physics_process(delta: float) -> void:
	if phase != Phase.PLAYING or not multiplayer.is_server():
		return
	clock += delta
	for mark: StringName in _get_marks():
		if clock >= _get_marks()[mark] and not _marks_done.has(mark):
			_marks_done[mark] = true
			time_mark.emit(mark)
	if clock >= Config.tuning.jump_time:
		end_match(&"jump")


## Clears everything for a new match. Call before building the ship.
func reset() -> void:
	phase = Phase.LOBBY
	clock = 0.0
	end_reason = &""
	zones.clear()
	players.clear()
	_marks_done.clear()
	loot_deck = LootDeck.new()
	ship_state = ShipState.new()


func start_match() -> void:
	phase = Phase.PLAYING
	match_started.emit()


## Ends the match. Host only.
func end_match(reason: StringName) -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	end_reason = reason
	match_ended.emit(reason)


func register_zone(zone: Zone) -> void:
	zones.append(zone)


func register_player(player: PlayerCharacter) -> void:
	players.append(player)


## The character controlled by a network peer, or null.
func get_player_by_peer(peer_id: int) -> PlayerCharacter:
	for player: PlayerCharacter in players:
		if is_instance_valid(player) and player.peer_id == peer_id:
			return player
	return null


## True once the grace period is over (encounters and events may happen).
func is_grace_over() -> bool:
	return clock >= Config.tuning.grace_period


## Players who are alive and still walking around the ship.
func get_awake_players() -> Array[PlayerCharacter]:
	var awake: Array[PlayerCharacter] = []
	for player: PlayerCharacter in players:
		if is_instance_valid(player) and player.is_awake():
			awake.append(player)
	return awake


## The clock as "MM:SS".
func get_clock_text() -> String:
	var total := int(clock)
	return "%02d:%02d" % [total / 60, total % 60]


func _get_marks() -> Dictionary:
	var tuning := Config.tuning
	return {
		&"grace_over": tuning.grace_period,
		&"commit": tuning.commit_time,
		&"cryo_unlock": tuning.cryo_unlock_time,
		&"jump_warning": tuning.jump_warning_time,
		&"final_warning": tuning.final_warning_time,
	}
