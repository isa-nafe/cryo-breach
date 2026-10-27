extends Node
## Global game configuration, available everywhere as `Config`.
##
## Example: `Config.tuning.walk_speed`
## Registered as an autoload in Project Settings > Globals.

const TUNING_PATH := "res://data/tuning.tres"

## All gameplay numbers. See res://scripts/data/tuning.gd.
var tuning: Tuning


func _enter_tree() -> void:
	tuning = load(TUNING_PATH) as Tuning
	if tuning == null:
		push_error("Could not load %s; using default values." % TUNING_PATH)
		tuning = Tuning.new()
	InputSetup.ensure_default_actions()
