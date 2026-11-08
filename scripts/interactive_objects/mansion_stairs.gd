@tool
class_name MansionStairs
extends Interactable

@export var destination: NodePath
@export var automatic := false

func can_interact(player: CoopPlayer) -> bool:
	return not automatic and player.plane == CoopPlayer.DepthPlane.BACKGROUND and get_node_or_null(destination) is Marker2D

func interact(player: CoopPlayer) -> void:
	if can_interact(player):
		_traverse(player)

func _on_entering_area_body_entered(body: Node2D) -> void:
	var player := body as CoopPlayer
	if automatic and player != null and player.plane == CoopPlayer.DepthPlane.BACKGROUND:
		_traverse(player)

func _traverse(player: CoopPlayer) -> void:
	var marker := get_node_or_null(destination) as Marker2D
	if marker == null:
		return
	player.global_position = marker.global_position
	player.velocity = Vector2.ZERO
	player.publish_position()
	print("P%d used stairs %s" % [player.player_id, get_parent().name])
