class_name HealthComponent
extends Node
## Hit points for aliens and breakable things.
##
## Players do NOT use this: they use the wound system (PlayerWounds).
## Add it as a child named "HealthComponent" so `find_in` can locate it.

## Emitted after damage is applied. `source` is who caused it (may be null).
signal damaged(amount: float, source: Node)
## Emitted once, when health reaches 0. `killer` dealt the last damage.
signal died(killer: Node)

## Starting and maximum health.
@export var max_health: float = 30.0

## Current health.
var health: float = 0.0
var is_dead := false


func _ready() -> void:
	health = max_health


## Returns the HealthComponent of `node`, or null if it has none.
static func find_in(node: Node) -> HealthComponent:
	if node == null:
		return null
	return node.get_node_or_null(^"HealthComponent") as HealthComponent


## Removes health. Only the host should call this.
func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	damaged.emit(amount, source)
	if health <= 0.0:
		is_dead = true
		died.emit(source)


## Back to full health (used when an alien returns to the pool).
func revive() -> void:
	is_dead = false
	health = max_health


## Health as a fraction from 0 to 1.
func get_fraction() -> float:
	if max_health <= 0.0:
		return 0.0
	return health / max_health
