class_name MansionDoor
extends Interactable
@export var door_id := ""
var session: GameSession
func configure(s: GameSession) -> void:
	session = s
	session.cross_map_event.connect(_on_event)
	session.session_reset.connect(queue_redraw)
	queue_redraw()
func interact(player: CoopPlayer) -> void:
	if session != null:
		session.set_mansion_door_locked(door_id, not session.is_mansion_door_locked(door_id), player.player_id)
func _on_event(event_name: String, payload: Dictionary) -> void:
	if event_name == "mansion_door_changed" and payload.get("door_id") == door_id:
		queue_redraw()
func _draw() -> void:
	var locked := session == null or session.is_mansion_door_locked(door_id)
	draw_rect(Rect2(-24, -110, 48, 110), Color("#a05d60") if locked else Color("#79a887"))
	draw_string(ThemeDB.fallback_font, Vector2(-42, 24), "LOCKED" if locked else "UNLOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
