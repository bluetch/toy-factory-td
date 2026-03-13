## MainMenu — handles the title screen buttons.
class_name MainMenuUI
extends Control

@onready var play_button:         Button = $MenuContainer/PlayButton
@onready var level_select_button: Button = $MenuContainer/LevelSelectButton
@onready var high_scores_button:  Button = $MenuContainer/HighScoresButton
@onready var quit_button:         Button = $MenuContainer/QuitButton
@onready var version_label:       Label  = $VersionLabel
@onready var high_scores_panel:   Control = $HighScoresPanel

func _ready() -> void:
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.1.0")
	play_button.pressed.connect(_on_play_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	high_scores_button.pressed.connect(_on_high_scores_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	high_scores_panel.hide()

func _on_play_pressed() -> void:
	AudioManager.play_ui_click()
	# Start from the highest unlocked level
	var start_level := 1
	for id in range(SaveManager.MAX_LEVEL, 0, -1):
		if SaveManager.is_level_unlocked(id):
			start_level = id
			break
	SceneManager.goto_level(start_level)

func _on_level_select_pressed() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_level_select()

func _on_high_scores_pressed() -> void:
	AudioManager.play_ui_click()
	high_scores_panel.visible = not high_scores_panel.visible
	if high_scores_panel.visible:
		_populate_high_scores()

func _populate_high_scores() -> void:
	for i in range(1, SaveManager.MAX_LEVEL + 1):
		var label := high_scores_panel.get_node_or_null("VBoxContainer/Level%dScore" % i) as Label
		if label:
			label.text = "Level %d:  %d pts" % [i, SaveManager.get_high_score(i)]

func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit()
