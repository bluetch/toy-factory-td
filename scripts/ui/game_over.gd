## GameOverUI — shown when the player loses all lives.
## Starts hidden; displays itself when EventBus.game_over_triggered fires.
class_name GameOverUI
extends Control

@onready var score_label:      Label  = $PanelContainer/VBox/StatBox/StatVBox/ScoreLabel
@onready var enemies_label:    Label  = $PanelContainer/VBox/StatBox/StatVBox/EnemiesLabel
@onready var retry_button:     Button = $PanelContainer/VBox/RetryButton
@onready var main_menu_button: Button = $PanelContainer/VBox/MainMenuButton

## Dynamically injected labels for extra session stats
var _towers_label: Label = null
var _diff_label:   Label = null

func _ready() -> void:
	hide()
	# Listen for the game-over event; populate + show when received
	EventBus.game_over_triggered.connect(_on_game_over)
	retry_button.pressed.connect(_on_retry)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	# Inject extra stat labels at the bottom of the stat box
	var stat_vbox: Node = enemies_label.get_parent()
	_towers_label = Label.new()
	_towers_label.add_theme_font_size_override("font_size", 13)
	_towers_label.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	stat_vbox.add_child(_towers_label)
	_diff_label = Label.new()
	_diff_label.add_theme_font_size_override("font_size", 13)
	stat_vbox.add_child(_diff_label)

func _on_game_over() -> void:
	AudioManager.play_game_over()
	score_label.text   = "分數：%d" % GameManager.score
	enemies_label.text = "擊殺敵人：%d" % AchievementManager.get_session_enemies()
	if _towers_label != null:
		_towers_label.text = "建造防禦塔：%d" % AchievementManager.get_session_towers()
	if _diff_label != null:
		var di := GameManager.current_difficulty
		_diff_label.text = "難度：%s" % GameManager.DIFFICULTY_NAMES[di]
		_diff_label.add_theme_color_override("font_color", GameManager.DIFFICULTY_COLORS[di])
	show()

func _on_retry() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_level(GameManager.current_level_id)

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_main_menu()
