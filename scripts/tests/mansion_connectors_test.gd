extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game: Node = load("res://Globals/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var split = game.get_node("SplitScreenManager2")
	var map := split.player_one_viewport.get_node("MapInstance1") as MapInstance
	var second_map := split.player_two_viewport.get_node("MapInstance2") as MapInstance
	for ladder_name in ["Ladder(7-19)", "Ladder(14-15)", "Ladder(17-22)", "Ladder(9-17)", "Ladder(16-25)"]:
		var ladder := map.mansion.get_node(ladder_name)
		assert(ladder.get_node("LowerEndpoint") is MansionLadder)
		assert(ladder.get_node("UpperEndpoint") is MansionLadder)
		assert(ladder.get_node("LowerEndpoint").destination != NodePath())
		assert(ladder.get_node("UpperEndpoint").destination != NodePath())
	assert(map.mansion.get_node("Ladder(7-19)/LowerEndpoint").global_position == Vector2(-680, 2010))
	assert(map.mansion.get_node("Ladder(7-19)/UpperEndpoint").global_position == Vector2(-680, 1470))
	assert(map.mansion.get_node("Ladder(14-15)/UpperEndpoint").global_position == Vector2(7000, 1470))
	assert(map.mansion.get_node("Ladder(17-22)/UpperEndpoint").global_position == Vector2(2500, 2010))
	assert(map.mansion.get_node("Ladder(9-17)/UpperEndpoint").global_position == Vector2(3500, 1470))
	assert(map.mansion.get_node("Ladder(16-25)/UpperEndpoint").global_position == Vector2(5500, 2010))
	var door: MansionDoor = map.mansion.get_node("Door(3->4)")
	assert(door.door_id == "door_3_4")
	assert(door.connects_pair(map.mansion.get_node("GrandRoom(3)"), map.mansion.get_node("SmallRoom(4)")))
	assert(map.constrain_mansion_movement(-1161, -1159, 390) == -1160.01)
	map.player.position = Vector2(-1161, 390)
	Input.action_press("p1_move_right")
	await physics_frame
	Input.action_release("p1_move_right")
	assert(map.player.position.x <= -1160.0)
	door.interact(map.player)
	assert(not game.get_node("GameSession").is_mansion_door_locked("door_3_4"))
	assert(map.constrain_mansion_movement(-1161, -1159, 390) == -1159)
	map.player.position = Vector2(-1161, 390)
	Input.action_press("p1_move_right")
	await physics_frame
	Input.action_release("p1_move_right")
	assert(map.player.position.x > -1160.0)
	game.get_node("GameSession").reset()
	var second_door: MansionDoor = second_map.mansion.get_node("Door(3->4)")
	second_map.player.position = Vector2(-1161, 390)
	Input.action_press("p2_move_right")
	await physics_frame
	Input.action_release("p2_move_right")
	assert(second_map.player.position.x <= -1160.0)
	second_door.interact(second_map.player)
	second_map.player.position = Vector2(-1161, 390)
	Input.action_press("p2_move_right")
	await physics_frame
	Input.action_release("p2_move_right")
	assert(second_map.player.position.x > -1160.0)
	print("PASS: five requested ladders and room 3 -> room 4 door")
	quit()
