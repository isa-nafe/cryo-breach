class_name HoldAction
extends RefCounted
## Tracks "hold a button for N seconds on one target".
##
## Call `update` every physics frame. It returns true exactly once, when
## the hold completes; the button must then be released before it can
## start again. Looking at a different target restarts the timer.

## Seconds held so far on the current target.
var progress: float = 0.0

var _target: Variant = null
var _needs_release := false


func update(held: bool, target: Variant, seconds: float, delta: float) -> bool:
	if not held or target == null:
		progress = 0.0
		_target = null
		_needs_release = _needs_release and held
		return false
	if _needs_release:
		return false
	if target != _target:
		_target = target
		progress = 0.0
	progress += delta
	if progress < seconds:
		return false
	progress = 0.0
	_needs_release = true
	return true


## Progress from 0 to 1, for the HUD bar.
func get_fraction(seconds: float) -> float:
	if seconds <= 0.0:
		return 0.0
	return clampf(progress / seconds, 0.0, 1.0)
