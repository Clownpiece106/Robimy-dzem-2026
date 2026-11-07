class_name MapInstance
extends Node2D

const PLAYER_DARK_SCENE := preload("res://Players/PlayerDark.tscn")
const PLAYER_LIGHT_SCENE := preload("res://Players/PlayerLight.tscn")

const MAP_WIDTH := 3240.0
const MANSION_SCENE := preload("res://scenes/mansion_layout.tscn")
var mansion: Node2D
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

func configure_mansion(game_session: GameSession, owning_player_id: int) -> void:
	session = game_session
	local_player_id = owning_player_id
	_connect_collectible_signals()
	player = get_node("Player") as CoopPlayer
	player.configure_for_map(local_player_id, self, session)
	ghost = get_node("OtherPlayerGhost") as CoopGhost
	ghost.configure(GameSession.PLAYER_2 if local_player_id == GameSession.PLAYER_1 else GameSession.PLAYER_1, session, self)
	mansion = get_node("Mansion") as Node2D
	for room in mansion.get_children():
		room.configure(session)
		for object in room.get_children():
			if object is MansionDoor:
				object.configure(session)
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

	mansion = MANSION_SCENE.instantiate()
	mansion.name = "Mansion"
	mansion.z_index = -1
	add_child(mansion)
	for room in mansion.get_children():
		room.configure(session)
		for object in room.get_children():
			if object is MansionDoor:
				object.configure(session)

func constrain_mansion_movement(old_x: float, new_x: float, y: float) -> float:
	if mansion == null:
		return new_x
	if y < 0.0:
		return clampf(new_x, 540.0, 2159.0)
	new_x = clampf(new_x, 0.0, MAP_WIDTH - 1.0)
	for boundary in [540.0, 2160.0]:
		var id := "left" if boundary == 540.0 else "right"
		if session.is_mansion_door_locked(id) and ((old_x < boundary and new_x >= boundary) or (old_x >= boundary and new_x < boundary)):
			return boundary - 1.0 if old_x < boundary else boundary
	return new_x

func same_mansion_room(a: Vector2, b: Vector2) -> bool:
	if mansion == null:
		return true
	for room in mansion.get_children():
		var bounds := Rect2(room.global_position, Vector2(room.room_width, 540.0))
		if bounds.has_point(a) and bounds.has_point(b):
			return true
	return false

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
	if mansion != null and player != null:
		for room in mansion.get_children():
			room.update_visibility(player.global_position)
	if camera != null and player != null:
		camera.position = player.position
	if session != null and player != null:
		session.update_player_state(local_player_id, player.position, player.plane)
