class_name MansionMonster
extends Node2D

const PATROL_SPEED := 290.0
const CHASE_SPEED := 340.0
const RECOVERY_SPEED := 95.0
const NOTICE_DISTANCE := 620.0
const HIT_DISTANCE := 52.0
const RECOVERY_SECONDS := 7.0
const ARRIVAL_DISTANCE := 18.0

var plane_swap_timer := 0
var plane_swap_max_delay := 300
var plane_swap_min_delay := 120
var rng

@export var player_id := 1

@export var anim_eye : SpriteFrames
@export var anim_ear : SpriteFrames
@onready var animated_sprite_2d = $AnimatedSprite2D

var map: MapInstance
var player: CoopPlayer
var session: GameSession
var alerted := false
var recovery_left := 0.0
var patrol_target := Vector2.INF
var patrol_link: Dictionary = {}
var links: Array[Dictionary] = []

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	rng = RandomNumberGenerator.new()

func configure(owning_map: MapInstance, target: CoopPlayer, game_session: GameSession) -> void:
	map = owning_map
	player = target
	session = game_session
	player_id = target.player_id
	if(player_id==1):
		animated_sprite_2d.sprite_frames = anim_ear
		animated_sprite_2d.play("default")
		print("set to ear")
	if(player_id==2):
		animated_sprite_2d.sprite_frames = anim_eye
		animated_sprite_2d.play("default")
		print("set to eye")
	_rebuild_links()
	if not session.session_reset.is_connected(_on_session_reset):
		session.session_reset.connect(_on_session_reset)
	_on_session_reset()

func _on_session_reset() -> void:
	alerted = false
	recovery_left = 0.0
	patrol_link = {}
	patrol_target = Vector2.INF
	var spawn := map.mansion.find_child("Player%dSpawn" % player_id, true, false) as Marker2D
	if spawn != null:
		var room := map._room_at(map.to_local(spawn.global_position))
		if room != null:
			var bounds := Rect2(room.global_position, Vector2(room.room_width, 540.0))
			global_position = Vector2(clampf(spawn.global_position.x + 760.0, bounds.position.x + 100.0, bounds.end.x - 100.0), bounds.position.y + 480.0)
			return
	global_position = player.global_position + Vector2(760.0, 0.0)

func _physics_process(delta: float) -> void:
	if map == null or player == null:
		return
	recovery_left = maxf(0.0, recovery_left - delta)
	var own_room := map._room_at(map.to_local(global_position))
	var player_room := map._room_at(map.to_local(player.global_position))
	if own_room == null or player_room == null:
		return
	if not alerted and own_room == player_room and player.health > 0 and global_position.distance_to(player.global_position) <= NOTICE_DISTANCE:
		alerted = true
		print("Monster P%d noticed player" % player_id)
	var speed := RECOVERY_SPEED if recovery_left > 0.0 else (CHASE_SPEED if alerted else PATROL_SPEED)
	var target := Vector2.INF
	var link: Dictionary = {}
	if alerted and player.health > 0:
		patrol_link = {}
		if own_room == player_room:
			target = Vector2(player.global_position.x, own_room.global_position.y + 480.0)
		else:
			link = _first_link_toward(own_room, player_room)
			if not link.is_empty():
				target = link.entry
	if target == Vector2.INF:
		if patrol_target == Vector2.INF or global_position.distance_to(patrol_target) < ARRIVAL_DISTANCE:
			_choose_patrol_target(own_room)
		target = patrol_target
		link = patrol_link
	_move_toward(target, speed * delta)
	#print(target.x)
	if(target.x>position.x):
		animated_sprite_2d.scale.x = 0.4
	else:
		animated_sprite_2d.scale.x = -0.4
	if not link.is_empty() and global_position.distance_to(link.entry) <= ARRIVAL_DISTANCE:
		_traverse(link)
		patrol_target = Vector2.INF
		patrol_link = {}
	if (z_index == player.z_index)&& alerted and recovery_left <= 0.0 and own_room == player_room and player.health > 0 and global_position.distance_to(player.global_position) <= HIT_DISTANCE:
		player.take_damage(1)
		recovery_left = RECOVERY_SECONDS
		print("Monster P%d hit player: %d hearts left" % [player_id, player.health])
	_sprite_plane()
	
	if(plane_swap_timer>0):
		plane_swap_timer -=1
		print(plane_swap_timer)
		if(plane_swap_timer==0):
			z_index = player.z_index
			animated_sprite_2d.offset.y = player.sprite.position.y

func _move_toward(target: Vector2, distance: float) -> void:
	if(!MainMenu.visible):
		if target == Vector2.INF:
			return
		var before := global_position.x
		global_position = global_position.move_toward(target, distance)
		if not is_equal_approx(before, global_position.x):
			sprite.flip_h = global_position.x < before

