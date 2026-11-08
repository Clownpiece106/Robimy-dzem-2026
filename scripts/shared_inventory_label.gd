extends Label

func configure(session: GameSession) -> void:
	session.inventory_changed.connect(_update_slots)
	_update_slots(session.inventory_slots)

func _update_slots(slots: Array) -> void:
	var descriptions: Array[String] = []
	for slot_index in GameSession.INVENTORY_SLOT_COUNT:
		var item: Dictionary = slots[slot_index]
		var label := "Empty" if item.is_empty() else str(item.get("label", "Collectible"))
		descriptions.append("[%d] %s" % [slot_index + 6, label])
	text = "SHARED INVENTORY  %s" % "   ".join(descriptions)
