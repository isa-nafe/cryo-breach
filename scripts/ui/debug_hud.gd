extends CanvasLayer
## Developer overlay: what the player is doing and how loud their zone is.
## Toggle it with F3.

## The PlayerCharacter to report on.
@export var player_path: NodePath

var _player: PlayerCharacter
var _overview: Camera3D
var _saved_fog := false
var _saved_ambient := 0.0

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
		_overview = Camera3D.new()
		_overview.projection = Camera3D.PROJECTION_ORTHOGONAL
		_overview.size = Config.tuning.overview_camera_size
		_overview.far = Config.tuning.overview_camera_height * 2.0
		get_tree().current_scene.add_child(_overview)
		_overview.global_position = Vector3(
			Config.tuning.overview_camera_x, Config.tuning.overview_camera_height, 0.0
		)
		_overview.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var show_overview := not _overview.current
	if show_overview:
		_overview.make_current()
	else:
		_player.camera.make_current()
	get_tree().call_group(&"ceilings", &"set_visible", not show_overview)
	_set_overview_lighting(show_overview)


## Fog and dim ambient light hide the ship from 100 m up, so change them while
## the overview is on and put them back after.
func _set_overview_lighting(on: bool) -> void:
	var world := get_tree().current_scene.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if world == null or world.environment == null:
		return
	var environment := world.environment
	if on:
		_saved_fog = environment.fog_enabled
		_saved_ambient = environment.ambient_light_energy
		environment.fog_enabled = false
		environment.ambient_light_energy = Config.tuning.overview_ambient_energy
	else:
		environment.fog_enabled = _saved_fog
		environment.ambient_light_energy = _saved_ambient
