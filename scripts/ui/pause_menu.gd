## PauseMenu — overlay shown when game is paused.
class_name PauseMenu
extends Control

@onready var resume_button:    Button = $PanelContainer/VBox/ResumeButton
@onready var main_menu_button: Button = $PanelContainer/VBox/MainMenuButton
@onready var quit_button:      Button = $PanelContainer/VBox/QuitButton

func _ready() -> void:
	resume_button.pressed.connect(GameManager.resume_game)
	main_menu_button.pressed.connect(SceneManager.goto_main_menu)
	quit_button.pressed.connect(get_tree().quit)

	EventBus.game_paused.connect(show)
	EventBus.game_resumed.connect(hide)
	hide()
