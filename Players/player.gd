class_name CoopPlayer
extends Node2D

enum DepthPlane { BACKGROUND, FOREGROUND }

const SPEED := 220.0
const INTERACT_ACTION := "p%d_interact"
const DROP_SLOT_ACTION := "inventory_drop_slot_%d"

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
	if(player_id==1):
		Game.player_dark_ref = self
	if(player_id==2):
		Game.player_light_ref = self

#Called by game.gd
func configure(owning_map: Node) -> void:
	map_instance = owning_map
	_setup_interaction()

func configure_for_map(id: int, owning_map: Node, game_session: GameSession = null) -> void:
	player_id = id
	map_instance = owning_map
	session = game_session
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
	var direction := Input.get_axis(left_action, right_action)
	position.x = position.x + direction * SPEED * delta
	_process_inventory_drop()
	if Input.is_action_just_pressed(interact_action) and interaction_sensor != null:
		var target := interaction_sensor.get_closest_interactable()
		if target != null:
			print("Interaction attempt: P%d -> %s" % [player_id, target.name])
			target.interact(self)
		else:
			print("Interaction attempt: P%d has no target in range" % player_id)

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

# End of player behavior.
	#if Input.is_action_just_pressed(background_action):
		#plane = DepthPlane.BACKGROUND
	#if Input.is_action_just_pressed(foreground_action):
		#plane = DepthPlane.FOREGROUND
	#position.y = map_instance.get_lane_y(plane)

