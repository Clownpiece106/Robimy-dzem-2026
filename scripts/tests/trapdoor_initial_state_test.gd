extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game: Node = load("res://Globals/game.tscn").instantiate()
	root.add_child(game)
	var split := game.get_node("SplitScreenManager2") as SplitScreenManager
	var map := split.player_one_viewport.get_node("MapInstance1") as MapInstance
	var second_map := split.player_two_viewport.get_node("MapInstance2") as MapInstance
	var session := game.get_node("GameSession") as GameSession
	var trapdoor := map.mansion.get_node("Trapdoor(10-17)") as MansionTrapdoor
	var second_trapdoor := second_map.mansion.get_node("Trapdoor(10-17)") as MansionTrapdoor
	assert(trapdoor.initial_state == GameSession.DoorState.OPEN)
	assert(session.get_mansion_trapdoor_state(trapdoor.trapdoor_id) == GameSession.DoorState.OPEN)
	assert(trapdoor.get_node("FloorEndpoint/OpenSprite").visible)
	assert(not trapdoor.get_node("FloorEndpoint/ClosedSprite").visible)
	assert(second_trapdoor.get_node("FloorEndpoint/OpenSprite").visible)
	for frame in 3:
		await physics_frame
	var player_spawn := map.mansion.find_child("Player1Spawn", true, false) as Marker2D
	assert(map.same_mansion_room(map.player.position, map.to_local(player_spawn.global_position)))
	var ceiling_endpoint := trapdoor.get_node("CeilingEndpoint") as MansionTrapdoorEndpoint
	var floor_arrival := trapdoor.get_node("FloorEndpoint/ArrivalMarker") as Marker2D
	map.player.global_position = ceiling_endpoint.global_position
	ceiling_endpoint._on_entering_area_body_entered(map.player)
	assert(map.player.global_position == floor_arrival.global_position)
	print("PASS: open trapdoor default updates sprites and permits traversal")
	quit()
