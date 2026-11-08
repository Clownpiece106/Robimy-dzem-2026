class_name PlacementSurface
extends Interactable

const ITEM_TEXTURES := CollectibleItem.ITEM_TEXTURES
const ITEM_REGIONS := CollectibleItem.ITEM_REGIONS

@export var placement_id := ""
@export_enum("candle", "music_box") var accepted_item_kind := "candle"
@export var visual_offset := Vector2(0.0, -70.0)
@export var visual_scale := CollectibleItem.ITEM_VISUAL_SCALE

var session: GameSession

func configure(game_session: GameSession) -> void:
	if session == game_session:
		return
	if session != null and session.placement_changed.is_connected(_on_placement_changed):
		session.placement_changed.disconnect(_on_placement_changed)
	session = game_session
	session.register_placement(placement_id, accepted_item_kind)
	if not session.placement_changed.is_connected(_on_placement_changed):
		session.placement_changed.connect(_on_placement_changed)
	if not session.session_reset.is_connected(_on_session_reset):
		session.session_reset.connect(_on_session_reset)
	_refresh_visual()

func can_interact(player: CoopPlayer) -> bool:
	return (
		player.session != null
		and _can_player_place(player.player_id)
		and player.session.get_placed_item(placement_id).is_empty()
		and player.session.has_inventory_item(accepted_item_kind)
	)

func _can_player_place(player_id: int) -> bool:
	match accepted_item_kind:
		"candle":
			return player_id == GameSession.PLAYER_2
		"music_box":
			return player_id == GameSession.PLAYER_1
		_:
			return false

func interact(player: CoopPlayer) -> void:
	if not can_interact(player):
		return
	if player.session.place_inventory_item(placement_id, accepted_item_kind, player.player_id):
		_refresh_visual()

func _on_placement_changed(changed_id: String, _item_kind: String) -> void:
	if changed_id == placement_id:
		_refresh_visual()

func _on_session_reset() -> void:
	_refresh_visual()

func _refresh_visual() -> void:
	var visual := get_node_or_null("PlacedItem") as Sprite2D
	var item_kind := "" if session == null else session.get_placed_item(placement_id)
	if item_kind.is_empty():
		if visual != null:
			visual.queue_free()
		return
	if visual == null:
		visual = Sprite2D.new()
		visual.name = "PlacedItem"
		add_child(visual)
	var atlas := AtlasTexture.new()
	atlas.atlas = ITEM_TEXTURES[item_kind]
	atlas.region = ITEM_REGIONS[item_kind]
	visual.texture = atlas
	visual.position = visual_offset
	visual.scale = visual_scale
