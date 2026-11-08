class_name GameOverOverlay
extends CanvasLayer

@onready var screen: Control = $Screen
@onready var title_label: Label = $Screen/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var detail_label: Label = $Screen/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Detail
@onready var retry_button: Button = $Screen/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/RetryButton

var session: GameSession

func configure(game_session: GameSession) -> void:
	session = game_session
	session.game_ended.connect(_on_game_ended)
	session.session_reset.connect(_on_session_reset)
	screen.hide()
	if session.is_game_over:
		_on_game_ended(session.ending, 0)

func _on_game_ended(result: String, player_id: int) -> void:
	if result == "good":
		title_label.text = "GOOD ENDING"
		detail_label.text = "Every candle and music box found its place."
	else:
		title_label.text = "GAME OVER"
		detail_label.text = "Player %d lost all their hearts." % player_id
	screen.show()
	retry_button.grab_focus()

func _on_session_reset() -> void:
	screen.hide()

func _on_retry_button_pressed() -> void:
	session.reset()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
