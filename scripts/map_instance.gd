class_name MapInstance
extends Node2D

const PLAYER_DARK_SCENE := preload("res://Players/PlayerDark.tscn")
const PLAYER_LIGHT_SCENE := preload("res://Players/PlayerLight.tscn")

const MAP_WIDTH := 2400.0
const BACKGROUND_LANE_Y := 260.0
const FOREGROUND_LANE_Y := 390.0

@onready var bg_physics_tile_map = $BgPhysicsTileMap
@onready var fg_physics_tile_map = $FgPhysicsTileMap


var session: GameSession
var local_player_id: int
var player: CoopPlayer
var ghost: CoopGhost
var door: LinkedDoor
var lever: LinkedLever
var camera: Camera2D

func configure(game_session: GameSession, owning_player_id: int) -> void:
	session = game_session
	local_player_id = owning_player_id
	_connect_collectible_signals()
	_create_world()

func configure_existing(game_session: GameSession, owning_player_id: int) -> void:
	session = game_session
	local_player_id = owning_player_id
	_connect_collectible_signals()
	player = get_node("Player") as CoopPlayer
	player.configure_for_map(local_player_id, self, session)
	ghost = get_node("OtherPlayerGhost") as CoopGhost
	ghost.configure(GameSession.PLAYER_2 if local_player_id == GameSession.PLAYER_1 else GameSession.PLAYER_1, session, self)
	lever = get_node_or_null("Lever") as LinkedLever
	if lever != null:
		lever.configure(session)
	door = get_node("Door") as LinkedDoor
	door.configure(session)
	camera = get_node("Camera2D") as Camera2D
	camera.enabled = true
	camera.make_current()

func get_lane_y(plane: int) -> float:
	return BACKGROUND_LANE_Y if plane == CoopPlayer.DepthPlane.BACKGROUND else FOREGROUND_LANE_Y

func _create_world() -> void:
	var player_scene: PackedScene = PLAYER_DARK_SCENE if local_player_id == GameSession.PLAYER_1 else PLAYER_LIGHT_SCENE
	player = player_scene.instantiate() as CoopPlayer
	player.name = "Player%d" % local_player_id
	player.player_id = local_player_id
	player.position = Vector2(220.0, FOREGROUND_LANE_Y)
	add_child(player)
	player.configure_for_map(local_player_id, self, session)

	ghost = CoopGhost.new()
	ghost.name = "Player%dGhost" % (GameSession.PLAYER_1 if local_player_id == GameSession.PLAYER_2 else GameSession.PLAYER_2)
	add_child(ghost)
	ghost.configure(GameSession.PLAYER_1 if local_player_id == GameSession.PLAYER_2 else GameSession.PLAYER_2, session, self)

	if local_player_id == GameSession.PLAYER_1:
		lever = LinkedLever.new()
		lever.position = Vector2(1050.0, FOREGROUND_LANE_Y)
		add_child(lever)
		lever.configure(session)
	else:
		lever = LinkedLever.new()
		lever.name = "Lever"
		lever.position = Vector2(1050.0, FOREGROUND_LANE_Y)
		add_child(lever)
		lever.configure(session)
		door = LinkedDoor.new()
		door.position = Vector2(1500.0, FOREGROUND_LANE_Y)
		add_child(door)
		door.configure(session)
	queue_redraw()

func set_camera(active_camera: Camera2D) -> void:
	camera = active_camera

func _connect_collectible_signals() -> void:
	if not session.collectible_collected.is_connected(_on_collectible_collected):
		session.collectible_collected.connect(_on_collectible_collected)
	if not session.collectible_dropped.is_connected(_on_collectible_dropped):
		session.collectible_dropped.connect(_on_collectible_dropped)
	if not session.session_reset.is_connected(_on_session_reset):
		session.session_reset.connect(_on_session_reset)

func _on_collectible_collected(collectible_id: String) -> void:
	var collectible := _find_collectible(collectible_id)
	if collectible != null:
		collectible.set_collected_from_session()

func _on_collectible_dropped(collectible_id: String, item: Dictionary, world_position: Vector2) -> void:
	spawn_dropped_collectible(collectible_id, item, world_position)

func _on_session_reset() -> void:
	for child in get_children():
		if child is CollectibleItem:
			var collectible := child as CollectibleItem
			if collectible.spawned_at_runtime:
				collectible.queue_free()
			else:
				collectible.reset_from_session()

func _find_collectible(collectible_id: String) -> CollectibleItem:
	for child in get_children():
		if child is CollectibleItem and child.shared_object_id == collectible_id:
			return child as CollectibleItem
	return null

func spawn_dropped_collectible(collectible_id: String, item: Dictionary, drop_position: Vector2) -> void:
	var collectible := CollectibleItem.new()
	collectible.name = "%sDropped" % str(item.get("kind", "Collectible")).capitalize()
	collectible.shared_object_id = collectible_id
	collectible.item_kind = str(item.get("kind", "collectible"))
	collectible.item_label = str(item.get("label", "Collectible"))
	collectible.spawned_at_runtime = true
	collectible.position = drop_position
	add_child(collectible)

func _process(_delta: float) -> void:
	if camera != null and player != null:
		camera.position = player.position
	if session != null and player != null:
		session.update_player_state(local_player_id, player.position, player.plane)

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, MAP_WIDTH, 540.0), Color("#121827"), true)
	draw_rect(Rect2(0.0, BACKGROUND_LANE_Y + 18.0, MAP_WIDTH, 6.0), Color("#4a5568"), true)
	draw_rect(Rect2(0.0, FOREGROUND_LANE_Y + 18.0, MAP_WIDTH, 6.0), Color("#718096"), true)
	draw_string(ThemeDB.fallback_font, Vector2(40.0, 48.0), "PARALLEL MAP %d" % local_player_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#cbd5e0"))
	draw_string(ThemeDB.fallback_font, Vector2(40.0, BACKGROUND_LANE_Y - 30.0), "BACKGROUND PLANE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#718096"))
	draw_string(ThemeDB.fallback_font, Vector2(40.0, FOREGROUND_LANE_Y - 30.0), "FOREGROUND PLANE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#a0aec0"))
