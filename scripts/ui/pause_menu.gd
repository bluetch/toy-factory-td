## PauseMenu — overlay shown when game is paused.
class_name PauseMenu
extends Control

@onready var resume_button:    Button = $PanelContainer/VBox/ResumeButton
@onready var settings_button:  Button = $PanelContainer/VBox/SettingsButton
@onready var main_menu_button: Button = $PanelContainer/VBox/MainMenuButton
@onready var quit_button:      Button = $PanelContainer/VBox/QuitButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Inject Restart button between Resume and Settings
	var vbox: VBoxContainer = resume_button.get_parent() as VBoxContainer
	if vbox != null:
		var restart_btn := Button.new()
		restart_btn.text = "重新開始"
		restart_btn.pressed.connect(_on_restart_pressed)
		# Copy theme from existing button so it matches the scene's style
		restart_btn.theme = resume_button.theme
		vbox.add_child(restart_btn)
		vbox.move_child(restart_btn, resume_button.get_index() + 1)

	EventBus.game_paused.connect(show)
	EventBus.game_resumed.connect(hide)
	hide()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause_game"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.resume_game()

func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.resume_game()
	SceneManager.goto_settings(SceneManager.GAME_WORLD_SCENE)

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.resume_game()   # restore time_scale + unpause tree before leaving
	SceneManager.goto_main_menu()

func _on_restart_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.resume_game()
	SceneManager.goto_level(GameManager.current_level_id)

func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit()
