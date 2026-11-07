extends Node2D

@onready var session: GameSession = $GameSession
@onready var split_screen: SplitScreenManager = $SplitScreenManager

func _ready() -> void:
	split_screen.configure(session)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		session.reset()
