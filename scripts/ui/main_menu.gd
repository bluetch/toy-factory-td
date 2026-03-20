## MainMenu — handles the title screen buttons.
class_name MainMenuUI
extends Control

@onready var play_button:         Button = $CenterPanel/VBox/MenuContainer/PlayButton
@onready var level_select_button: Button = $CenterPanel/VBox/MenuContainer/LevelSelectButton
@onready var settings_button:     Button = $CenterPanel/VBox/MenuContainer/SettingsButton
@onready var quit_button:         Button = $CenterPanel/VBox/MenuContainer/QuitButton
@onready var version_label:       Label  = $VersionLabel


func _ready() -> void:
	AudioManager.play_track("menu")
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.1.0")
	play_button.pressed.connect(_on_play_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	AudioManager.play_ui_click()
	var start_level := 1
	for id in range(SaveManager.MAX_LEVEL, 0, -1):
		if SaveManager.is_level_unlocked(id):
			start_level = id
			break
	SceneManager.goto_level(start_level)


func _on_level_select_pressed() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_level_select()


func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_settings(SceneManager.MAIN_MENU_SCENE)


func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit()
