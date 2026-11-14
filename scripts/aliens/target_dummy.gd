extends StaticBody3D
## A practice target: takes damage, disappears at 0 health, comes back.
## Scene: StaticBody3D on the "aliens" layer with children
## "CollisionShape3D", "MeshInstance3D" and "HealthComponent".

@onready var _health: HealthComponent = $HealthComponent
@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


func _on_damaged(_amount: float, _source: Node) -> void:
	# A tween animates a property over time; here a quick "pop".
	_mesh.scale = Vector3.ONE * 1.15
	create_tween().tween_property(_mesh, "scale", Vector3.ONE, 0.15)


func _on_died(_killer: Node) -> void:
	_mesh.visible = false
	_shape.set_deferred("disabled", true)
	await get_tree().create_timer(Config.tuning.dummy_respawn_seconds).timeout
	_health.revive()
	_mesh.visible = true
	_shape.set_deferred("disabled", false)
