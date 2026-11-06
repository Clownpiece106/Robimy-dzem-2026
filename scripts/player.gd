class_name CoopPlayer
extends Node2D

enum Plane { BACKGROUND, FOREGROUND }

const SPEED := 220.0
const MAP_LEFT := 80.0
const MAP_RIGHT := 2320.0

var player_id: int
var session: GameSession
var map_instance: Node
var left_action: String
var right_action: String
var background_action: String
var foreground_action: String
var plane: int = Plane.FOREGROUND

func configure(id: int, game_session: GameSession, owning_map: Node) -> void:
	player_id = id
	session = game_session
	map_instance = owning_map
	left_action = "p%d_move_left" % player_id
	right_action = "p%d_move_right" % player_id
	background_action = "p%d_move_background" % player_id
	foreground_action = "p%d_move_foreground" % player_id
	position = Vector2(220.0, map_instance.get_lane_y(plane))
	session.update_player_state(player_id, position, plane)
	session.session_reset.connect(_on_session_reset)
	queue_redraw()

func _on_session_reset() -> void:
	plane = Plane.FOREGROUND
	position = Vector2(220.0, map_instance.get_lane_y(plane))
	session.update_player_state(player_id, position, plane)
	queue_redraw()

func _process(delta: float) -> void:
	if session == null:
		return

	var direction := Input.get_axis(left_action, right_action)
	position.x = clampf(position.x + direction * SPEED * delta, MAP_LEFT, MAP_RIGHT)
	if Input.is_action_just_pressed(background_action):
		plane = Plane.BACKGROUND
	if Input.is_action_just_pressed(foreground_action):
		plane = Plane.FOREGROUND
	position.y = map_instance.get_lane_y(plane)
	session.update_player_state(player_id, position, plane)
	queue_redraw()

func _draw() -> void:
	var body_color := Color("#4fd1c5") if player_id == 1 else Color("#f6ad55")
	draw_rect(Rect2(-16.0, -34.0, 32.0, 34.0), body_color)
	draw_circle(Vector2(0.0, -43.0), 10.0, body_color.lightened(0.15))
	draw_string(ThemeDB.fallback_font, Vector2(-24.0, 22.0), "P%d" % player_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
