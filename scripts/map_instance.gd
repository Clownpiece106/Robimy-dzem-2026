class_name MapInstance
extends Node2D

const PLAYER_DARK_SCENE := preload("res://Players/PlayerDark.tscn")
const PLAYER_LIGHT_SCENE := preload("res://Players/PlayerLight.tscn")

const MAP_WIDTH := 2400.0
const BACKGROUND_LANE_Y := 260.0
const FOREGROUND_LANE_Y := 390.0

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
	_create_world()

func configure_existing(game_session: GameSession, owning_player_id: int) -> void:
	session = game_session
	local_player_id = owning_player_id
	player = get_node("Player") as CoopPlayer
	player.configure_for_map(local_player_id, self)
	ghost = get_node("OtherPlayerGhost") as CoopGhost
	ghost.configure(GameSession.PLAYER_2 if local_player_id == GameSession.PLAYER_1 else GameSession.PLAYER_1, session, self)
	lever = get_node("Lever") as LinkedLever
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
	player.configure_for_map(local_player_id, self)

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
