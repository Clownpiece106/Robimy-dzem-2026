class_name CoopGhost
extends Node2D

const PLAYER_1_FRAMES := preload("res://Players/boy.tres")
const PLAYER_2_FRAMES := preload("res://Players/girl.tres")
const GHOST_DISTORTION := preload("res://shaders/ghost_distortion.gdshader")

var source_player_id: int
var session: GameSession
var sprite_offset_y := 0.0
var sprite: AnimatedSprite2D

func configure(id: int, game_session: GameSession) -> void:
	source_player_id = id
	session = game_session
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "Sprite"
		sprite.modulate.a = 0.5
		var distortion_material := ShaderMaterial.new()
		distortion_material.shader = GHOST_DISTORTION
		sprite.material = distortion_material
		add_child(sprite)
	sprite.sprite_frames = PLAYER_1_FRAMES if source_player_id == GameSession.PLAYER_1 else PLAYER_2_FRAMES
	sprite.scale = Vector2(0.25, 0.25)
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
	sprite.position.y = sprite_offset_y
	sprite.scale.x = state.get("facing_scale_x", 0.25)
	var animation: StringName = state.get("animation", &"default")
	if sprite.animation != animation:
		sprite.animation = animation
	sprite.set_frame_and_progress(state.get("frame", 0), state.get("frame_progress", 0.0))
	if state.get("playing", false):
		sprite.play()
	else:
		sprite.pause()
	visible = true
