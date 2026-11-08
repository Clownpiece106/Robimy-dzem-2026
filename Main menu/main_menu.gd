extends Control
@onready var selector = $TextureRect2
@onready var label = $ColorRect

func _on_button_button_down():
	visible = false
	var pos = get_viewport().get_mouse_position()
	selector.position = Vector2(pos.x - 250, pos.y - 250)
	selector.visible = true

func _on_button_2_button_down():
	var pos = get_viewport().get_mouse_position()
	selector.position = Vector2(pos.x - 250, pos.y - 250)
	selector.visible = true
	label.visible = !label.visible

func _on_button_3_button_down():
	var pos = get_viewport().get_mouse_position()
	selector.position = Vector2(pos.x - 250, pos.y - 250)
	selector.visible = true
	get_tree().quit()
