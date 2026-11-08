class_name CoopGhost
extends Node2D

var source_player_id: int
var session: GameSession
var map_instance: Node
var sprite_offset_y := 0.0

func configure(id: int, game_session: GameSession, owning_map: Node) -> void:
	source_player_id = id
	session = game_session
	map_instance = owning_map
	# Read both players' positions after movement and interactions for this frame.
	process_priority = 1
	visible = false

func _process(_delta: float) -> void:
	if session == null:
		return
	var state := session.get_player_state(source_player_id)
	if state.is_empty():
		return
	position = state.position
	sprite_offset_y = state.sprite_offset_y
	z_index = state.draw_order
	visible = map_instance.same_mansion_room(map_instance.player.position, position)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0.0, sprite_offset_y))
	var ghost_color := Color(0.7, 0.9, 1.0, 0.5)
	draw_rect(Rect2(-16.0, -18.0, 32.0, 34.0), ghost_color)
	draw_circle(Vector2(0.0, -27.0), 10.0, ghost_color)
	draw_string(ThemeDB.fallback_font, Vector2(-28.0, -44.0), "GHOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ghost_color)
