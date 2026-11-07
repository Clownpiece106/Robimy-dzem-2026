@tool
class_name MansionRoom
extends Node2D

@export var room_id := "Room":
	set(value):
		room_id = value
		queue_redraw()
@export var room_width := 540.0:
	set(value):
		room_width = value
		queue_redraw()
var room_visible := true

func update_visibility(player_position: Vector2, doors: Array) -> void:
	var inside := Rect2(global_position, Vector2(room_width, 540.0)).has_point(player_position)
	var has_door := false
	var unlocked := false
	for door in doors:
		if door.connects(self):
			has_door = true
			if not door.session.is_mansion_door_locked(door.door_id):
				unlocked = true
	var next_visible := inside or not has_door or unlocked
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
