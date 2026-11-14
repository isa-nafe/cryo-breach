extends CanvasLayer
## Shown when the match ends. Pauses the game; press R to play again.
## Scene: CanvasLayer (process mode "Always") with Labels "Title", "Details"
## and "Hint". Phase 5 (M5.5) adds every player's objective and result.

const TITLES := {
	&"escaped": "You escaped",
	&"died": "You died",
	&"jump": "Left behind at the jump",
	&"destroyed": "The ship was destroyed",
	&"nobody_awake": "Nobody was left awake",
}

@onready var _title: Label = $Title
@onready var _details: Label = $Details


## Fills in the screen and pauses the game.
func show_result(reason: StringName, clock_text: String, kills: int) -> void:
	_title.text = TITLES.get(reason, "Match over")
	_details.text = "Time  %s\nAliens killed  %d" % [clock_text, kills]
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()
