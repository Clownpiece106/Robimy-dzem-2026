extends Node2D

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		session.reset()
