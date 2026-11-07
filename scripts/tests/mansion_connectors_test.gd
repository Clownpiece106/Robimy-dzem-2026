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
	assert(map.mansion_rooms.size() == 5 and map.mansion_doors.size() == 3)
	var door: MansionDoor = map.mansion.get_node("Door(3->4)")
	assert(door.door_id == "door_3_4")
	assert(door.connects_pair(map.mansion.get_node("GrandRoom(3)"), map.mansion.get_node("SmallRoom(4)")))
	assert(map.constrain_mansion_movement(-1161, -1159, 390) == -1160.01)
	map.player.position = Vector2(-1161, 390)
	await physics_frame
	await physics_frame
	assert(map.player.interaction_sensor.get_closest_interactable() == door)
	door.interact(map.player)
	assert(not game.get_node("GameSession").is_mansion_door_locked("door_3_4"))
	assert(map.constrain_mansion_movement(-1161, -1159, 390) == -1159)
	game.get_node("GameSession").reset()
	assert(game.get_node("GameSession").is_mansion_door_locked("door_3_4"))
	print("PASS: room 3 -> room 4 door")
	quit()
