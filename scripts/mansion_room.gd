class_name MansionRoom
extends Node2D
@export var room_id := ""
@export var room_width := 540.0
@export var door_ids: Array[String] = []
var session: GameSession
var room_visible := true
func configure(s: GameSession) -> void:
	session = s
func update_visibility(player_position: Vector2) -> void:
	var inside := Rect2(global_position, Vector2(room_width, 540.0)).has_point(player_position)
	var unlocked := door_ids.is_empty()
	for id in door_ids:
		if not session.is_mansion_door_locked(id):
			unlocked = true
	var next_visible := inside or unlocked
	if room_visible != next_visible:
		room_visible = next_visible
		queue_redraw()
func _draw() -> void:
	if not room_visible:
		return
	draw_rect(Rect2(0, 0, room_width, 540), Color("#252233"))
	draw_rect(Rect2(0, 0, room_width, 540), Color("#65546b"), false, 5.0)
	draw_rect(Rect2(0, 408, room_width, 12), Color("#887980"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 45), room_id.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#c9bcc5"))
