extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game := load("res://Globals/game.tscn").instantiate()
	root.add_child(game)
	var session := game.get_node("GameSession") as GameSession
	var split := game.get_node("SplitScreenManager2") as SplitScreenManager
	var first_map := split.player_one_viewport.get_node("MapInstance1") as MapInstance
	var second_map := split.player_two_viewport.get_node("MapInstance2") as MapInstance
	var overlay := game.get_node("GameOverOverlay") as GameOverOverlay
	assert(first_map.player.health == 5 and second_map.player.health == 5)
	assert(first_map.ghost.sprite.modulate.a == 0.5 and second_map.ghost.sprite.modulate.a == 0.5)
	assert(first_map.ghost.get_child_count() == 1 and second_map.ghost.get_child_count() == 1)
	var collectible_counts := {"candle": 0, "music_box": 0}
	for collectible in first_map._get_collectibles():
		if collectible_counts.has(collectible.item_kind):
			collectible_counts[collectible.item_kind] += 1
	assert(collectible_counts["candle"] == 6 and collectible_counts["music_box"] == 6)

	for player in [first_map.player, second_map.player]:
		player.take_damage(4)
		assert(not session.is_game_over)
		player.take_damage()
		assert(session.is_game_over and session.ending == "bad")
		assert(overlay.screen.visible and overlay.detail_label.text.contains("Player %d" % player.player_id))
		overlay._on_retry_button_pressed()
		assert(not session.is_game_over and not overlay.screen.visible)
		assert(first_map.player.health == 5 and second_map.player.health == 5)

	assert(session.placement_kinds.size() == 12)
	var candle_count := 0
	var music_box_count := 0
	for placement_id in session.placement_kinds:
		var item_kind: String = session.placement_kinds[placement_id]
		var local_map: MapInstance = second_map if item_kind == "candle" else first_map
		var remote_map: MapInstance = first_map if item_kind == "candle" else second_map
		candle_count += int(item_kind == "candle")
		music_box_count += int(item_kind == "music_box")
		var local_surface := _find_surface(local_map, placement_id)
		var remote_surface := _find_surface(remote_map, placement_id)
		assert(local_surface != null and remote_surface != null)
		assert(session.add_inventory_item({"kind": item_kind, "label": item_kind}, local_map.local_player_id) >= 0)
		local_surface.interact(local_map.player)
		assert(session.get_placed_item(placement_id) == item_kind)
		assert(remote_surface.get_node_or_null("PlacedItem") != null)
	assert(candle_count == 6 and music_box_count == 6)
	assert(session.is_game_over and session.ending == "good")
	assert(overlay.screen.visible and overlay.title_label.text == "GOOD ENDING")
	assert(not session.place_inventory_item("candle_holder_0", "candle", GameSession.PLAYER_2))
	print("Game ending checks passed")
	quit()

func _find_surface(map: MapInstance, placement_id: String) -> PlacementSurface:
	for surface in map.placement_surfaces:
		if surface.placement_id == placement_id:
			return surface
	return null
