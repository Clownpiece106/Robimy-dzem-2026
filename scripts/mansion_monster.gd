class_name MansionMonster
extends Node2D

signal player_captured(player_id: int)

enum State { PATROL, PURSUIT, SEARCH }
@export var patrol_speed := 110.0
@export var pursuit_speed := 170.0
@export var search_duration := 4.0
@export var capture_distance := 35.0

var state := State.PATROL
var map: MapInstance
var session: GameSession
var player: CoopPlayer
var edges: Array[Dictionary] = []
var target_room: MansionRoom
var last_known_position: Vector2
var search_left := 0.0
var captured := false
var spawn_position: Vector2
var rng := RandomNumberGenerator.new()
var local_patrol_x := INF

func configure(owning_map: MapInstance, game_session: GameSession, local_player: CoopPlayer) -> void:
	map = owning_map
	session = game_session
	player = local_player
	spawn_position = position
	rng.randomize()
	_build_graph()
	session.session_reset.connect(_reset)

func _reset() -> void:
	position = spawn_position
	state = State.PATROL
	target_room = null
	captured = false

func _room_at_global(point: Vector2) -> MansionRoom:
	return map._room_at(map.to_local(point))

func _build_graph() -> void:
	edges.clear()
	for door in map.mansion_doors:
		var left := _room_at_global(door.global_position + Vector2(-2, 0))
		var right := _room_at_global(door.global_position + Vector2(2, 0))
		if left != null and right != null and door.connects_pair(left, right):
			edges.append({"from": left, "to": right, "entry": door.global_position + Vector2(-3, 0), "exit": door.global_position + Vector2(3, 0), "door": door})
			edges.append({"from": right, "to": left, "entry": door.global_position + Vector2(3, 0), "exit": door.global_position + Vector2(-3, 0), "door": door})
	_collect_vertical(map.mansion)

func _collect_vertical(node: Node) -> void:
	if node is MansionLadder:
		var endpoint := node as MansionLadder
		var destination := endpoint.get_node_or_null(endpoint.destination) as Marker2D
		if destination != null:
			var from_room := _room_at_global(endpoint.global_position)
			var to_room := _room_at_global(destination.global_position)
			if from_room != null and to_room != null and from_room != to_room:
				edges.append({"from": from_room, "to": to_room, "entry": endpoint.global_position, "exit": destination.global_position})
	for child in node.get_children():
		_collect_vertical(child)

func _route(from_room: MansionRoom, to_room: MansionRoom) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if from_room == null or to_room == null or from_room == to_room:
		return result
	var queue: Array[MansionRoom] = [from_room]
	var previous := {from_room: {}}
	while not queue.is_empty():
		var room := queue.pop_front() as MansionRoom
		for edge in edges:
			if edge.from != room or previous.has(edge.to):
				continue
			if edge.has("door") and session.is_mansion_door_locked(edge.door.door_id):
				continue
			previous[edge.to] = edge
			if edge.to == to_room:
				var cursor := to_room
				while cursor != from_room:
					var step: Dictionary = previous[cursor]
					result.push_front(step)
					cursor = step.from
				return result
			queue.append(edge.to)
	return result

func _physics_process(delta: float) -> void:
	if map == null or player == null:
		return
	var room := _room_at_global(global_position)
	var player_room := _room_at_global(player.global_position)
	if room == null:
		return
	if room == player_room:
		state = State.PURSUIT
		last_known_position = player.global_position
		target_room = room
		search_left = search_duration
	elif state == State.PURSUIT:
		state = State.SEARCH
		target_room = _room_at_global(last_known_position)
	if room == player_room and absf(global_position.x - player.global_position.x) <= capture_distance:
		if not captured:
			captured = true
			player_captured.emit(player.player_id)
			print("Monster captured P%d" % player.player_id)
	else:
		captured = false
	if state == State.PATROL and (target_room == null or target_room == room or _route(room, target_room).is_empty()):
		_choose_patrol_room(room)
	if target_room == null:
		if state == State.PATROL:
			if is_inf(local_patrol_x) or is_equal_approx(global_position.x, local_patrol_x):
				local_patrol_x = rng.randf_range(room.global_position.x + 40.0, room.global_position.x + room.room_width - 40.0)
			_move_x(local_patrol_x, patrol_speed, delta)
		return
	if room != target_room:
		var route := _route(room, target_room)
		if route.is_empty():
			if state == State.SEARCH:
				state = State.PATROL
			target_room = null
			return
		_follow_edge(route[0], delta)
	elif state == State.PURSUIT:
		_move_x(last_known_position.x, pursuit_speed, delta)
	elif state == State.SEARCH:
		if _move_x(last_known_position.x, patrol_speed, delta):
			search_left -= delta
			if search_left <= 0:
				state = State.PATROL
				target_room = null

func _choose_patrol_room(room: MansionRoom) -> void:
	var choices: Array[MansionRoom] = []
	for candidate in map.mansion_rooms:
		if candidate != room and not _route(room, candidate).is_empty():
			choices.append(candidate)
	if not choices.is_empty():
		target_room = choices[rng.randi_range(0, choices.size() - 1)]

func _follow_edge(edge: Dictionary, delta: float) -> void:
	var entry: Vector2 = edge.entry
	if not _move_x(entry.x, pursuit_speed if state == State.PURSUIT else patrol_speed, delta):
		return
	if edge.has("door"):
		var door: MansionDoor = edge.door
		if session.is_mansion_door_locked(door.door_id):
			return
		session.set_mansion_door_state(door.door_id, GameSession.MansionDoorState.OPEN, 0)
	global_position = edge.exit

func _move_x(target_x: float, speed: float, delta: float) -> bool:
	global_position.x = move_toward(global_position.x, target_x, speed * delta)
	return is_equal_approx(global_position.x, target_x)

func _draw() -> void:
	draw_rect(Rect2(-24, -95, 48, 95), Color("#321d2a"))
	draw_circle(Vector2(-10, -70), 4, Color("#e55858"))
	draw_circle(Vector2(10, -70), 4, Color("#e55858"))
