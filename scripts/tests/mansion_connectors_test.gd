extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://Globals/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var split = game.get_node("SplitScreenManager2")
	var a = split.player_one_viewport.get_node("MapInstance1")
	var b = split.player_two_viewport.get_node("MapInstance2")
	assert(a.mansion_rooms.size() == 4 and b.mansion_doors.size() == 2)
	assert(a.mansion != b.mansion)
	assert(a.constrain_mansion_movement(539, 541, 390) < 540)
	assert(b.constrain_mansion_movement(539, 541, 390) < 540)
	assert(not a.mansion.get_node("BigRoom").room_visible)
	a.player.position = Vector2(510, 390)
	await physics_frame
	await physics_frame
	assert(a.player.interaction_sensor.get_closest_interactable() == a.mansion.get_node("LeftDoor"))
	a.player.interaction_sensor.get_closest_interactable().interact(a.player)
	assert(not game.session.is_mansion_door_locked("left"))
	assert(b.constrain_mansion_movement(539, 541, 390) == 541)
	await process_frame
	await process_frame
	assert(b.mansion.get_node("BigRoom").room_visible)
	var ladder = b.mansion.get_node("Ladder/LowerEndpoint")
	b.player.position = Vector2(1350, 390)
	assert(ladder.can_interact(b.player))
	ladder.interact(b.player)
	assert(b.player.position.is_equal_approx(Vector2(1350, -150)))
	await physics_frame
	await physics_frame
	assert(b.player.interaction_sensor.get_closest_interactable() == b.mansion.get_node("Ladder/UpperEndpoint"))
	b.player.interaction_sensor.get_closest_interactable().interact(b.player)
	assert(b.player.position.is_equal_approx(Vector2(1350, 390)))
	assert(a.player.position.y == 390)
	game.session.reset()
	assert(game.session.is_mansion_door_locked("left"))
	assert(a.ghost.get_child_count() == 0)
	print("PASS: shared door state, local visibility, both boundaries, ladder and reset")
	quit()
