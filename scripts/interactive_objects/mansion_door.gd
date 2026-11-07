@tool
class_name MansionDoor
extends Interactable

@export var door_id := ""
@export var initially_locked := true
@export var room_a: NodePath
@export var room_b: NodePath
var session: GameSession

func configure(s: GameSession) -> void:
	session = s
	if door_id.is_empty():
		push_warning("Mansion door %s needs a unique door_id" % get_path())
		return
	session.register_mansion_door(door_id, initially_locked)
	session.cross_map_event.connect(_on_event)
	session.session_reset.connect(queue_redraw)
	queue_redraw()

func connects(room: Node) -> bool:
	return room != null and (get_node_or_null(room_a) == room or get_node_or_null(room_b) == room)

func connects_pair(a: Node, b: Node) -> bool:
	if a == b:
		return false
	if connects(a) and connects(b):
		return true
	# Keep the connector usable when room nodes were renamed in the layout.
	# The door is still authoritative by its placement at the shared boundary.
	var room_a_node := a as MansionRoom
	var room_b_node := b as MansionRoom
	if room_a_node == null or room_b_node == null:
		return false
	var door_position := global_position
	var a_rect := Rect2(room_a_node.global_position, Vector2(room_a_node.room_width, 540.0))
	var b_rect := Rect2(room_b_node.global_position, Vector2(room_b_node.room_width, 540.0))
	var horizontal_edge := is_equal_approx(a_rect.end.x, b_rect.position.x) or is_equal_approx(b_rect.end.x, a_rect.position.x)
	return horizontal_edge and absf(door_position.x - (a_rect.end.x if is_equal_approx(a_rect.end.x, b_rect.position.x) else b_rect.end.x)) < 1.0 and door_position.y >= a_rect.position.y and door_position.y <= a_rect.end.y

func interact(player: CoopPlayer) -> void:
	if session == null or door_id.is_empty():
		return
	var state := session.get_mansion_door_state(door_id)
	if state == GameSession.MansionDoorState.LOCKED:
		if session.has_inventory_item("key"):
			session.set_mansion_door_state(door_id, GameSession.MansionDoorState.OPEN, player.player_id)
		else:
			print("P%d needs a key for door %s" % [player.player_id, door_id])
	else:
		var next := GameSession.MansionDoorState.CLOSED if state == GameSession.MansionDoorState.OPEN else GameSession.MansionDoorState.OPEN
		session.set_mansion_door_state(door_id, next, player.player_id)

func _on_event(event_name: String, payload: Dictionary) -> void:
	if event_name == "mansion_door_changed" and payload.get("door_id") == door_id:
		queue_redraw()

func _draw() -> void:
	var state := GameSession.MansionDoorState.LOCKED if initially_locked else GameSession.MansionDoorState.OPEN
	if session != null:
		state = session.get_mansion_door_state(door_id)
	var colors := [Color("#79a887"), Color("#b28b5a"), Color("#a05d60")]
	var labels := ["OPEN", "CLOSED", "LOCKED"]
	draw_rect(Rect2(-24, -110, 48, 110), colors[state])
	draw_string(ThemeDB.fallback_font, Vector2(-42, 24), labels[state], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
