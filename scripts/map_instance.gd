class_name MapInstance
extends Node2D

const PLAYER_DARK_SCENE := preload("res://Players/PlayerDark.tscn")
const PLAYER_LIGHT_SCENE := preload("res://Players/PlayerLight.tscn")
const INVERT_ENVIRONMENT := preload("res://shaders/invert_environment.tres")

const MANSION_SCENE := preload("res://scenes/mansion_layout.tscn")
var mansion: Node2D
var mansion_rooms: Array[MansionRoom] = []
var mansion_doors: Array[MansionDoor] = []
var mansion_trapdoors: Array[MansionTrapdoor] = []
const ROOM_VIEW_SIZE := Vector2(540.0, 540.0)

@onready var bg_physics_tile_map := get_node_or_null("BgPhysicsTileMap") as TileMapLayer
@onready var fg_physics_tile_map := get_node_or_null("FgPhysicsTileMap") as TileMapLayer


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
	_apply_environment_appearance()
	_connect_collectible_signals()
	player = get_node("Player") as CoopPlayer
	player.configure_for_map(local_player_id, self, session)
	player.publish_position()
	ghost = get_node("OtherPlayerGhost") as CoopGhost
	ghost.configure(GameSession.PLAYER_2 if local_player_id == GameSession.PLAYER_1 else GameSession.PLAYER_1, session)
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
	mansion = get_node("Mansion") as Node2D
	_configure_layout()
	player = get_node("Player") as CoopPlayer
	player.configure_for_map(local_player_id, self, session)
	_spawn_in_attic()
	ghost = get_node("OtherPlayerGhost") as CoopGhost
	ghost.configure(GameSession.PLAYER_2 if local_player_id == GameSession.PLAYER_1 else GameSession.PLAYER_1, session)
	set_camera(get_node("Camera2D") as Camera2D)

func _create_world() -> void:
	mansion = MANSION_SCENE.instantiate()
	mansion.name = "Mansion"
	mansion.z_index = -1
	add_child(mansion)
	_configure_layout()

	var player_scene: PackedScene = PLAYER_DARK_SCENE if local_player_id == GameSession.PLAYER_1 else PLAYER_LIGHT_SCENE
	player = player_scene.instantiate() as CoopPlayer
	player.name = "Player%d" % local_player_id
	player.player_id = local_player_id
	add_child(player)
	player.configure_for_map(local_player_id, self, session)
	_spawn_in_attic()

	ghost = CoopGhost.new()
	ghost.name = "Player%dGhost" % (GameSession.PLAYER_1 if local_player_id == GameSession.PLAYER_2 else GameSession.PLAYER_2)
	add_child(ghost)
	ghost.configure(GameSession.PLAYER_1 if local_player_id == GameSession.PLAYER_2 else GameSession.PLAYER_2, session)

func _spawn_in_attic() -> void:
	var spawn := mansion.find_child("Player%dSpawn" % local_player_id, true, false) as Marker2D
	if spawn == null:
		push_error("Missing spawn marker for player %d" % local_player_id)
		return
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	player.set_depth_plane(CoopPlayer.DepthPlane.FOREGROUND)
	player.sprite_depth_offset = 0.0
	player.sprite.position.y = 0.0
	player.publish_position()

func _configure_layout() -> void:
	bg_physics_tile_map = mansion.get_node_or_null("PhysicsTileMapBg") as TileMapLayer
	fg_physics_tile_map = mansion.get_node_or_null("PhysicsTileMapFg") as TileMapLayer
	mansion_rooms.clear()
	mansion_doors.clear()
	mansion_trapdoors.clear()
	_collect_layout_nodes(mansion)
	_apply_environment_appearance()
	for door in mansion_doors:
		door.configure(session)
	for trapdoor in mansion_trapdoors:
		trapdoor.configure(session)

