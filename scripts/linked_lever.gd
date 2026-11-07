class_name LinkedLever
extends Node2D

var session: GameSession
var activated := false

func configure(game_session: GameSession) -> void:
	session = game_session
	session.session_reset.connect(_on_session_reset)
	queue_redraw()

func _on_session_reset() -> void:
	activated = false
	queue_redraw()

func _process(_delta: float) -> void:
	if activated or session == null:
		return
	var player_state := session.get_player_state(GameSession.PLAYER_1)
	if absf(player_state.position.x - position.x) <= 36.0 and player_state.plane == CoopPlayer.DepthPlane.FOREGROUND:
		activated = true
		session.emit_cross_map_event("lever_a_opened", {"source_player": GameSession.PLAYER_1})
		queue_redraw()

func _draw() -> void:
	var color := Color("#f6e05e") if not activated else Color("#a0aec0")
	draw_rect(Rect2(-18.0, -50.0, 36.0, 50.0), color, true)
	draw_string(ThemeDB.fallback_font, Vector2(-36.0, 22.0), "LEVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
