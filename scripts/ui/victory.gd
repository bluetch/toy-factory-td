## VictoryUI — shown when the player survives all waves.
## Starts hidden; displays itself when EventBus.victory_triggered fires.
## High-score saving and level unlock are handled by GameManager.victory()
## before this signal is emitted, so we only need to display the results.
class_name VictoryUI
extends Control

@onready var score_label:       Label  = $PanelContainer/VBox/ScoreLabel
@onready var high_score_label:  Label  = $PanelContainer/VBox/HighScoreLabel
@onready var enemies_label:     Label  = $PanelContainer/VBox/EnemiesLabel
@onready var towers_label:      Label  = $PanelContainer/VBox/TowersLabel
@onready var next_level_button: Button = $PanelContainer/VBox/NextLevelButton
@onready var main_menu_button:  Button = $PanelContainer/VBox/MainMenuButton

func _ready() -> void:
	hide()
	EventBus.victory_triggered.connect(_on_victory)
	next_level_button.pressed.connect(_on_next_level_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_victory() -> void:
	var level_id := GameManager.current_level_id
	score_label.text      = "分數：%d" % GameManager.score
	high_score_label.text = "最佳：%d" % SaveManager.get_high_score(level_id)
	enemies_label.text    = "擊殺敵人：%d" % AchievementManager.get_session_enemies()
	towers_label.text     = "建造防禦塔：%d" % AchievementManager.get_session_towers()

	var next_level := level_id + 1
	if next_level <= SaveManager.MAX_LEVEL:
		next_level_button.text     = "下一關 (%d) ▶" % next_level
		next_level_button.disabled = false
	else:
		# Last level cleared — offer epilogue
		next_level_button.text     = "觀看結局 ▶"
		next_level_button.disabled = false

	show()

func _on_next_level_pressed() -> void:
	AudioManager.play_ui_click()
	var level_id   := GameManager.current_level_id
	var next_level := level_id + 1
	if next_level <= SaveManager.MAX_LEVEL:
		SceneManager.goto_level_outro(level_id, func() -> void:
			SceneManager.goto_level(next_level)
		)
	else:
		# Play epilogue then return to main menu
		SceneManager.goto_story("epilogue", func() -> void:
			SceneManager.goto_main_menu()
		)

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_main_menu()
