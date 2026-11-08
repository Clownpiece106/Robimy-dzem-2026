extends Node2D

@onready var session: GameSession = $GameSession
@onready var inventory_label = $Instructions/Inventory

func _ready() -> void:
	var first_map: MapInstance = $SplitScreenManager/Player1ViewportContainer/Player1Viewport/MapInstance1
	var second_map: MapInstance = $SplitScreenManager/Player2ViewportContainer/Player2Viewport/MapInstance2
	first_map.get_viewport().world_2d = World2D.new()
	second_map.get_viewport().world_2d = World2D.new()
	first_map.configure_existing(session, GameSession.PLAYER_1)
	second_map.configure_existing(session, GameSession.PLAYER_2)
	($GameOverOverlay as GameOverOverlay).configure(session)
	inventory_label.configure(session)
	print("Interaction test ready: P1 uses E, P2 uses Enter. Shared inventory uses 6, 7, and 8.")
