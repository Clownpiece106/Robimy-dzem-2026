@tool
class_name MansionTrapdoorEndpoint
extends Interactable

@export var destination: NodePath

func can_interact(_player: CoopPlayer) -> bool:
	return _trapdoor() != null

func interact(player: CoopPlayer) -> void:
	var trapdoor := _trapdoor()
	if trapdoor != null:
		trapdoor.interact(player)

func _on_entering_area_body_entered(body: Node2D) -> void:
	var player := body as CoopPlayer
	var marker := get_node_or_null(destination) as Marker2D
	var trapdoor := _trapdoor()
	if player != null and marker != null and trapdoor != null:
		trapdoor.traverse(player, marker)

func _trapdoor() -> MansionTrapdoor:
	return get_parent() as MansionTrapdoor
