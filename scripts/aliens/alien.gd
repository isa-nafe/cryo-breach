class_name Alien
extends CharacterBody3D
## An active alien. Runs only on the host; clients see its synced position.
##
## Phase 1 behaviour (enough for the Crawler): stand still, walk to loud
## noises, chase a player it can see, attack in reach. Phase 4 adds vents,
## fleeing, doors and the other types on top of this class.
## Scene: CharacterBody3D on the "aliens" layer with children
## "CollisionShape3D", "NavigationAgent3D" and "HealthComponent".

## Emitted when this alien is killed. `killer` dealt the last damage.
signal died(alien: Alien, killer: Node)

enum State { IDLE, INVESTIGATE, CHASE, DEAD }

## This alien's numbers.
@export var data: AlienData

var state: State = State.IDLE
## The player being chased, or null.
var target: PlayerCharacter = null

var _attack_cooldown := 0.0
var _repath_timer := 0.0
var _lost_sight_timer := 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var _agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	# Only the host thinks; clients get the position and turn from a synchronizer.
	set_physics_process(multiplayer.is_server())
	add_to_group(&"aliens")
	health.max_health = data.max_health
	health.revive()
	health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_update_target(delta)
	var speed := 0.0
	match state:
		State.CHASE:
			_repath_to(target.global_position, delta)
			if _distance_to_target() > data.attack_range * 0.8:
				speed = data.move_speed
			_try_attack()
		State.INVESTIGATE:
			speed = data.move_speed
			if _navigation_ready() and _agent.is_navigation_finished():
				state = State.IDLE
	_handle_doors()
	_steer(speed, delta)
	move_and_slide()


## Called through the "aliens" group whenever a player makes noise.
func hear_noise(noise_position: Vector3, amount: float) -> void:
	if state == State.DEAD or state == State.CHASE:
		return
	if amount < Config.tuning.loud_noise_threshold:
		return
	if global_position.distance_to(noise_position) > data.hearing_range:
		return
	go_to(noise_position)


## Sends the alien to a place (noise, encounter zone).
func go_to(place: Vector3) -> void:
	if state == State.DEAD or state == State.CHASE:
		return
	_agent.target_position = place
	state = State.INVESTIGATE


## Opens closed doors the alien walks up to. A locked or welded door stops
## it (M4.2 lets bigger aliens break them).
func _handle_doors() -> void:
	if state != State.CHASE and state != State.INVESTIGATE:
		return
	var reach := Config.tuning.alien_door_reach
	for node: Node in get_tree().get_nodes_in_group(&"doors"):
		var door := node as Door
		if door == null or door.is_open:
			continue
		var offset := door.global_position - global_position
		offset.y = 0.0
		if offset.length() > reach:
			continue
		if not door.let_alien_through(self):
			target = null
			state = State.IDLE
			return


func _update_target(delta: float) -> void:
	if target != null and (not is_instance_valid(target) or target.is_dead):
		target = null
		state = State.IDLE
	var seen := _find_visible_player()
	if seen:
		target = seen
		state = State.CHASE
		_lost_sight_timer = 0.0
	elif state == State.CHASE:
		_lost_sight_timer += delta
		if _lost_sight_timer >= Config.tuning.alien_lose_target_seconds:
			# Give up the chase but check where the player was last.
			var last_place := target.global_position
			target = null
			state = State.IDLE
			go_to(last_place)


func _find_visible_player() -> PlayerCharacter:
	var best: PlayerCharacter = null
	var best_distance := INF
	for node: Node in get_tree().get_nodes_in_group(&"players"):
		var player := node as PlayerCharacter
		if player == null or player.is_dead or not _can_see(player):
			continue
		var distance := global_position.distance_to(player.global_position)
		if distance < best_distance:
			best = player
			best_distance = distance
	return best


func _can_see(player: PlayerCharacter) -> bool:
	if data.sight_range <= 0.0:
		return false
	var eye := global_position + Vector3.UP * data.eye_height
	var to_player := player.head.global_position - eye
	if to_player.length() > data.sight_range:
		return false
	if data.sight_cone_degrees < 360.0:
		var flat := Vector3(to_player.x, 0.0, to_player.z)
		var forward := -global_basis.z
		if flat.length() > 0.01 and forward.angle_to(flat) > deg_to_rad(data.sight_cone_degrees) * 0.5:
			return false
	# A wall between the eyes and the player's head blocks sight.
	var query := PhysicsRayQueryParameters3D.create(
		eye, player.head.global_position, Layers.WORLD | Layers.DOORS
	)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _try_attack() -> void:
	if _attack_cooldown > 0.0 or _distance_to_target() > data.attack_range:
		return
	_attack_cooldown = data.attack_interval
	if data.light_wounds_per_hit > 0:
		target.wounds.add_light(data.light_wounds_per_hit)
	if data.serious_wounds_per_hit > 0:
		target.wounds.add_serious(data.serious_wounds_per_hit)


func _distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


## Asks for a new path at most a few times per second (paths are costly).
func _repath_to(place: Vector3, delta: float) -> void:
	_repath_timer -= delta
	if _repath_timer > 0.0:
		return
	_repath_timer = Config.tuning.alien_repath_interval
	_agent.target_position = place


func _steer(speed: float, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var direction := Vector3.ZERO
	if speed > 0.0 and _navigation_ready() and not _agent.is_navigation_finished():
		direction = _agent.get_next_path_position() - global_position
		direction.y = 0.0
		direction = direction.normalized()
	elif state == State.CHASE:
		# In reach: stand still but keep facing the target.
		direction = target.global_position - global_position
		direction.y = 0.0
		direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction != Vector3.ZERO:
		var yaw := atan2(-direction.x, -direction.z)
		var weight := clampf(Config.tuning.alien_turn_speed * delta, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, yaw, weight)


## False until the navigation map has been built at least once.
func _navigation_ready() -> bool:
	return NavigationServer3D.map_get_iteration_id(_agent.get_navigation_map()) != 0


func _on_health_died(killer: Node) -> void:
	state = State.DEAD
	remove_from_group(&"aliens")
	died.emit(self, killer)
	queue_free()
