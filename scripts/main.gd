extends Node2D

var session: GameSession
var split_screen: SplitScreenManager

func _ready() -> void:
	InputSetup.configure()
	session = GameSession.new()
	session.name = "GameSession"
	add_child(session)

	split_screen = SplitScreenManager.new()
	split_screen.name = "SplitScreenManager"
	add_child(split_screen)
	split_screen.configure(session)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		session.reset()
