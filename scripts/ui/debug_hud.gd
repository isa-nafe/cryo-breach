extends CanvasLayer
## Developer overlay: what the player is doing and how loud their zone is.
## Toggle it with F3.

## The PlayerCharacter to report on.
@export var player_path: NodePath

var _player: PlayerCharacter

@onready var _info: Label = $Info


func _ready() -> void:
	_player = get_node_or_null(player_path) as PlayerCharacter
	if _player == null:
		push_warning("DebugHUD: no PlayerCharacter at %s" % player_path)


func _unhandled_input(event: InputEvent) -> void:
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
		"",
		"WASD move | Shift sprint | Ctrl or C crouch | Space jump",
		"F lamp | F3 hide this | Esc free the mouse, click to resume",
	])
	_info.text = "\n".join(lines)
