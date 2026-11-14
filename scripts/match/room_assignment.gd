class_name RoomAssignment
extends RefCounted
## Decides which room type goes in each slot of the ship for one match. The
## host makes the assignment and sends it to every player, so everyone builds
## the same ship.

## Phase 2 rooms for some shuffled slots (the rest are Crew Quarters). M4.5
## replaces this with a random shuffle of every room type.
const PHASE2_ROOMS := {
	&"slot_3": &"medbay",
	&"slot_9": &"generator",
	&"slot_11": &"armory",
}


## Slot id -> room type id for every slot of the ship: the fixed rooms are
## themselves, the shuffled slots get their Phase 2 room or Crew Quarters.
static func make_phase2() -> Dictionary:
	var assignment := {}
	for slot: Dictionary in ShipLayoutData.SLOTS:
		if slot.fixed != &"":
			assignment[slot.id] = slot.fixed
		else:
			assignment[slot.id] = PHASE2_ROOMS.get(slot.id, &"quarters")
	return assignment
