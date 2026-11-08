extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game: Node = load("res://Globals/game.tscn").instantiate()
	root.add_child(game)
	var split := game.get_node("SplitScreenManager2") as SplitScreenManager
	var first := split.player_one_viewport.get_node("MapInstance1") as MapInstance
	var second := split.player_two_viewport.get_node("MapInstance2") as MapInstance
	var session := game.get_node("GameSession") as GameSession
	assert(first.monster != null and second.monster != null)
	assert(first.monster != second.monster)
	assert(first.monster.player == first.player and second.monster.player == second.player)
	assert(first.monster.get_viewport() != second.monster.get_viewport())
	second.monster.set_physics_process(false)
	var first_x := first.player.position.x
	var second_x := second.player.position.x
	Input.action_press("p1_move_right")
	await physics_frame
	await physics_frame
	Input.action_release("p1_move_right")
	assert(first.player.position.x > first_x)
	second_x = second.player.position.x
	Input.action_press("p2_move_right")
	await physics_frame
	await physics_frame
	Input.action_release("p2_move_right")
	assert(second.player.position.x > second_x)
	assert(is_equal_approx(first.ghost.sprite.modulate.a, 0.5))
	assert(is_equal_approx(second.ghost.sprite.modulate.a, 0.5))
	assert(first.ghost is Node2D and second.ghost is Node2D)
	var counts := {"door": 0, "ladder": 0, "trapdoor": 0, "hole": 0}
	for link in first.monster.links:
		if counts.has(link.kind):
			counts[link.kind] += 1
	print("Monster links: ", counts)
	for kind in counts:
		assert(counts[kind] > 0)
	var locked_door := first.mansion.get_node("Doors/Door(3->4)") as MansionDoor
	var locked_link: Dictionary = {}
	for link in first.monster.links:
		if link.connector == locked_door:
			locked_link = link
			break
	session.mansion_doors[locked_door.door_id] = GameSession.DoorState.LOCKED
	assert(not locked_link.is_empty() and not first.monster._link_available(locked_link))
	assert(not session.open_mansion_door_for_monster(locked_door.door_id, 1))
	assert(session.get_mansion_door_state(locked_door.door_id) == GameSession.DoorState.LOCKED)
	var passable_door := first.mansion.get_node("Doors/Door(1->3)") as MansionDoor
	var passable_link: Dictionary = {}
	for link in first.monster.links:
		if link.connector == passable_door:
			passable_link = link
			break
	assert(not passable_link.is_empty())
	var route: Dictionary = first.monster._first_link_toward(passable_link["from"], passable_link["to"])
	assert(not route.is_empty() and route["to"] == passable_link["to"])
	first.monster._traverse(passable_link)
	assert(session.get_mansion_door_state(passable_door.door_id) == GameSession.DoorState.OPEN)
	assert(first.monster.global_position == passable_link.exit)
	assert(second.mansion.get_node("Doors/Door(1->3)").is_open())
	var trapdoor := first.mansion.get_node("Trapdoor(10-17)") as MansionTrapdoor
	session.mansion_trapdoors[trapdoor.trapdoor_id] = GameSession.DoorState.LOCKED
	assert(not session.open_mansion_trapdoor_for_monster(trapdoor.trapdoor_id, 1))
	assert(session.get_mansion_trapdoor_state(trapdoor.trapdoor_id) == GameSession.DoorState.LOCKED)
	var other_health := second.player.health
	first.monster.alerted = true
	first.monster.global_position = first.player.global_position
	await physics_frame
	await physics_frame
	assert(first.player.health == CoopPlayer.MAX_HEALTH - 1)
	assert(second.player.health == other_health)
	assert(first.monster.recovery_left > 0.0)
	for frame in 30:
		first.monster.global_position = first.player.global_position
		await physics_frame
	assert(first.player.health == CoopPlayer.MAX_HEALTH - 1)
	first.monster.recovery_left = 0.0
	first.monster.global_position = first.player.global_position
	await physics_frame
	await physics_frame
	assert(first.player.health == CoopPlayer.MAX_HEALTH - 2)
	session.reset()
	assert(first.player.health == CoopPlayer.MAX_HEALTH)
	assert(first.monster.recovery_left == 0.0)
	print("PASS: separate monsters, connector routes, locked door, damage and recovery")
	quit()
