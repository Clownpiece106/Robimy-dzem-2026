extends Node2D

const INVENTORY_LABEL := preload("res://scripts/shared_inventory_label.gd")
const INVENTORY_TEXT_SHADER := preload("res://shaders/shared_inventory_text.gdshader")
const HEART_ICON := preload("res://Assets/health_heart.svg")
const FULL_HEART_COLOR := Color("#ff5a70")
const EMPTY_HEART_COLOR := Color("#79717e")

@onready var session: GameSession = $GameSession

func _ready() -> void:
	var split_screen := get_node_or_null("SplitScreenManager") as SplitScreenManager
	if split_screen == null:
		split_screen = get_node("SplitScreenManager2") as SplitScreenManager
	var template := get_node_or_null("MansionLayout") as Node2D
	if template != null:
		for id in [1, 2]:
			var map := split_screen.get_node("Player%dViewportContainer/Player%dViewport/MapInstance%d" % [id, id, id])
			var old_layout := map.get_node_or_null("Mansion")
			if old_layout != null:
				map.remove_child(old_layout)
				old_layout.queue_free()
			var layout := template.duplicate() as Node2D
			layout.name = "Mansion"
			layout.visible = true
			layout.z_index = -1
			map.add_child(layout)
		template.visible = false
	split_screen.configure(session)
	($GameOverOverlay as GameOverOverlay).configure(session)
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var inventory := INVENTORY_LABEL.new()
	hud.add_child(inventory)
	inventory.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	inventory.position.y = 20.0
	inventory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory.add_theme_font_size_override("font_size", 32)
	inventory.add_theme_color_override("font_color", Color.WHITE)
	inventory.add_theme_color_override("font_outline_color", Color.BLACK)
	inventory.add_theme_constant_override("outline_size", 6)
	var text_material := ShaderMaterial.new()
	text_material.shader = INVENTORY_TEXT_SHADER
	inventory.material = text_material
	inventory.configure(session)
	var first_map := split_screen.player_one_viewport.get_node("MapInstance1") as MapInstance
	var second_map := split_screen.player_two_viewport.get_node("MapInstance2") as MapInstance
	_add_health_display(hud, first_map.player, BoxContainer.ALIGNMENT_BEGIN)
	_add_health_display(hud, second_map.player, BoxContainer.ALIGNMENT_END)

func _add_health_display(hud: CanvasLayer, player: CoopPlayer, alignment: BoxContainer.AlignmentMode) -> void:
	var hearts := HBoxContainer.new()
	hearts.name = "Player%dHearts" % player.player_id
	hud.add_child(hearts)
	hearts.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hearts.offset_left = 20.0
	hearts.offset_right = -20.0
	hearts.position.y = 20.0
	hearts.alignment = alignment
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in CoopPlayer.MAX_HEALTH:
		var icon := TextureRect.new()
		icon.texture = HEART_ICON
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts.add_child(icon)
	var update_hearts := func(health: int) -> void:
		for index in CoopPlayer.MAX_HEALTH:
			var icon := hearts.get_child(index) as TextureRect
			icon.self_modulate = FULL_HEART_COLOR if index < health else EMPTY_HEART_COLOR
	player.health_changed.connect(update_hearts)
	update_hearts.call(player.health)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		session.reset()
