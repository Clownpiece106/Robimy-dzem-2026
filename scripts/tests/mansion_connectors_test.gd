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
	door.interact(map.player)
	assert(not game.get_node("GameSession").is_mansion_door_locked("door_3_4"))
	assert(map.constrain_mansion_movement(-1161, -1159, 390) == -1159)
	print("PASS: five requested ladders and room 3 -> room 4 door")
	quit()
