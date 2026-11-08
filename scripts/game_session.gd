class_name GameSession
extends Node

signal cross_map_event(event_name: String, payload: Dictionary)
signal session_reset
signal inventory_changed(slots: Array)
signal collectible_collected(collectible_id: String)
signal collectible_dropped(collectible_id: String, item: Dictionary, world_position: Vector2)
signal placement_changed(placement_id: String, item_kind: String)
signal game_ended(ending: String, player_id: int)

const PLAYER_1 := 1
const PLAYER_2 := 2
const INVENTORY_SLOT_COUNT := 3

enum DoorState { CLOSED, OPEN, LOCKED }

var player_states: Dictionary = {}
var mansion_doors: Dictionary = {}
var mansion_door_defaults: Dictionary = {}
var mansion_trapdoors: Dictionary = {}
var mansion_trapdoor_defaults: Dictionary = {}

func register_mansion_door(id: String, initial_state: DoorState) -> void:
	if not mansion_door_defaults.has(id):
		mansion_door_defaults[id] = initial_state
		mansion_doors[id] = initial_state
	elif mansion_door_defaults[id] != initial_state:
		push_warning("Conflicting initial state for mansion door %s" % id)

func get_mansion_door_state(id: String) -> DoorState:
	return mansion_doors.get(id, DoorState.LOCKED)

func toggle_mansion_door(id: String, actor_id: int) -> void:
	if not mansion_doors.has(id):
		return
	var state := get_mansion_door_state(id)
	var key_slot := -1
	if state == DoorState.LOCKED:
		key_slot = find_inventory_slot("key")
		if key_slot == -1:
			print("P%d needs a key to open %s" % [actor_id, id])
			return
	var next_state := DoorState.CLOSED if state == DoorState.OPEN else DoorState.OPEN
	mansion_doors[id] = next_state
	if key_slot >= 0:
		take_inventory_slot(key_slot)
	emit_cross_map_event("mansion_door_changed", {"door_id": id, "state": next_state, "source_player": actor_id})

func open_mansion_door_for_monster(id: String, monster_player_id: int) -> bool:
	var state := get_mansion_door_state(id)
	if state == DoorState.LOCKED:
		return false
	if state == DoorState.CLOSED:
		mansion_doors[id] = DoorState.OPEN
		emit_cross_map_event("mansion_door_changed", {"door_id": id, "state": DoorState.OPEN, "source_monster": monster_player_id})
	return true

func register_mansion_trapdoor(id: String, initial_state: DoorState) -> void:
	if not mansion_trapdoor_defaults.has(id):
		mansion_trapdoor_defaults[id] = initial_state
		mansion_trapdoors[id] = initial_state
	elif mansion_trapdoor_defaults[id] != initial_state:
		push_warning("Conflicting initial state for mansion trapdoor %s" % id)

func get_mansion_trapdoor_state(id: String) -> DoorState:
	return mansion_trapdoors.get(id, DoorState.LOCKED)

func toggle_mansion_trapdoor(id: String, actor_id: int) -> void:
	if not mansion_trapdoors.has(id):
		return
	var state := get_mansion_trapdoor_state(id)
	var key_slot := -1
	if state == DoorState.LOCKED:
		key_slot = find_inventory_slot("key")
		if key_slot == -1:
			print("P%d needs a key to open %s" % [actor_id, id])
			return
	var next_state := DoorState.CLOSED if state == DoorState.OPEN else DoorState.OPEN
	mansion_trapdoors[id] = next_state
	if key_slot >= 0:
		take_inventory_slot(key_slot)
	emit_cross_map_event("mansion_trapdoor_changed", {"trapdoor_id": id, "state": next_state, "source_player": actor_id})

func open_mansion_trapdoor_for_monster(id: String, monster_player_id: int) -> bool:
	var state := get_mansion_trapdoor_state(id)
	if state == DoorState.LOCKED:
		return false
	if state == DoorState.CLOSED:
		mansion_trapdoors[id] = DoorState.OPEN
		emit_cross_map_event("mansion_trapdoor_changed", {"trapdoor_id": id, "state": DoorState.OPEN, "source_monster": monster_player_id})
	return true

