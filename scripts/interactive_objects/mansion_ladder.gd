class_name MansionLadder
extends Interactable
@export var destination_y := 390.0
func interact(player: CoopPlayer) -> void:
	player.position.y = destination_y
	print("P%d used ladder to floor y=%s" % [player.player_id, destination_y])
func _draw() -> void:
	draw_line(Vector2(-20, -110), Vector2(-20, 0), Color("#c09b6c"), 5.0)
	draw_line(Vector2(20, -110), Vector2(20, 0), Color("#c09b6c"), 5.0)
	for y in range(-100, 1, 20):
		draw_line(Vector2(-20, y), Vector2(20, y), Color("#c09b6c"), 4.0)
