extends Interactable

@export var object_label := "OBJECT"

func interact(player: CoopPlayer) -> void:
	print("Interaction succeeded: P%d used %s" % [player.player_id, object_label])
