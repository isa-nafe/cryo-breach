class_name PlayerWounds
extends Node
## A player's wounds. Players have no hit points (design rule).
##
## Light wounds: every third one becomes a serious wound.
## Serious wounds: each has a random effect; the third one kills.
## Only the host changes wounds; the owner is told the result.

## Emitted whenever anything about the wounds changes.
signal changed
## Emitted once when the player dies of wounds.
signal died

enum Effect { LIMP, SHAKY_AIM, BROKEN_ARM, BLEEDING }

const EFFECT_NAMES := {
	Effect.LIMP: "Limp",
	Effect.SHAKY_AIM: "Shaky aim",
	Effect.BROKEN_ARM: "Broken arm",
	Effect.BLEEDING: "Bleeding",
}

## Light wounds not yet turned into a serious wound.
var light_wounds: int = 0
## One entry per serious wound: its effect.
var serious_effects: Array[Effect] = []
## One entry per serious wound: true once it has been bandaged.
var serious_dressed: Array[bool] = []
var is_dead := false

var _bleed_timer := 0.0


func _physics_process(delta: float) -> void:
	if is_dead or not has_effect(Effect.BLEEDING):
		_bleed_timer = 0.0
		return
	_bleed_timer += delta
	if _bleed_timer >= Config.tuning.bleed_interval:
		_bleed_timer -= Config.tuning.bleed_interval
		add_light()


## Adds light wounds, converting every third into a serious wound.
func add_light(count: int = 1) -> void:
	for _i in count:
		if is_dead:
			break
		light_wounds += 1
		if light_wounds >= Config.tuning.light_wounds_per_serious:
			light_wounds = 0
			_add_one_serious()
	changed.emit()


## Adds serious wounds, each with a random effect.
func add_serious(count: int = 1) -> void:
	for _i in count:
		if is_dead:
			break
		_add_one_serious()
	changed.emit()


## Medkit or rest bed: removes all light wounds.
func heal_light() -> void:
	light_wounds = 0
	changed.emit()


## Bandage: stops the effect of the first undressed serious wound.
## It still counts toward death. Returns false if there was none.
func dress_one() -> bool:
	var index := serious_dressed.find(false)
	if index == -1:
		return false
	serious_dressed[index] = true
	changed.emit()
	return true


## Surgery: removes one serious wound completely (undressed ones first).
func remove_one_serious() -> bool:
	if serious_effects.is_empty():
		return false
	var index := serious_dressed.find(false)
	if index == -1:
		index = 0
	serious_effects.remove_at(index)
	serious_dressed.remove_at(index)
	changed.emit()
	return true


## True if an undressed serious wound has this effect.
func has_effect(effect: Effect) -> bool:
	for i in serious_effects.size():
		if serious_effects[i] == effect and not serious_dressed[i]:
			return true
	return false


func get_speed_multiplier() -> float:
	if has_effect(Effect.LIMP):
		return Config.tuning.limp_speed_multiplier
	return 1.0


func can_sprint() -> bool:
	return not has_effect(Effect.LIMP)


func get_spread_multiplier() -> float:
	if has_effect(Effect.SHAKY_AIM):
		return Config.tuning.shaky_aim_spread_multiplier
	return 1.0


## 1 with an undressed broken arm, otherwise 2.
func get_usable_hands() -> int:
	if has_effect(Effect.BROKEN_ARM):
		return 1
	return 2


## Text for the HUD, for example "Limp, Bleeding (dressed)".
func describe_serious() -> String:
	var parts := PackedStringArray()
	for i in serious_effects.size():
		var text: String = EFFECT_NAMES[serious_effects[i]]
		if serious_dressed[i]:
			text += " (dressed)"
		parts.append(text)
	return ", ".join(parts)


func _add_one_serious() -> void:
	var effect := randi_range(0, Effect.size() - 1) as Effect
	serious_effects.append(effect)
	serious_dressed.append(false)
	if serious_effects.size() >= Config.tuning.serious_wounds_to_die:
		is_dead = true
		died.emit()