func _sprite_plane() -> void:
	var own_room := map._room_at(map.to_local(global_position))
	var player_room := map._room_at(map.to_local(player.global_position))
	visible = own_room != null and own_room.room_visible
	if own_room == player_room:
		if(z_index!=player.z_index)&&(plane_swap_timer==0):
			plane_swap_timer = randi_range(plane_swap_min_delay, plane_swap_max_delay)
	else:
		z_index = 3
		animated_sprite_2d.offset.y = -32.0
	sprite.modulate = Color(0.65, 0.7, 1.0, 0.7) if recovery_left > 0.0 else Color.WHITE

func _choose_patrol_target(room: MansionRoom) -> void:
	var candidates: Array[Dictionary] = []
	for link in links:
		if link["from"] == room and _link_available(link):
			candidates.append(link)
	if not candidates.is_empty():
		patrol_link = candidates.pick_random()
		patrol_target = patrol_link.entry
	else:
		patrol_link = {}
		patrol_target = Vector2(randf_range(room.global_position.x + 90.0, room.global_position.x + room.room_width - 90.0), room.global_position.y + 480.0)

func _first_link_toward(start: MansionRoom, goal: MansionRoom) -> Dictionary:
	var queue: Array[MansionRoom] = [start]
	var visited := {start: true}
	var first: Dictionary = {}
	while not queue.is_empty():
		var room: MansionRoom = queue.pop_front()
		for link in links:
			if link["from"] != room or not _link_available(link) or visited.has(link["to"]):
				continue
			visited[link["to"]] = true
			first[link["to"]] = link if room == start else first[room]
			if link["to"] == goal:
				return first[goal]
			queue.append(link["to"])
	return {}

func _link_available(link: Dictionary) -> bool:
	match link.kind:
		"door":
			return session.get_mansion_door_state(link.connector.door_id) != GameSession.DoorState.LOCKED
		"trapdoor":
			return session.get_mansion_trapdoor_state(link.connector.trapdoor_id) != GameSession.DoorState.LOCKED
	return true

func _traverse(link: Dictionary) -> void:
	if not _link_available(link):
		return
	match link.kind:
		"door":
			if not session.open_mansion_door_for_monster(link.connector.door_id, player_id):
				return
		"trapdoor":
			if not session.open_mansion_trapdoor_for_monster(link.connector.trapdoor_id, player_id):
				return
	global_position = link.exit
	print("Monster P%d used %s %s" % [player_id, link.kind, link.connector.name])

func _rebuild_links() -> void:
	links.clear()
	for door in map.mansion_doors:
		var a := door.get_node_or_null(door.room_a) as MansionRoom
		var b := door.get_node_or_null(door.room_b) as MansionRoom
		if a == null or b == null:
			continue
		var a_on_left := a.global_position.x < b.global_position.x
		_add_pair(a, b, Vector2(door.global_position.x + (-36.0 if a_on_left else 36.0), a.global_position.y + 480.0), Vector2(door.global_position.x + (36.0 if a_on_left else -36.0), b.global_position.y + 480.0), "door", door)
	for trapdoor in map.mansion_trapdoors:
		_add_endpoint_pair(trapdoor.get_node("FloorEndpoint"), trapdoor.get_node("CeilingEndpoint"), "trapdoor", trapdoor)
	for ladder in map.mansion.find_children("*", "Node2D", true, false):
		if ladder is MansionLadder and ladder.name == "LowerEndpoint":
			_add_endpoint_pair(ladder, ladder.get_parent().get_node("UpperEndpoint"), "ladder", ladder.get_parent())
	for stairs in map.mansion.find_children("Stairs_*", "Node2D", true, false):
		_add_endpoint_pair(stairs.get_node("UpEndpoint"), stairs.get_node("DownEndpoint"), "stairs", stairs)
	var holes: Array[Node2D] = []
	for hole in map.mansion.find_children("hole*", "Sprite2D", true, false):
		holes.append(hole)
	for i in holes.size():
		for j in range(i + 1, holes.size()):
			var a := holes[i]
			var b := holes[j]
			var vertical := absf(a.global_position.y - b.global_position.y)
			if absf(a.global_position.x - b.global_position.x) <= 220.0 and vertical >= 400.0 and vertical <= 1200.0:
				_add_endpoint_pair(a, b, "hole", a)

func _add_endpoint_pair(a: Node2D, b: Node2D, kind: String, connector: Node2D) -> void:
	var room_a := map._room_at(map.to_local(a.global_position))
	var room_b := map._room_at(map.to_local(b.global_position))
	if room_a == null or room_b == null or room_a == room_b:
		return
	_add_pair(room_a, room_b, Vector2(a.global_position.x, room_a.global_position.y + 480.0), Vector2(b.global_position.x, room_b.global_position.y + 480.0), kind, connector)

func _add_pair(a: MansionRoom, b: MansionRoom, entry: Vector2, exit: Vector2, kind: String, connector: Node2D) -> void:
	links.append({"from": a, "to": b, "entry": entry, "exit": exit, "kind": kind, "connector": connector})
	links.append({"from": b, "to": a, "entry": exit, "exit": entry, "kind": kind, "connector": connector})
