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
