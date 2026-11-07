class_name CoopPlayer
extends CharacterBody2D

enum DepthPlane { BACKGROUND, FOREGROUND }
@onready var test_sprite = $TestSprite

const SPEED := 220.0
const GRV := 0.0
const MAX_VSP := 300.0
const INTERACT_ACTION := "p%d_interact"
const DROP_SLOT_ACTION := "inventory_drop_slot_%d"
@onready var sprite = $Sprite
var sprite_depth_offset := 0.0
var sprite_depth_offset_target := 0.0
var sprite_depth_offset_bg := -8.0
var sprite_depth_offset_fg := 0.0
var current_tilemap_ref : TileMapLayer
var is_on_stairs := false

@export var player_id: int
var map_instance: Node
var left_action: String
var right_action: String
var background_action: String
var foreground_action: String
var interact_action: String
var interaction_sensor: InteractionSensor
var session: GameSession
var plane: int = DepthPlane.FOREGROUND

func _ready():
	var game_root := get_node_or_null("/root/Game")
	if game_root != null:
		if player_id == 1:
			game_root.set("player_dark_ref", self)
		if player_id == 2:
			game_root.set("player_light_ref", self)

#Called by game.gd
func configure(owning_map: Node) -> void:
	map_instance = owning_map
	_setup_interaction()

func configure_for_map(id: int, owning_map: Node, game_session: GameSession = null) -> void:
	player_id = id
	map_instance = owning_map
	session = game_session
	current_tilemap_ref = map_instance.fg_physics_tile_map
	_setup_interaction()

func _setup_interaction() -> void:
	left_action = "p%d_move_left" % player_id
	right_action = "p%d_move_right" % player_id
	background_action = "p%d_move_background" % player_id
	foreground_action = "p%d_move_foreground" % player_id
	interact_action = INTERACT_ACTION % player_id
	if interaction_sensor == null:
		interaction_sensor = InteractionSensor.new()
		interaction_sensor.name = "InteractionSensor"
		interaction_sensor.player = self
		add_child(interaction_sensor)
	#position = Vector2(220.0, map_instance.get_lane_y(plane))

func _process(delta: float) -> void:
	
	#region Plane switching
	is_on_stairs = false #check_tile_data()
	print(current_tilemap_ref)
	if(!is_on_stairs):
		if Input.is_action_just_pressed(background_action):
			plane = DepthPlane.BACKGROUND
			collision_layer = 1
			collision_mask = 1
			z_index = 1
			sprite_depth_offset_target = sprite_depth_offset_bg
			current_tilemap_ref = map_instance.bg_physics_tile_map
		if Input.is_action_just_pressed(foreground_action):
			plane = DepthPlane.FOREGROUND
			collision_layer = 2
			collision_mask = 2
			z_index = 2
			sprite_depth_offset_target = sprite_depth_offset_fg
			current_tilemap_ref = map_instance.fg_physics_tile_map
	sprite_depth_offset = lerp(sprite_depth_offset, sprite_depth_offset_target, 0.2)
	sprite.position.y = sprite_depth_offset
	#endregion
	
	#region Interactions
	var direction := Input.get_axis(left_action, right_action)
	var next_x := position.x + direction * SPEED * delta
	if map_instance != null and map_instance.has_method("constrain_mansion_movement"):
		next_x = map_instance.constrain_mansion_movement(position.x, next_x, position.y)
	position.x = next_x
	_process_inventory_drop()
	if Input.is_action_just_pressed(interact_action) and interaction_sensor != null:
		var target := interaction_sensor.get_closest_interactable()
		if target != null:
			print("Interaction attempt: P%d -> %s" % [player_id, target.name])
			target.interact(self)
		else:
			print("Interaction attempt: P%d has no target in range" % player_id)
	#endregion

func _physics_process(delta):
	var direction := Input.get_axis(left_action, right_action)
	velocity.x = direction * SPEED
	velocity.y = min(velocity.y+GRV, MAX_VSP)
	move_and_slide()

func _process_inventory_drop() -> void:
	if session == null or session.inventory_actor_id != player_id:
		return
	for slot_index in GameSession.INVENTORY_SLOT_COUNT:
		if Input.is_action_just_pressed(DROP_SLOT_ACTION % (slot_index + 1)):
			var item := session.drop_inventory_slot(slot_index)
			if item.is_empty():
				print("P%d tried to drop empty inventory slot %d" % [player_id, slot_index + 1])
				return
			session.drop_shared_collectible(item, position)
			print("P%d dropped %s from slot %d" % [player_id, item.get("label", "Collectible"), slot_index + 1])
			return

func get_current_tile_coords() -> Vector2i:
	if(!current_tilemap_ref):
		return Vector2(0,0)
		
	# Convert player's global position to local TileMap position
	var check_pos = Vector2(global_position.x, global_position.y+32)
	var local_pos = current_tilemap_ref.to_local(check_pos)
	# Convert local position to cell/tile coordinates on the grid
	return current_tilemap_ref.local_to_map(local_pos)

func check_tile_data():
	if(!current_tilemap_ref):
		return Vector2(0,0)
	var coords = get_current_tile_coords()
	
	# Get the source ID of the tile at these coordinates (layer 0)
	var source_id = current_tilemap_ref.get_cell_source_id(coords)
	
	# Get custom tile data (useful for custom user data, e.g., speed, damage, biome)
	var tile_data: TileData = current_tilemap_ref.get_cell_tile_data(coords)
	if tile_data:
		# Access custom data properties if you set them up in the TileSet
		var custom_val = tile_data.get_custom_data("IsStair")
		return custom_val
		print("at coords "+str(coords)+" stairs are "+str(custom_val))
	return is_on_stairs

# End of player behavior.
