class_name LinkedLever
extends Interactable

var session: GameSession
var activated := false

func configure(game_session: GameSession) -> void:
	session = game_session
	session.session_reset.connect(_on_session_reset)
	_add_interaction_area()
	queue_redraw()

func _add_interaction_area() -> void:
	if has_node("InteractionArea"):
		return
	var area := Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0
	area.collision_mask = 1
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(48.0, 60.0)
	collision_shape.shape = rectangle
	area.add_child(collision_shape)
	add_child(area)

func _on_session_reset() -> void:
	activated = false
	queue_redraw()

func can_interact(_player: CoopPlayer) -> bool:
	return not activated and session != null

func interact(player: CoopPlayer) -> void:
	if not can_interact(player):
		return
	activated = true
	print("Interaction succeeded: P%d activated %s" % [player.player_id, name])
	session.emit_cross_map_event("lever_a_opened", {"source_player": player.player_id})
	queue_redraw()

func _draw() -> void:
	var color := Color("#f6e05e") if not activated else Color("#a0aec0")
	draw_rect(Rect2(-18.0, -50.0, 36.0, 50.0), color, true)
	draw_string(ThemeDB.fallback_font, Vector2(-36.0, 22.0), "LEVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
