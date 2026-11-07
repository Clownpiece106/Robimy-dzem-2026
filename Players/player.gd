class_name CoopPlayer
extends Node2D

enum DepthPlane { BACKGROUND, FOREGROUND }

const SPEED := 220.0

@export var player_id: int
var map_instance: Node
var left_action: String
var right_action: String
var background_action: String
var foreground_action: String
var plane: int = DepthPlane.FOREGROUND

func _ready():
	if(player_id==1):
		Game.player_dark_ref = self
	if(player_id==2):
		Game.player_light_ref = self

#Called by game.gd
func configure(owning_map: Node) -> void:
	map_instance = owning_map
	left_action = "p%d_move_left" % player_id
	right_action = "p%d_move_right" % player_id
	background_action = "p%d_move_background" % player_id
	foreground_action = "p%d_move_foreground" % player_id
	#position = Vector2(220.0, map_instance.get_lane_y(plane))

func _process(delta: float) -> void:
	var direction := Input.get_axis(left_action, right_action)
	position.x = position.x + direction * SPEED * delta
	#if Input.is_action_just_pressed(background_action):
		#plane = DepthPlane.BACKGROUND
	#if Input.is_action_just_pressed(foreground_action):
		#plane = DepthPlane.FOREGROUND
	#position.y = map_instance.get_lane_y(plane)
