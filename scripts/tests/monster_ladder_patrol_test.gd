extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game: Node = load("res://Globals/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var split: SplitScreenManager = game.get_node("SplitScreenManager2")
	var session: GameSession = game.get_node("GameSession")
	for map in [split.player_one_viewport.get_node("MapInstance1"), split.player_two_viewport.get_node("MapInstance2")]:
		var monster: MansionMonster = map.mansion.get_node("Monster")
		monster.set_physics_process(false)
		monster.rng.seed = 42
		monster.global_position = Vector2(1166, 2411)
		var room: MansionRoom = map.mansion.get_node("MediumRoom(23)")
		var ladder_room: MansionRoom = map.mansion.get_node("SmallRoom(22)")
		session.set_mansion_door_state("door_22_23", GameSession.MansionDoorState.LOCKED, 0)
		assert(monster._route(room, ladder_room).is_empty())
		session.set_mansion_door_state("door_22_23", GameSession.MansionDoorState.CLOSED, 0)
		assert(not monster._route(room, ladder_room).is_empty())
		var start_y := monster.global_position.y
		var climbed := false
		for i in 4000:
			monster._physics_process(0.1)
			if monster.global_position.y < start_y - 400.0:
				climbed = true
				break
		if not climbed:
			printerr("FAIL: lower-floor monster never climbed; position=", monster.global_position)
			quit(1)
			return
		assert(session.get_mansion_door_state("door_22_23") == GameSession.MansionDoorState.OPEN)
	print("PASS: both monsters open the closed door and climb; locked doors block routes")
	quit(0)
