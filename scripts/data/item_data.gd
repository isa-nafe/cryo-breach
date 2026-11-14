class_name ItemData
extends Resource
## One kind of item. One .tres per item in res://data/items/.

enum UseKind { NONE, HITSCAN, MELEE, THROWN, HEAL_LIGHT, DRESS_WOUND, SCANNER, AMMO, TOOL }

## Short id, for example &"medkit".
@export var id: StringName = &""
## Name on the HUD.
@export var display_name: String = ""
## True if the item needs both hands and cannot go in a slot.
@export var two_handed: bool = false
## How many fit in one hand or slot (3 for small items, otherwise 1).
@export var stack_limit: int = 1
## What happens when its hand button is pressed with nothing to use it on.
@export var use_kind: UseKind = UseKind.NONE
## Seconds the hand button must be held to use it on yourself.
@export var use_seconds: float = 0.0
## Hitscan weapons: the gun's numbers.
@export var weapon: WeaponData
## Melee weapons: damage to aliens per hit.
@export var melee_damage: float = 0.0
## Rounds, charges or uses when full. 0 = the item has none.
@export var max_charges: int = 0
## True if using it up removes one from the stack.
@export var consumed_on_use: bool = false
## What the player sees in their hand. Empty = a coloured box.
@export var view_scene: PackedScene
## Colour of the grey-box pickup and hand box.
@export var color: Color = Color(0.8, 0.8, 0.8)
