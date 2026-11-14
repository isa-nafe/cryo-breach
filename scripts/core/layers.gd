class_name Layers
extends RefCounted
## Physics layer bit values. Use these instead of raw numbers.
##
## Example: `query.collision_mask = Layers.WORLD | Layers.ALIENS`

const WORLD := 1
const PLAYERS := 2
const ALIENS := 4
const ZONES := 8
const INTERACTABLES := 16
const DOORS := 32

## What a bullet can hit. Players are left out on purpose: bullets and
## melee never damage players (design rule).
const BULLET_MASK := WORLD | ALIENS | DOORS
