extends SceneTree

var captures := 0

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game: Node = load("res://Globals/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var split = game.get_node("SplitScreenManager2")
	var map: MapInstance = split.player_one_viewport.get_node("MapInstance1")
	var other: MapInstance = split.player_two_viewport.get_node("MapInstance2")
	var session: GameSession = game.get_node("GameSession")
	var monster: MansionMonster = map.mansion.get_node("Monster")
	var monster2: MansionMonster = other.mansion.get_node("Monster")
	monster.set_physics_process(false)
	monster2.set_physics_process(false)
	assert(monster != monster2 and monster.player == map.player and monster2.player == other.player)
	var room_a: MansionRoom = map.mansion.get_node("GrandRoom(3)")
	var room_b: MansionRoom = map.mansion.get_node("SmallRoom(4)")
	var door: MansionDoor = map.mansion.get_node("Door(3->4)")
	assert(monster._route(room_a, room_b).is_empty())
	door.interact(map.player)
	assert(session.is_mansion_door_locked(door.door_id))
	map.mansion.get_node("MansionKey").interact(map.player)
	assert(other.mansion.get_node("MansionKey").collected)
	door.interact(map.player)
	assert(session.get_mansion_door_state(door.door_id) == GameSession.MansionDoorState.OPEN)
	door.interact(map.player)
	assert(session.get_mansion_door_state(door.door_id) == GameSession.MansionDoorState.CLOSED)
	var route := monster._route(room_a, room_b)
	assert(not route.is_empty())
	monster.global_position = route[0].entry
	monster._follow_edge(route[0], 1.0)
	assert(session.get_mansion_door_state(door.door_id) == GameSession.MansionDoorState.OPEN)
	assert(other.mansion.get_node("Door(3->4)").session == session)
	assert(monster._room_at_global(monster.global_position) == room_b)
	session.set_mansion_door_state(door.door_id, GameSession.MansionDoorState.LOCKED, 1)
	assert(monster._route(room_a, room_b).is_empty())
	var lower: MansionLadder = map.mansion.get_node("Ladder/LowerEndpoint")
	var upper: MansionLadder = map.mansion.get_node("Ladder/UpperEndpoint")
	assert(not monster._route(monster._room_at_global(lower.global_position), monster._room_at_global(upper.global_position)).is_empty())
	var hole = load("res://scenes/connectors/hole_connector.tscn").instantiate()
	hole.position = lower.position + lower.get_parent().position + Vector2(100, 0)
	map.mansion.add_child(hole)
	monster._build_graph()
	var hole_lower: MansionHole = hole.get_node("LowerEndpoint")
	var hole_upper: MansionHole = hole.get_node("UpperEndpoint")
	var hole_edges := 0
	for edge in monster.edges:
		if edge.entry == hole_lower.global_position or edge.entry == hole_upper.global_position:
			hole_edges += 1
	assert(hole_edges == 2)
	monster.player_captured.connect(func(_id): captures += 1)
	monster.global_position = Vector2(0, 390)
	map.player.global_position = Vector2(10, 390)
	map.player.plane = CoopPlayer.DepthPlane.BACKGROUND
	monster._physics_process(0.1)
	monster._physics_process(0.1)
	assert(monster.state == MansionMonster.State.PURSUIT and captures == 1)
	map.player.global_position = Vector2(2000, 390)
	monster._physics_process(0.1)
	assert(monster.state == MansionMonster.State.SEARCH)
	print("PASS: monster navigation, shared doors, holes and capture")
	quit()


