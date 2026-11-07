extends Node2D

@onready var session: GameSession = $GameSession
@onready var inventory_label: Label = $Instructions/Inventory

func _ready() -> void:
	var first_map: MapInstance = $SplitScreenManager/Player1ViewportContainer/Player1Viewport/MapInstance1
	var second_map: MapInstance = $SplitScreenManager/Player2ViewportContainer/Player2Viewport/MapInstance2
	first_map.configure_existing(session, GameSession.PLAYER_1)
	second_map.configure_existing(session, GameSession.PLAYER_2)
	session.inventory_changed.connect(_on_inventory_changed)
	_on_inventory_changed(session.inventory_slots)
	print("Interaction test ready: P1 uses E, P2 uses Enter. Shared inventory uses 6, 7, and 8.")

func _on_inventory_changed(slots: Array) -> void:
	var descriptions: Array[String] = []
	for slot_index in GameSession.INVENTORY_SLOT_COUNT:
		var item: Dictionary = slots[slot_index]
		var label := "Empty" if item.is_empty() else str(item.get("label", "Collectible"))
		descriptions.append("[%d] %s" % [slot_index + 6, label])
	inventory_label.text = "SHARED INVENTORY  %s" % "   ".join(descriptions)
