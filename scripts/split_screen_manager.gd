class_name SplitScreenManager
extends Control

enum Layout { VERTICAL, HORIZONTAL }

var layout := Layout.VERTICAL
var session: GameSession
var player_one_container: SubViewportContainer
var player_two_container: SubViewportContainer
var player_one_viewport: SubViewport
var player_two_viewport: SubViewport

func configure(game_session: GameSession) -> void:
	session = game_session
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	if has_node("Player1ViewportContainer"):
		player_one_container = get_node("Player1ViewportContainer")
		player_two_container = get_node("Player2ViewportContainer")
		player_one_viewport = player_one_container.get_node("Player1Viewport")
		player_two_viewport = player_two_container.get_node("Player2Viewport")
		player_one_viewport.world_2d = World2D.new()
		player_two_viewport.world_2d = World2D.new()
		(player_one_viewport.get_node("MapInstance1") as MapInstance).configure_mansion(session, GameSession.PLAYER_1)
		(player_two_viewport.get_node("MapInstance2") as MapInstance).configure_mansion(session, GameSession.PLAYER_2)
	else:
		_create_viewports()
	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_apply_layout")

func set_layout(next_layout: Layout) -> void:
	layout = next_layout
	_apply_layout()

func _create_viewports() -> void:
	player_one_container = _create_container("Player1ViewportContainer")
	player_two_container = _create_container("Player2ViewportContainer")
	add_child(player_one_container)
	add_child(player_two_container)

	player_one_viewport = _create_viewport(player_one_container, "Player1Viewport", GameSession.PLAYER_1)
	player_two_viewport = _create_viewport(player_two_container, "Player2Viewport", GameSession.PLAYER_2)

func _create_container(container_name: String) -> SubViewportContainer:
	var container := SubViewportContainer.new()
	container.name = container_name
	container.stretch = false
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return container

func _create_viewport(container: SubViewportContainer, viewport_name: String, player_id: int) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = viewport_name
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport.world_2d = World2D.new()
	container.add_child(viewport)
	var map := MapInstance.new()
	map.name = "MapInstance%d" % player_id
	viewport.add_child(map)
	map.configure(session, player_id)
	var camera := Camera2D.new()
	camera.name = "Player%dCamera" % player_id
	map.add_child(camera)
	map.set_camera(camera)
	return viewport

func _apply_layout() -> void:
	if player_one_container == null:
		return
	size = get_viewport().get_visible_rect().size
	if layout == Layout.VERTICAL:
		_set_rect(player_one_container, 0.0, 0.0, 0.5, 1.0)
		_set_rect(player_two_container, 0.5, 0.0, 1.0, 1.0)
	else:
		_set_rect(player_one_container, 0.0, 0.0, 1.0, 0.5)
		_set_rect(player_two_container, 0.0, 0.5, 1.0, 1.0)
	var viewport_size := get_viewport().get_visible_rect().size
	player_one_viewport.size = Vector2i(maxi(1, int(viewport_size.x * (0.5 if layout == Layout.VERTICAL else 1.0))), max(1, int(viewport_size.y * (1.0 if layout == Layout.VERTICAL else 0.5))))
	player_two_viewport.size = player_one_viewport.size

func _set_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
