extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game: Node = load("res://Globals/game.tscn").instantiate()
	root.add_child(game)
	var split = game.get_node("SplitScreenManager2")
	var map := split.player_one_viewport.get_node("MapInstance1") as MapInstance
	var second_map := split.player_two_viewport.get_node("MapInstance2") as MapInstance
	var session := game.get_node("GameSession") as GameSession
	for frame in 45:
		await physics_frame
	assert(map.player.is_on_floor() and second_map.player.is_on_floor())
	var first_spawn := map.mansion.find_child("Player1Spawn", true, false) as Marker2D
	for world in [map, second_map]:
		for pair in ["Stairs_5_3", "Stairs_21_20", "Stairs_9_11", "Stairs_26_24"]:
			var stairs: Node2D = world.mansion.get_node("Stairs/" + pair)
			var up := stairs.get_node("UpEndpoint") as MansionStairs
			var down := stairs.get_node("DownEndpoint") as MansionStairs
			var lower_room: MansionRoom = world.mansion.get_node({"Stairs_5_3": "SmallRoom(5)", "Stairs_21_20": "MediumRoom(21)", "Stairs_9_11": "SmallRoom(9)", "Stairs_26_24": "MediumRoom(26)"}[pair])
			var upper_room: MansionRoom = world.mansion.get_node({"Stairs_5_3": "GrandRoom(3)", "Stairs_21_20": "MediumRoom(20)", "Stairs_9_11": "MediumRoom(11)", "Stairs_26_24": "MediumRoom(24)"}[pair])
			world.player.set_depth_plane(CoopPlayer.DepthPlane.FOREGROUND)
			var previous_position: Vector2 = world.player.global_position
			up._on_entering_area_body_entered(world.player)
			assert(world.player.global_position == previous_position)
			world.player.set_depth_plane(CoopPlayer.DepthPlane.BACKGROUND)
			up._on_entering_area_body_entered(world.player)
			assert(Rect2(upper_room.global_position, Vector2(upper_room.room_width, 540)).has_point(world.player.global_position))
			assert(world.player.global_position.distance_to(down.global_position) > 85.0)
			world.player.set_depth_plane(CoopPlayer.DepthPlane.FOREGROUND)
			previous_position = world.player.global_position
			down._on_entering_area_body_entered(world.player)
			assert(world.player.global_position == previous_position)
			world.player.set_depth_plane(CoopPlayer.DepthPlane.BACKGROUND)
			down._on_entering_area_body_entered(world.player)
			assert(Rect2(lower_room.global_position, Vector2(lower_room.room_width, 540)).has_point(world.player.global_position))
		world.player.set_depth_plane(CoopPlayer.DepthPlane.FOREGROUND)
	world.player.global_position = first_spawn.global_position
	second_map.player.global_position = second_map.mansion.find_child("Player2Spawn", true, false).global_position
	assert(not map.same_mansion_room(map.player.position, second_map.player.position))
	assert(map.ghost.visible and map.ghost.position.is_equal_approx(second_map.player.position))
	assert(second_map.ghost.visible and second_map.ghost.position.is_equal_approx(map.player.position))
	await press("p2_move_background")
	assert(map.ghost.z_index == second_map.player.z_index)
	assert(is_equal_approx(map.ghost.sprite_offset_y, second_map.player.sprite.position.y))
	assert(map.ghost.sprite.sprite_frames == second_map.player.sprite.sprite_frames)
	assert(is_equal_approx(map.ghost.sprite.modulate.a, 0.5))
	assert(map.ghost.sprite.material is ShaderMaterial)
	await press("p2_move_foreground")
	for ladder_name in ["Ladder(7-19)", "Ladder(14-15)", "Ladder(17-22)"]:
		var ladder := map.mansion.get_node(ladder_name)
		assert(ladder.get_node("LowerEndpoint") is MansionLadder)
		assert(ladder.get_node("UpperEndpoint") is MansionLadder)
		assert(ladder.get_node("LowerEndpoint").destination != NodePath())
		assert(ladder.get_node("UpperEndpoint").destination != NodePath())
		assert(ladder.get_node("LowerEndpoint/LadderBottomSprite") is Sprite2D)
		assert(ladder.get_node("UpperEndpoint/LadderTopSprite") is Sprite2D)
	assert(map.mansion.find_children("Ladder_Room*", "CollectibleItem", true, false).is_empty())
	assert(map.mansion.get_node("Ladder(7-19)/LowerEndpoint").global_position == Vector2(-680, 2010))
	assert(map.mansion.get_node("Ladder(7-19)/UpperEndpoint").global_position == Vector2(-680, 1470))
	assert(map.mansion.get_node("Ladder(14-15)/UpperEndpoint").global_position == Vector2(7000, 1470))
	assert(map.mansion.get_node("Ladder(17-22)/UpperEndpoint").global_position == Vector2(2500, 2010))
	var trapdoor := map.mansion.get_node("Trapdoor(10-17)") as MansionTrapdoor
	var second_trapdoor := second_map.mansion.get_node("Trapdoor(10-17)") as MansionTrapdoor
	var other_trapdoor := map.mansion.get_node("Trapdoor(16-25)") as MansionTrapdoor
	assert(trapdoor.trapdoor_id == "trapdoor_10_17")
	assert(other_trapdoor.trapdoor_id == "trapdoor_16_25")
	assert(trapdoor.get_node("FloorEndpoint").global_position == Vector2(4460, 1470))
	assert(other_trapdoor.get_node("FloorEndpoint").global_position == Vector2(5500, 2010))
	assert(session.get_mansion_trapdoor_state(trapdoor.trapdoor_id) == GameSession.DoorState.OPEN)
	assert(session.get_mansion_trapdoor_state(other_trapdoor.trapdoor_id) == GameSession.DoorState.OPEN)
	assert(map.same_mansion_room(map.player.position, map.to_local(first_spawn.global_position)))
	var door: MansionDoor = map.mansion.get_node("Doors/Door(3->4)")
	var second_door: MansionDoor = second_map.mansion.get_node("Doors/Door(3->4)")
	assert(door.door_id == "door_3_4")
	assert(door.connects_pair(map.mansion.get_node("GrandRoom(3)"), map.mansion.get_node("SmallRoom(4)")))
	door.interact(map.player)
	assert(session.get_mansion_door_state(door.door_id) == GameSession.DoorState.LOCKED)
	assert(map.constrain_mansion_movement(-1161, -1159, 486) == -1160.01)
	var key := map.mansion.get_node("MediumRoom(7)/Key_Room7_1") as CollectibleItem
	var second_key := second_map.mansion.get_node("MediumRoom(7)/Key_Room7_1") as CollectibleItem
	map.player.global_position = key.global_position
	await wait_for_overlap()
	await press("p1_interact")
	assert(session.has_inventory_item("key"))
	assert(key.collected and second_key.collected)
	assert(session.add_inventory_item({"kind": "key", "label": "Spare Key"}, GameSession.PLAYER_1) == 1)
	second_map.player.position = Vector2(-1161, 486)
	await wait_for_overlap()
	assert(not map.same_mansion_room(map.player.position, second_map.player.position))
	assert(map.ghost.visible and second_map.ghost.visible)
	assert(map.ghost.position.is_equal_approx(second_map.player.position))
	assert(second_map.ghost.position.is_equal_approx(map.player.position))
	await press("p2_interact")
	assert(door.is_open() and second_door.is_open())
	assert(session.inventory_slots[0].is_empty())
	assert(session.find_inventory_slot("key") == 1)
	assert(map._find_collectible("dropped_1") == null)
	assert(map.constrain_mansion_movement(-1161, -1159, 486) == -1159)
	Input.action_press("p2_move_right")
	await wait_for_overlap()
	Input.action_release("p2_move_right")
	assert(second_map.player.position.x > -1160.0)
	second_door.interact(second_map.player)
	assert(session.get_mansion_door_state(door.door_id) == GameSession.DoorState.CLOSED)
	assert(second_map.constrain_mansion_movement(-1161, -1159, 486) == -1160.01)
	await press("inventory_drop_slot_2")
	assert(not session.has_inventory_item("key"))
	assert(map._find_collectible("dropped_1").position == second_map._find_collectible("dropped_1").position)
	second_door.interact(second_map.player)
	assert(door.is_open())
	second_map.player.position = second_map._find_collectible("dropped_1").position
	await wait_for_overlap()
	await press("p2_interact")
	assert(session.has_inventory_item("key") and session.inventory_actor_id == GameSession.PLAYER_2)
	second_trapdoor.interact(second_map.player)
	assert(session.get_mansion_trapdoor_state(trapdoor.trapdoor_id) == GameSession.DoorState.CLOSED)
	assert(session.has_inventory_item("key"))
	trapdoor.interact(map.player)
	assert(trapdoor.is_open() and second_trapdoor.is_open())
	assert(session.has_inventory_item("key"))
	assert(trapdoor.get_node("FloorEndpoint/OpenSprite").visible)
	assert(second_trapdoor.get_node("FloorEndpoint/OpenSprite").visible)
	trapdoor.interact(map.player)
	assert(session.get_mansion_trapdoor_state(trapdoor.trapdoor_id) == GameSession.DoorState.CLOSED)
	trapdoor.interact(map.player)
	var ceiling_endpoint := trapdoor.get_node("CeilingEndpoint") as MansionTrapdoorEndpoint
	var floor_arrival := trapdoor.get_node("FloorEndpoint/ArrivalMarker") as Marker2D
	map.player.global_position = ceiling_endpoint.global_position
	ceiling_endpoint._on_entering_area_body_entered(map.player)
	assert(map.player.global_position == floor_arrival.global_position)
	session.reset()
	assert(not key.collected and not second_key.collected)
	assert(map._find_collectible("dropped_1") == null)
	assert(session.get_mansion_door_state(door.door_id) == GameSession.DoorState.LOCKED)
	assert(session.get_mansion_trapdoor_state(trapdoor.trapdoor_id) == GameSession.DoorState.OPEN)
	assert(trapdoor.get_node("FloorEndpoint/OpenSprite").visible)
	assert(map.player.global_position == first_spawn.global_position)
	var attic_ladder := second_map.mansion.get_node("Ladder/UpperEndpoint") as MansionLadder
	second_map.player.position.x = second_map.to_local(attic_ladder.global_position).x
	await wait_for_overlap()
	await press("p2_interact")
	assert(second_map.player.position.y > 0.0)
	print("PASS: split spawns, ghost tracking, shared inventory, and mansion connectors")
	quit()

func wait_for_overlap() -> void:
	await physics_frame
	await physics_frame
	await physics_frame

func press(action: String) -> void:
	Input.action_press(action)
	await process_frame
	await process_frame
	Input.action_release(action)
