extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game: Node = load("res://scenes/interaction_test.tscn").instantiate()
	root.add_child(game)
	var split := game.get_node("SplitScreenManager")
	var first_map := split.get_node("Player1ViewportContainer/Player1Viewport/MapInstance1") as MapInstance
	var second_map := split.get_node("Player2ViewportContainer/Player2Viewport/MapInstance2") as MapInstance
	var first_door := first_map.door
	var second_door := second_map.door
	var session := game.get_node("GameSession") as GameSession
	await physics_frame
	await physics_frame
	first_map.player.set_depth_plane(CoopPlayer.DepthPlane.FOREGROUND)
	second_map.player.set_depth_plane(CoopPlayer.DepthPlane.BACKGROUND)
	await assert_blocked(first_map, "p1_move_right")
	await assert_blocked(second_map, "p2_move_right")
	assert(session.add_inventory_item({"kind": "key", "label": "Key"}, GameSession.PLAYER_1) >= 0)
	first_door.interact(first_map.player)
	await physics_frame
	assert(first_door.open and second_door.open)
	assert(first_door.get_node("DoorBlocker/CollisionShape2D").disabled)
	assert(second_door.get_node("DoorBlocker/CollisionShape2D").disabled)
	await assert_passable(first_map, "p1_move_right")
	await assert_passable(second_map, "p2_move_right")
	session.reset()
	await physics_frame
	assert(not first_door.open and not second_door.open)
	await assert_blocked(first_map, "p1_move_right")
	await assert_blocked(second_map, "p2_move_right")
	print("PASS: closed doors block both players and opened doors allow passage in both worlds")
	quit()

func assert_blocked(world: MapInstance, action: String) -> void:
	var door_x := world.door.position.x
	assert(not world.door.get_node("DoorBlocker/CollisionShape2D").disabled)
	world.player.position = Vector2(door_x - 80.0, 390.0)
	world.player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press(action)
	for frame in 20:
		await physics_frame
	Input.action_release(action)
	assert(world.player.position.x < door_x - 30.0)

func assert_passable(world: MapInstance, action: String) -> void:
	var door_x := world.door.position.x
	world.player.position = Vector2(door_x - 80.0, 390.0)
	world.player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press(action)
	for frame in 20:
		await physics_frame
	Input.action_release(action)
	assert(world.player.position.x > door_x + 30.0)
