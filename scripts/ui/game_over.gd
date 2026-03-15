## GameOverUI — shown when the player loses all lives.
## Starts hidden; displays itself when EventBus.game_over_triggered fires.
class_name GameOverUI
extends Control

@onready var score_label:      Label  = $PanelContainer/VBox/ScoreLabel
@onready var enemies_label:    Label  = $PanelContainer/VBox/EnemiesLabel
@onready var retry_button:     Button = $PanelContainer/VBox/RetryButton
@onready var main_menu_button: Button = $PanelContainer/VBox/MainMenuButton

func _ready() -> void:
	hide()
	# Listen for the game-over event; populate + show when received
	EventBus.game_over_triggered.connect(_on_game_over)
	retry_button.pressed.connect(_on_retry)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_game_over() -> void:
	AudioManager.play_game_over()
	score_label.text   = "分數：%d" % GameManager.score
	enemies_label.text = "擊殺敵人：%d" % AchievementManager.get_session_enemies()
	show()

func _on_retry() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_level(GameManager.current_level_id)

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_main_menu()
