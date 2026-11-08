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
	assert(map.player.position.y == second_map.player.position.y)
	for frame in 45:
		await physics_frame
	assert(map.player.is_on_floor() and second_map.player.is_on_floor())
	assert(absf(map.player.position.y - second_map.player.position.y) < 0.5,
		"Attic players settled at %s and %s" % [map.player.position, second_map.player.position])
	var first_spawn := map.mansion.get_node("Attic/Player1Spawn") as Marker2D
	assert(map.same_mansion_room(map.player.position, map.to_local(first_spawn.global_position)))
	assert(map.same_mansion_room(map.player.position, second_map.player.position))
	assert(map.ghost.visible and map.ghost.position.is_equal_approx(second_map.player.position))
	assert(second_map.ghost.visible and second_map.ghost.position.is_equal_approx(map.player.position))
	await press("p2_move_background")
	assert(map.ghost.z_index == second_map.player.z_index)
	assert(is_equal_approx(map.ghost.sprite_offset_y, second_map.player.sprite.position.y))
	await press("p2_move_foreground")
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
	var second_door: MansionDoor = second_map.mansion.get_node("Door(3->4)")
	assert(door.door_id == "door_3_4")
	assert(door.connects_pair(map.mansion.get_node("GrandRoom(3)"), map.mansion.get_node("SmallRoom(4)")))
	door.interact(map.player)
	assert(session.get_mansion_door_state(door.door_id) == GameSession.DoorState.LOCKED)
	assert(map.constrain_mansion_movement(-1161, -1159, 486) == -1160.01)
	var key := map.mansion.get_node("Attic/Key") as CollectibleItem
	var second_key := second_map.mansion.get_node("Attic/Key") as CollectibleItem
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
	session.reset()
	assert(not key.collected and not second_key.collected)
	assert(map._find_collectible("dropped_1") == null)
	assert(session.get_mansion_door_state(door.door_id) == GameSession.DoorState.LOCKED)
	assert(map.player.global_position == first_spawn.global_position)
	var attic_ladder := map.mansion.get_node("Ladder/UpperEndpoint") as MansionLadder
	map.player.position.x = map.to_local(attic_ladder.global_position).x
	await wait_for_overlap()
	await press("p1_interact")
	assert(map.player.position.y > 0.0)
	assert(second_map.ghost.visible and second_map.ghost.position.is_equal_approx(map.player.position))
	print("PASS: attic spawns, ghost tracking, shared inventory, and mansion connectors")
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