func _apply_environment_appearance() -> void:
	var environment_material: Material = INVERT_ENVIRONMENT if local_player_id == GameSession.PLAYER_2 else null
	for room in mansion_rooms:
		room.material = environment_material
	for trapdoor in mansion_trapdoors:
		trapdoor.material = environment_material
	for node_name in ["Background", "Floor", "BgPhysicsTileMap", "FgPhysicsTileMap"]:
		var environment_node := get_node_or_null(node_name) as CanvasItem
		if environment_node != null:
			environment_node.material = environment_material

func _collect_layout_nodes(node: Node) -> void:
	if node is MansionRoom:
		mansion_rooms.append(node as MansionRoom)
	if node is MansionDoor:
		mansion_doors.append(node as MansionDoor)
	if node is MansionTrapdoor:
		mansion_trapdoors.append(node as MansionTrapdoor)
	for child in node.get_children():
		_collect_layout_nodes(child)

func _room_at(point: Vector2) -> MansionRoom:
	for room in mansion_rooms:
		if Rect2(to_local(room.global_position), Vector2(room.room_width, ROOM_VIEW_SIZE.y)).has_point(point):
			return room
	return null

func constrain_mansion_movement(old_x: float, new_x: float, y: float) -> float:
	if mansion == null or is_equal_approx(old_x, new_x):
		return new_x
	var current := _room_at(Vector2(old_x, y))
	if current == null:
		return old_x
	var room_left := to_local(current.global_position).x
	var room_right := room_left + current.room_width
	if new_x >= room_left and new_x < room_right:
		return new_x
	var moving_right := new_x > old_x
	var boundary := room_right if moving_right else room_left
	var other := _room_at(Vector2(boundary + (0.01 if moving_right else -0.01), y))
	var floor_top := to_local(current.global_position).y
	for door in mansion_doors:
		var door_pos := to_local(door.global_position)
		var at_boundary := absf(door_pos.x - boundary) < 1.0 and door_pos.y >= floor_top and door_pos.y < floor_top + ROOM_VIEW_SIZE.y
		if other != null and at_boundary and door.connects_pair(current, other) and door.is_open():
			return new_x
	return boundary - 0.01 if moving_right else boundary

func same_mansion_room(a: Vector2, b: Vector2) -> bool:
	if mansion == null:
		return true
	var room := _room_at(a)
	return room != null and room == _room_at(b)

func set_camera(active_camera: Camera2D) -> void:
	camera = active_camera
	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
	camera.limit_bottom = 10000000
	camera.enabled = true
	camera.make_current()
	_update_mansion_camera()

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
	player.health = CoopPlayer.MAX_HEALTH
	for collectible in _get_collectibles():
		if collectible.spawned_at_runtime:
			collectible.set_collected_from_session()
			collectible.queue_free()
		else:
			collectible.reset_from_session()
	if mansion != null:
		_spawn_in_attic()

func _find_collectible(collectible_id: String) -> CollectibleItem:
	for collectible in _get_collectibles():
		if collectible.shared_object_id == collectible_id and not collectible.is_queued_for_deletion():
			return collectible
	return null

func _get_collectibles() -> Array[CollectibleItem]:
	var collectibles: Array[CollectibleItem] = []
	for child in find_children("*", "Node2D", true, false):
		if child is CollectibleItem:
			collectibles.append(child)
	return collectibles

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
		for room in mansion_rooms:
			room.update_visibility(player.global_position, mansion_doors)
	if camera != null and player != null:
		if mansion != null:
			_update_mansion_camera()
		else:
			camera.position = player.position

func _update_mansion_camera() -> void:
	# Match the logical room dimensions to the actual split viewport size.
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	camera.zoom = viewport_size / ROOM_VIEW_SIZE
	for room in mansion_rooms:
		var bounds := Rect2(to_local(room.global_position), Vector2(room.room_width, ROOM_VIEW_SIZE.y))
		if bounds.has_point(player.position):
			camera.position = Vector2(
				clampf(player.position.x, bounds.position.x + ROOM_VIEW_SIZE.x / 2.0, bounds.end.x - ROOM_VIEW_SIZE.x / 2.0),
				bounds.position.y + ROOM_VIEW_SIZE.y / 2.0
			)
			return
