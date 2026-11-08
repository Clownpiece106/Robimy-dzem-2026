@tool
class_name MansionDoor
extends Interactable

@export var door_id := ""
@export var initial_state: GameSession.DoorState = GameSession.DoorState.LOCKED:
	set(value):
		initial_state = value
		queue_redraw()
@export var room_a: NodePath
@export var room_b: NodePath
var session: GameSession
@onready var interaction_collision_shape = $InteractionArea/CollisionShape2D

@export var text_door_open : Texture2D
@export var text_door_closed : Texture2D
@onready var door_l = $DoorL
@onready var door_r = $DoorR

func configure(s: GameSession) -> void:
	session = s
	if door_id.is_empty():
		push_warning("Mansion door %s needs a unique door_id" % get_path())
		return
	session.register_mansion_door(door_id, initial_state)
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
	if session != null:
		session.toggle_mansion_door(door_id, player.player_id)
	
	if(is_open()):
		door_l.texture = text_door_open
		door_r.texture = text_door_open
	else:
		door_l.texture = text_door_closed
		door_r.texture = text_door_closed

func is_open() -> bool:
	return session != null and session.get_mansion_door_state(door_id) == GameSession.DoorState.OPEN

func _on_event(event_name: String, payload: Dictionary) -> void:
	if event_name == "mansion_door_changed" and payload.get("door_id") == door_id:
		queue_redraw()

func _draw() -> void:
	var state := initial_state if session == null else session.get_mansion_door_state(door_id)
	var color := Color("c4996100")
	var label := "CLOSED"
	match state:
		GameSession.DoorState.LOCKED:
			color = Color("a05d6000")
			label = "LOCKED"
		GameSession.DoorState.OPEN:
			color = Color("79a88700")
			label = "OPEN"
	var frame := Rect2(-24, -110, 48, 110)
	if state == GameSession.DoorState.OPEN:
		draw_rect(frame, color, false, 3.0)
	else:
		draw_rect(frame, color)
	draw_string(ThemeDB.fallback_font, Vector2(-42, 24), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


#Teleport the player to the other side
func _on_body_entered(body):
	if(body.is_in_group("Player"))&&(is_open()):
		if(body.position.x>position.x):
			body.position.x = position.x - (interaction_collision_shape.shape.size.x/2)
		else:
			body.position.x = position.x + (interaction_collision_shape.shape.size.x/2)
		#print(position)
		#print(interaction_collision_shape.shape.size)
		#print(str(position.x+interaction_collision_shape.shape.size.x))
