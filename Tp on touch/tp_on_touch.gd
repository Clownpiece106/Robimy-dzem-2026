extends Area2D

@onready var target = $Target

func _on_body_entered(body):
	if(body.is_in_group("Player")):
		body.position = target.global_position
