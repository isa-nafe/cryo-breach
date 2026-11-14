class_name OverviewCamera
extends Camera3D
## A camera high above the ship, looking straight down, so the whole layout
## shows. While it is on, the ceilings are hidden and the fog is switched off
## with brighter ambient light (otherwise the ship is too dark to see from
## 100 m up). Add it to the match scene and call `set_active`.

var _saved_fog := false
var _saved_ambient := 0.0
var _is_active := false


func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = Config.tuning.overview_camera_size
	far = Config.tuning.overview_camera_height * 2.0
	position = Vector3(Config.tuning.overview_camera_x, Config.tuning.overview_camera_height, 0.0)
	rotation_degrees = Vector3(-90.0, 0.0, 0.0)


## True while the overview is showing.
func is_overview_on() -> bool:
	return _is_active


## Turns the overview on (this camera becomes the view) or off (the caller
## must make another camera current again).
func set_active(on: bool) -> void:
	if on == _is_active:
		return
	_is_active = on
	if on:
		make_current()
	get_tree().call_group(&"ceilings", &"set_visible", not on)
	_set_lighting(on)


func _set_lighting(on: bool) -> void:
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
