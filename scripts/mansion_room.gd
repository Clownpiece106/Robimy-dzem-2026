@tool
class_name MansionRoom
extends Node2D

const ROOM_BACKGROUNDS = preload("res://scenes/rooms/room_backgrounds.tres")

@export var room_id := "Room":
	set(value):
		room_id = value
		queue_redraw()
@export var room_width := 540.0:
	set(value):
		room_width = value
		queue_redraw()
var room_visible := true

func _ready() -> void:
	if not ROOM_BACKGROUNDS.changed.is_connected(queue_redraw):
		ROOM_BACKGROUNDS.changed.connect(queue_redraw)

func _background_texture() -> Texture2D:
	# The reusable room scenes retain their original widths; the mansion layout
	# overrides them with the current room dimensions.
	if room_width <= 960.0:
		return ROOM_BACKGROUNDS.small
	if is_equal_approx(room_width, 1620.0) or room_width > 1920.0:
		return ROOM_BACKGROUNDS.big
	return ROOM_BACKGROUNDS.medium

func update_visibility(player_position: Vector2, doors: Array) -> void:
	var inside := Rect2(global_position, Vector2(room_width, 540.0)).has_point(player_position)
	var has_door := false
	var open_door := false
	for door in doors:
		if door.connects(self):
			has_door = true
			if door.is_open():
				open_door = true
	var next_visible := inside or not has_door or open_door
	if room_visible != next_visible:
		room_visible = next_visible
		queue_redraw()

func _draw() -> void:
	if not room_visible:
		return
	var background := _background_texture()
	if background != null:
		draw_texture_rect(background, Rect2(0, 0, room_width, 540), false)
		return
	draw_rect(Rect2(0, 0, room_width, 540), Color("#252233"))
	draw_rect(Rect2(0, 0, room_width, 540), Color("#65546b"), false, 5.0)
	draw_rect(Rect2(0, 408, room_width, 12), Color("#887980"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 45), room_id.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#c9bcc5"))
