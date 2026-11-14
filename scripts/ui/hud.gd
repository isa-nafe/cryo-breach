extends CanvasLayer
## The player's own HUD: wounds, ammo, hit marker, death screen.
## Scene: CanvasLayer with Labels "Wounds", "Ammo", "HitMarker" and a
## ColorRect "DeathScreen" that has a Label child "Text".

## The PlayerCharacter this HUD belongs to.
@export var player_path: NodePath

var _player: PlayerCharacter

@onready var _prompt: Label = $Prompt
@onready var _hold_bar: ProgressBar = $HoldBar
@onready var _message: Label = $Message
@onready var _clock: Label = $Clock
@onready var _banner: Label = $Banner
@onready var _wounds: Label = $Wounds
@onready var _ammo: Label = $Ammo
@onready var _hands: Label = $Hands
@onready var _hit_marker: Label = $HitMarker
@onready var _death_screen: ColorRect = $DeathScreen


func _ready() -> void:
	_banner.text = ""
	_message.text = ""
	_death_screen.visible = false
	_hit_marker.visible = false
	_player = get_node_or_null(player_path) as PlayerCharacter
	if _player == null:
		push_warning("HUD: no PlayerCharacter at %s" % player_path)
		return
	_player.wounds.changed.connect(_refresh_wounds)
	_player.died.connect(_on_player_died)
	_refresh_wounds()
	_player.item_user.hit_confirmed.connect(_on_hit_confirmed)
	_player.message_shown.connect(_on_message)


func _process(_delta: float) -> void:
	_clock.text = GameState.get_clock_text()
	_update_prompt()
	_update_items()


## Shows what the player is looking at and how long they have held E.
func _update_prompt() -> void:
	_prompt.text = ""
	_hold_bar.visible = false
	if _player == null or _player.is_dead:
		return
	var pod := _player.seated_pod
	if pod != null:
		_prompt.text = pod.get_seated_prompt()
		if pod.hold_fraction > 0.0:
			_hold_bar.visible = true
			_hold_bar.value = pod.hold_fraction
		return
	var interactor := _player.interactor
	var lines := PackedStringArray()
	var interact_text := interactor.get_prompt_text(_player)
	if not interact_text.is_empty():
		lines.append(interact_text)
	lines.append_array(_get_item_prompts())
	_prompt.text = "\n".join(lines)
	var focused := interactor.focused
	if focused == null or interact_text.is_empty():
		return
	var seconds := focused.get_hold_seconds(_player)
	if seconds > 0.0 and interactor.hold.progress > 0.0:
		_hold_bar.visible = true
		_hold_bar.value = interactor.hold.get_fraction(seconds)


## What each hand's item can do to the thing in the crosshair.
func _get_item_prompts() -> PackedStringArray:
	var lines := PackedStringArray()
	var focused := _player.interactor.focused
	if focused == null:
		return lines
	var buttons := ["Left mouse", "Right mouse"]
	for hand in 2:
		var stack := _player.inventory.hands[hand]
		if stack == null:
			continue
		var text := focused.get_item_prompt(_player, stack.data)
		if not text.is_empty():
			lines.append("[%s] %s (hold)" % [buttons[hand], text])
	return lines


## Shows the hands, the slots, the main gun's ammo and item hold bars.
func _update_items() -> void:
	if _player == null:
		return
	var inventory := _player.inventory
	var slot_parts := PackedStringArray()
	for i in inventory.slots.size():
		slot_parts.append("[%d] %s" % [i + 1, _stack_text(inventory.slots[i])])
	_hands.text = "Main: %s    Off: %s\n%s" % [
		_stack_text(inventory.hands[Inventory.MAIN_HAND]),
		_stack_text(inventory.hands[Inventory.OFF_HAND]),
		"   ".join(slot_parts),
	]
	var weapon := _player.item_user.get_main_weapon()
	_ammo.text = ""
	if weapon:
		_ammo.text = "%s  %d / %d" % [weapon.data.display_name, weapon.rounds, weapon.data.capacity]
	var fraction := _player.item_user.hold_fraction
	if fraction > 0.0:
		_hold_bar.visible = true
		_hold_bar.value = fraction


func _stack_text(stack: ItemStack) -> String:
	if stack == null:
		return "-"
	var text := stack.data.display_name
	if stack.count > 1:
		text += " x%d" % stack.count
	if stack.data.max_charges > 0:
		text += " (%d)" % stack.charges
	return text


func _unhandled_input(event: InputEvent) -> void:
	# In a match the end screen handles restarting.
	var in_match := GameState.phase != GameState.Phase.LOBBY
	if _player and _player.is_dead and not in_match and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _refresh_wounds() -> void:
	var wounds := _player.wounds
	var tuning := Config.tuning
	var lines := PackedStringArray()
	lines.append("Light wounds   %d / %d" % [wounds.light_wounds, tuning.light_wounds_per_serious])
	lines.append(
		"Serious wounds %d / %d" % [wounds.serious_effects.size(), tuning.serious_wounds_to_die]
	)
	if not wounds.serious_effects.is_empty():
		lines.append(wounds.describe_serious())
	_wounds.text = "\n".join(lines)


func _on_message(text: String) -> void:
	_message.text = text
	await get_tree().create_timer(Config.tuning.message_seconds).timeout
	if _message.text == text:
		_message.text = ""


func _on_hit_confirmed(_killed: bool) -> void:
	_hit_marker.visible = true
	await get_tree().create_timer(Config.tuning.hit_marker_seconds).timeout
	_hit_marker.visible = false


func _on_player_died() -> void:
	# In a match the end screen replaces this one.
	if GameState.phase != GameState.Phase.LOBBY:
		return
	_death_screen.visible = true
