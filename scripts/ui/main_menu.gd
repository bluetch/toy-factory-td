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
	# Start from the highest unlocked level — or level 1 if only level 1 unlocked
	SceneManager.goto_level(1)

func _on_level_select_pressed() -> void:
	SceneManager.goto_level_select()

func _on_high_scores_pressed() -> void:
	high_scores_panel.visible = not high_scores_panel.visible
	if high_scores_panel.visible:
		_populate_high_scores()

func _populate_high_scores() -> void:
	# Find score labels inside the panel by name convention
	for i in range(1, 4):
		var label := high_scores_panel.get_node_or_null("Level%dScore" % i) as Label
		if label:
			label.text = "Level %d:  %d pts" % [i, SaveManager.get_high_score(i)]

func _on_quit_pressed() -> void:
	get_tree().quit()
