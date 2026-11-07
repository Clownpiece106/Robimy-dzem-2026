@tool
class_name Interactable
extends Node2D

## Base contract for objects a player can activate.
func can_interact(_player: CoopPlayer) -> bool:
	return true

func interact(_player: CoopPlayer) -> void:
	pass

func get_interaction_position() -> Vector2:
	return global_position
