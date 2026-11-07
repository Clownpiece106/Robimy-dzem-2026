extends Node2D

@onready var session: GameSession = $GameSession

func _ready() -> void:
	var first_map: MapInstance = $SplitScreenManager/Player1ViewportContainer/Player1Viewport/MapInstance1
	var second_map: MapInstance = $SplitScreenManager/Player2ViewportContainer/Player2Viewport/MapInstance2
	first_map.configure_existing(session, GameSession.PLAYER_1)
	second_map.configure_existing(session, GameSession.PLAYER_2)
	print("Interaction test ready: P1 uses E, P2 uses Enter.")
