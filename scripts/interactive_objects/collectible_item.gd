class_name CollectibleItem
extends Interactable

const ITEM_TEXTURES := {
	"key": preload("res://Assets/collectibles/klucz.png"),
	"music_box": preload("res://Assets/collectibles/pozytywka.png"),
	"candle": preload("res://Assets/collectibles/swieczka.png"),
}
const ITEM_REGIONS := {
	"key": Rect2(1105, 800, 35, 89),
	"music_box": Rect2(1556, 780, 143, 181),
	"candle": Rect2(1031, 786, 30, 102),
}
const ITEM_VISUAL_SCALE := Vector2(0.5, 0.5)

@export var item_kind := "collectible"
@export var item_label := "Collectible"
@export var shared_object_id := ""

var collected := false
var spawned_at_runtime := false

func interact(player: CoopPlayer) -> void:
	if collected or player.session == null:
		return
	var slot_index := player.session.collect_shared_collectible(shared_object_id, {
		"kind": item_kind,
		"label": item_label,
	}, player.player_id)
	if slot_index < 0:
		print("%s could not be collected: it is already gone or the inventory is full" % item_label)
		return
	print("P%d collected %s in slot %d" % [player.player_id, item_label, slot_index + 1])

func set_collected_from_session() -> void:
	collected = true
	visible = false
	var interaction_area := get_node_or_null("InteractionArea") as Area2D
	if interaction_area != null:
		interaction_area.set_deferred("monitorable", false)

func reset_from_session() -> void:
	collected = false
	visible = true
	var interaction_area := get_node_or_null("InteractionArea") as Area2D
	if interaction_area != null:
		interaction_area.set_deferred("monitorable", true)

func can_interact(_player: CoopPlayer) -> bool:
	return not collected

func build_runtime_nodes() -> void:
	if get_node_or_null("InteractionArea") == null:
		var interaction_area := Area2D.new()
		interaction_area.name = "InteractionArea"
		interaction_area.collision_layer = 1
		interaction_area.collision_mask = 0
		var collision_shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 38.0
		collision_shape.shape = circle
		interaction_area.add_child(collision_shape)
		add_child(interaction_area)
	_build_visual()

func _ready() -> void:
	build_runtime_nodes()

func _build_visual() -> void:
	if get_node_or_null("Visual") != null or not ITEM_TEXTURES.has(item_kind):
		queue_redraw()
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = ITEM_TEXTURES[item_kind]
	atlas.region = ITEM_REGIONS[item_kind]
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = atlas
	visual.scale = ITEM_VISUAL_SCALE
	visual.position.y = -atlas.get_height() * ITEM_VISUAL_SCALE.y * 0.5
	add_child(visual)

func _draw() -> void:
	if get_node_or_null("Visual") != null:
		return
	var color := Color("#f6ad55")
	var icon := "C"
	match item_kind:
		"music_box":
			color = Color("#4fd1c5")
			icon = "M"
		"key":
			color = Color("#f4d35e")
			icon = "K"
		"ladder":
			color = Color("#c09b6c")
			icon = "L"
	draw_rect(Rect2(-20.0, -40.0, 40.0, 40.0), color, true)
	draw_string(ThemeDB.fallback_font, Vector2(-6.0, -12.0), icon, HORIZONTAL_ALIGNMENT_CENTER, 12.0, 16, Color("#252233"))
	draw_string(ThemeDB.fallback_font, Vector2(-48.0, 20.0), item_label, HORIZONTAL_ALIGNMENT_CENTER, 96.0, 12, Color.WHITE)
