class_name LinkedDoor
extends Interactable

var open := false
var session: GameSession
@onready var blocker_shape: CollisionShape2D = $DoorBlocker/CollisionShape2D

func configure(game_session: GameSession) -> void:
	session = game_session
	session.cross_map_event.connect(_on_cross_map_event)
	session.session_reset.connect(_on_session_reset)
	_add_interaction_area()
	queue_redraw()

func _add_interaction_area() -> void:
	if has_node("InteractionArea"):
		return
	var area := Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1
	area.collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(80.0, 120.0)
	collision_shape.shape = rectangle
	area.add_child(collision_shape)
	add_child(area)

func can_interact(_player: CoopPlayer) -> bool:
	return not open and session != null

func interact(player: CoopPlayer) -> void:
	if not can_interact(player):
		return
	if session.take_inventory_slot(session.find_inventory_slot("key")).is_empty():
		print("P%d needs a key to unlock %s" % [player.player_id, name])
		return
	session.emit_cross_map_event("door_unlocked", {"source_player": player.player_id})

func _on_session_reset() -> void:
	open = false
	blocker_shape.set_deferred("disabled", false)
	queue_redraw()

func _on_cross_map_event(event_name: String, payload: Dictionary) -> void:
	if event_name == "door_unlocked":
		open = true
		blocker_shape.set_deferred("disabled", true)
		print("Door unlocked by player %d using the shared key" % payload.get("source_player", 0))
		queue_redraw()

func _draw() -> void:
	var color := Color("#68d391") if open else Color("#fc8181")
	draw_rect(Rect2(-30.0, -90.0, 60.0, 90.0), color, true)
	draw_string(ThemeDB.fallback_font, Vector2(-40.0, 24.0), "OPEN" if open else "DOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
