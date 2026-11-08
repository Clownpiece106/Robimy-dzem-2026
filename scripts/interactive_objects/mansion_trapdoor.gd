@tool
class_name MansionTrapdoor
extends Node2D

@export var trapdoor_id := ""
@export var initial_state: GameSession.DoorState = GameSession.DoorState.OPEN:
	set(value):
		initial_state = value
		_update_visuals()

var session: GameSession

func _ready() -> void:
	_update_visuals()

func configure(game_session: GameSession) -> void:
	session = game_session
	if trapdoor_id.is_empty():
		push_warning("Mansion trapdoor %s needs a unique trapdoor_id" % get_path())
		return
	session.register_mansion_trapdoor(trapdoor_id, initial_state)
	if not session.cross_map_event.is_connected(_on_event):
		session.cross_map_event.connect(_on_event)
	if not session.session_reset.is_connected(_on_session_reset):
		session.session_reset.connect(_on_session_reset)
	_update_visuals()

func interact(player: CoopPlayer) -> void:
	if session != null:
		session.toggle_mansion_trapdoor(trapdoor_id, player.player_id)

func is_open() -> bool:
	return session != null and session.get_mansion_trapdoor_state(trapdoor_id) == GameSession.DoorState.OPEN

func traverse(player: CoopPlayer, destination: Marker2D) -> void:
	if not is_open() or destination == null:
		return
	player.global_position = destination.global_position
	player.velocity = Vector2.ZERO
	player.publish_position()
	print("P%d used trapdoor %s" % [player.player_id, trapdoor_id])

func _on_event(event_name: String, payload: Dictionary) -> void:
	if event_name == "mansion_trapdoor_changed" and payload.get("trapdoor_id") == trapdoor_id:
		_update_visuals()

func _on_session_reset() -> void:
	_update_visuals()

func _update_visuals() -> void:
	if not is_node_ready():
		return
	var open := initial_state == GameSession.DoorState.OPEN if session == null else is_open()
	for endpoint_name in ["FloorEndpoint", "CeilingEndpoint"]:
		var endpoint := get_node_or_null(endpoint_name)
		if endpoint == null:
			continue
		var closed_sprite := endpoint.get_node_or_null("ClosedSprite") as CanvasItem
		var open_sprite := endpoint.get_node_or_null("OpenSprite") as CanvasItem
		if closed_sprite != null:
			closed_sprite.visible = not open
		if open_sprite != null:
			open_sprite.visible = open
