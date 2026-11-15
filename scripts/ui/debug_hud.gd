extends CanvasLayer
## Developer overlay: what the player is doing and how loud their zone is.
## Toggle it with F3.

## The PlayerCharacter to report on.
@export var player_path: NodePath

var _player: PlayerCharacter
var _overview: OverviewCamera

@onready var _info: Label = $Info


func _ready() -> void:
	_player = get_node_or_null(player_path) as PlayerCharacter
	if _player == null:
		push_warning("DebugHUD: no PlayerCharacter at %s" % player_path)


func _unhandled_input(event: InputEvent) -> void:
	_debug_keys(event)
	if event.is_action_pressed("toggle_debug"):
		_info.visible = not _info.visible


func _process(_delta: float) -> void:
	if not _info.visible or _player == null:
		return

	var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	var zone_text := "none"
	var zone := _player.current_zone
	if zone:
		zone_text = "%s (%s, %s section)  noise %.0f / %.0f" % [
			zone.zone_name, zone.kind, zone.power_section,
			zone.noise, Config.tuning.noise_max,
		]
	var lamp_text := "on" if _player.lamp.visible else "off"

	var lines := PackedStringArray([
		"FPS    %d" % Engine.get_frames_per_second(),
		"State  %s" % _player.get_state_name(),
		"Speed  %.1f m/s" % speed,
		"Zone   %s" % zone_text,
		"Lamp   %s" % lamp_text,
		"Scene  %s" % str(get_tree().current_scene.get(&"status")),
		"",
		"Left mouse FIRE | Shift+W sprint (1 noise per 3 s) | WASD move | Ctrl or C crouch | Space jump",
		"F4 top-down ship view | F8 lock the door you look at",
		"F5 light wound | F6 serious wound | F7 heal light",
		"F lamp | F3 hide this | Esc free the mouse, click to resume",
	])
	_info.text = "\n".join(lines)


## Debug only (remove in Phase 6): test wounds before aliens exist.
func _debug_keys(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _player == null:
		return
	# The wound and door keys change the game, so only the host may use them.
	if not multiplayer.is_server() and key.physical_keycode != KEY_F4:
		return
	match key.physical_keycode:
		KEY_F5:
			_player.wounds.add_light()
		KEY_F6:
			_player.wounds.add_serious()
		KEY_F7:
			_player.wounds.heal_light()
		KEY_F4:
			_toggle_overview()
		KEY_F8:
			var door := _player.interactor.focused as Door
			if door:
				door.lock(Config.tuning.door_lock_seconds)


## Debug only: a camera high above the ship with the ceilings hidden, so you
## can see the whole layout. Press F4 again to go back.
func _toggle_overview() -> void:
	if _overview == null:
		_overview = OverviewCamera.new()
		get_tree().current_scene.add_child(_overview)
	if _overview.is_overview_on():
		_overview.set_active(false)
		_player.camera.make_current()
	else:
		_overview.set_active(true)
