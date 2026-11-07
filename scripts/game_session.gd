class_name GameSession
extends Node

signal cross_map_event(event_name: String, payload: Dictionary)
signal session_reset

const PLAYER_1 := 1
const PLAYER_2 := 2

var player_states: Dictionary = {
	PLAYER_1: {"position": Vector2(220.0, 0.0), "plane": 1},
	PLAYER_2: {"position": Vector2(220.0, 0.0), "plane": 1},
}

func update_player_state(player_id: int, world_position: Vector2, plane: int) -> void:
	player_states[player_id] = {"position": world_position, "plane": plane}

func get_player_state(player_id: int) -> Dictionary:
	return player_states.get(player_id, {"position": Vector2.ZERO, "plane": 1})

func emit_cross_map_event(event_name: String, payload: Dictionary = {}) -> void:
	cross_map_event.emit(event_name, payload)

func reset() -> void:
	player_states[PLAYER_1] = {"position": Vector2(220.0, 0.0), "plane": 1}
	player_states[PLAYER_2] = {"position": Vector2(220.0, 0.0), "plane": 1}
	session_reset.emit()
