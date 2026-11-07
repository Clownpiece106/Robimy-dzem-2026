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
	return a != b and connects(a) and connects(b)

func interact(player: CoopPlayer) -> void:
	if session != null and not door_id.is_empty():
		session.set_mansion_door_locked(door_id, not session.is_mansion_door_locked(door_id), player.player_id)

func _on_event(event_name: String, payload: Dictionary) -> void:
	if event_name == "mansion_door_changed" and payload.get("door_id") == door_id:
		queue_redraw()

func _draw() -> void:
	var locked := initially_locked if session == null else session.is_mansion_door_locked(door_id)
	draw_rect(Rect2(-24, -110, 48, 110), Color("#a05d60") if locked else Color("#79a887"))
	draw_string(ThemeDB.fallback_font, Vector2(-42, 24), "LOCKED" if locked else "UNLOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
