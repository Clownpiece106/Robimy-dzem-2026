class_name GameSession
extends Node

signal cross_map_event(event_name: String, payload: Dictionary)
signal session_reset
signal inventory_changed(slots: Array)
signal collectible_collected(collectible_id: String)
signal collectible_dropped(collectible_id: String, item: Dictionary, world_position: Vector2)

const PLAYER_1 := 1
const PLAYER_2 := 2
const INVENTORY_SLOT_COUNT := 3

var player_states: Dictionary = {
	PLAYER_1: {"position": Vector2(220.0, 0.0), "plane": 1},
	PLAYER_2: {"position": Vector2(220.0, 0.0), "plane": 1},
}
var mansion_doors := {"left": true, "right": true}

func is_mansion_door_locked(id: String) -> bool:
	return mansion_doors.get(id, true)

func set_mansion_door_locked(id: String, locked: bool, actor_id: int) -> void:
	if not mansion_doors.has(id):
		return
	mansion_doors[id] = locked
	print("P%d changed door %s locked=%s" % [actor_id, id, locked])
	emit_cross_map_event("mansion_door_changed", {"door_id": id, "locked": locked, "source_player": actor_id})

var inventory_slots: Array[Dictionary] = [{}, {}, {}]
var inventory_actor_id := 0
var collected_collectible_ids: Dictionary = {}
var next_dropped_collectible_id := 1

func add_inventory_item(item: Dictionary, actor_id: int) -> int:
	for slot_index in INVENTORY_SLOT_COUNT:
		if inventory_slots[slot_index].is_empty():
			inventory_slots[slot_index] = item.duplicate(true)
			inventory_actor_id = actor_id
			inventory_changed.emit(inventory_slots)
			return slot_index
	return -1

func collect_shared_collectible(collectible_id: String, item: Dictionary, actor_id: int) -> int:
	if collectible_id.is_empty() or collected_collectible_ids.has(collectible_id):
		return -1
	var slot_index := add_inventory_item(item, actor_id)
	if slot_index >= 0:
		collected_collectible_ids[collectible_id] = true
		collectible_collected.emit(collectible_id)
	return slot_index

func drop_inventory_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= INVENTORY_SLOT_COUNT or inventory_slots[slot_index].is_empty():
		return {}
	var item := inventory_slots[slot_index]
	inventory_slots[slot_index] = {}
	inventory_changed.emit(inventory_slots)
	return item

func drop_shared_collectible(item: Dictionary, world_position: Vector2) -> String:
	var collectible_id := "dropped_%d" % next_dropped_collectible_id
	next_dropped_collectible_id += 1
	collectible_dropped.emit(collectible_id, item.duplicate(true), world_position)
	return collectible_id

func has_inventory_item(item_kind: String) -> bool:
	for item in inventory_slots:
		if item.get("kind", "") == item_kind:
			return true
	return false

func update_player_state(player_id: int, world_position: Vector2, plane: int) -> void:
	player_states[player_id] = {"position": world_position, "plane": plane}

func get_player_state(player_id: int) -> Dictionary:
	return player_states.get(player_id, {"position": Vector2.ZERO, "plane": 1})

func emit_cross_map_event(event_name: String, payload: Dictionary = {}) -> void:
	cross_map_event.emit(event_name, payload)

func reset() -> void:
	mansion_doors = {"left": true, "right": true}
	player_states[PLAYER_1] = {"position": Vector2(220.0, 0.0), "plane": 1}
	player_states[PLAYER_2] = {"position": Vector2(220.0, 0.0), "plane": 1}
	inventory_slots = [{}, {}, {}]
	inventory_actor_id = 0
	collected_collectible_ids.clear()
	next_dropped_collectible_id = 1
	inventory_changed.emit(inventory_slots)
	session_reset.emit()
