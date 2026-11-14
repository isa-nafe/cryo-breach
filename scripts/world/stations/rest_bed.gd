class_name RestBed
extends Interactable
## Medbay rest bed: heals all light wounds (GDD "Medbay").


func _ready() -> void:
	super._ready()
	prompt = "Rest"
	hold_seconds = Config.tuning.rest_bed_seconds


func can_interact(player: PlayerCharacter) -> bool:
	return enabled and player.wounds.light_wounds > 0


func get_blocked_prompt(_player: PlayerCharacter) -> String:
	return "No light wounds to heal"


func _on_interact(player: PlayerCharacter) -> void:
	player.wounds.heal_light()
	player.show_message("Light wounds healed")