var inventory_slots: Array[Dictionary] = [{}, {}, {}]
var inventory_actor_id := 0
var collected_collectible_ids: Dictionary = {}
var next_dropped_collectible_id := 1
var placed_items: Dictionary = {}
var placement_kinds: Dictionary = {}
var is_game_over := false
var ending := ""

func register_placement(placement_id: String, item_kind: String) -> void:
	if placement_id.is_empty():
		return
	if placement_kinds.has(placement_id) and placement_kinds[placement_id] != item_kind:
		push_warning("Conflicting item kind for placement %s" % placement_id)
		return
	placement_kinds[placement_id] = item_kind

func player_died(player_id: int) -> void:
	if is_game_over:
		return
	_finish_game("bad", player_id)

func _check_good_ending() -> void:
	if is_game_over or placement_kinds.is_empty():
		return
	var has_candle := false
	var has_music_box := false
	for placement_id in placement_kinds:
		var item_kind: String = placement_kinds[placement_id]
		has_candle = has_candle or item_kind == "candle"
		has_music_box = has_music_box or item_kind == "music_box"
		if placed_items.get(placement_id, "") != item_kind:
			return
	if has_candle and has_music_box:
		_finish_game("good", 0)

func _finish_game(result: String, player_id: int) -> void:
	is_game_over = true
	ending = result
	var death_detail := ""
	if player_id > 0:
		death_detail = " (P%d died)" % player_id
	print("Game ended: %s ending%s" % [result, death_detail])
	game_ended.emit(result, player_id)

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

func take_inventory_slot(slot_index: int) -> Dictionary:
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
	return find_inventory_slot(item_kind) >= 0

func find_inventory_slot(item_kind: String) -> int:
	for slot_index in INVENTORY_SLOT_COUNT:
		if inventory_slots[slot_index].get("kind", "") == item_kind:
			return slot_index
	return -1

func place_inventory_item(placement_id: String, item_kind: String, actor_id: int) -> bool:
	if is_game_over or placement_id.is_empty() or item_kind.is_empty() or placement_kinds.get(placement_id, "") != item_kind or placed_items.has(placement_id):
		return false
	var slot_index := find_inventory_slot(item_kind)
	if slot_index < 0:
		return false
	take_inventory_slot(slot_index)
	placed_items[placement_id] = item_kind
	placement_changed.emit(placement_id, item_kind)
	print("P%d placed %s on %s" % [actor_id, item_kind, placement_id])
	_check_good_ending()
	return true

func get_placed_item(placement_id: String) -> String:
	return str(placed_items.get(placement_id, ""))

func update_player_state(player_id: int, map_position: Vector2, sprite_offset_y: float, draw_order: int, animation: StringName, frame: int, frame_progress: float, is_playing: bool, facing_scale_x: float) -> void:
	player_states[player_id] = {
		"position": map_position,
		"sprite_offset_y": sprite_offset_y,
		"draw_order": draw_order,
		"animation": animation,
		"frame": frame,
		"frame_progress": frame_progress,
		"playing": is_playing,
		"facing_scale_x": facing_scale_x,
	}

func get_player_state(player_id: int) -> Dictionary:
	return player_states.get(player_id, {})

func emit_cross_map_event(event_name: String, payload: Dictionary = {}) -> void:
	cross_map_event.emit(event_name, payload)

func reset() -> void:
	is_game_over = false
	ending = ""
	mansion_doors = mansion_door_defaults.duplicate()
	mansion_trapdoors = mansion_trapdoor_defaults.duplicate()
	inventory_slots = [{}, {}, {}]
	inventory_actor_id = 0
	collected_collectible_ids.clear()
	placed_items.clear()
	next_dropped_collectible_id = 1
	inventory_changed.emit(inventory_slots)
	session_reset.emit()
