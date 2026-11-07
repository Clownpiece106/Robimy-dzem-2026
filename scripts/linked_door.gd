class_name LinkedDoor
extends Node2D

var open := false

func configure(game_session: GameSession) -> void:
	game_session.cross_map_event.connect(_on_cross_map_event)
	game_session.session_reset.connect(_on_session_reset)
	queue_redraw()

func _on_session_reset() -> void:
	open = false
	queue_redraw()

func _on_cross_map_event(event_name: String, _payload: Dictionary) -> void:
	if event_name == "lever_a_opened":
		open = true
		queue_redraw()

func _draw() -> void:
	var color := Color("#68d391") if open else Color("#fc8181")
	draw_rect(Rect2(-30.0, -90.0, 60.0, 90.0), color, true)
	draw_string(ThemeDB.fallback_font, Vector2(-40.0, 24.0), "OPEN" if open else "DOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
