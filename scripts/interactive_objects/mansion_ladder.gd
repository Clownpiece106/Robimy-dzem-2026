@tool
class_name MansionLadder
extends Interactable

@export var destination: NodePath

func can_interact(_player: CoopPlayer) -> bool:
	return get_node_or_null(destination) is Marker2D

func interact(player: CoopPlayer) -> void:
	var marker := get_node_or_null(destination) as Marker2D
	if marker != null:
		player.global_position = marker.global_position
		print("P%d used ladder at %s" % [player.player_id, name])

func _draw() -> void:
	draw_line(Vector2(-20, -110), Vector2(-20, 0), Color("#c09b6c"), 5.0)
	draw_line(Vector2(20, -110), Vector2(20, 0), Color("#c09b6c"), 5.0)
	for y in range(-100, 1, 20):
		draw_line(Vector2(-20, y), Vector2(20, y), Color("#c09b6c"), 4.0)
