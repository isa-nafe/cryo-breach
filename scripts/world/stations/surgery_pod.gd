class_name SurgeryPod
extends Interactable
## Medbay surgery pod: removes one serious wound (GDD "Medbay"). M5.2 adds
## the second choice, removing contamination cards.


func _ready() -> void:
	super._ready()
	prompt = "Surgery: remove a serious wound"
	hold_seconds = Config.tuning.surgery_seconds
	noise = Config.tuning.surgery_noise


func can_interact(player: PlayerCharacter) -> bool:
	return enabled and not player.wounds.serious_effects.is_empty()


func get_blocked_prompt(_player: PlayerCharacter) -> String:
	return "No serious wounds to treat"


func _on_interact(player: PlayerCharacter) -> void:
	if player.wounds.remove_one_serious():
		player.show_message("A serious wound was removed")
