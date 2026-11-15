class_name ShotEffects
extends RefCounted
## A muzzle flash and a shot sound at a character's head. Used for shots fired
## by characters whose gun this machine does not show (other players').


static func play(player: PlayerCharacter) -> void:
	var tuning := Config.tuning
	var light := OmniLight3D.new()
	light.light_color = tuning.shot_effect_color
	light.light_energy = tuning.shot_effect_energy
	light.omni_range = tuning.shot_effect_range
	player.head.add_child(light)
	var timer := player.get_tree().create_timer(tuning.muzzle_flash_seconds)
	timer.timeout.connect(light.queue_free)
	var sound := AudioStreamPlayer3D.new()
	sound.stream = PlaceholderSounds.noise_burst(tuning.placeholder_shot_seconds)
	player.head.add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()
