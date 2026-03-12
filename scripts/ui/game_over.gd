## GameOverUI — shown when the player loses all lives.
## Starts hidden; displays itself when EventBus.game_over_triggered fires.
class_name GameOverUI
extends Control

@onready var score_label:      Label  = $PanelContainer/VBox/ScoreLabel
@onready var retry_button:     Button = $PanelContainer/VBox/RetryButton
@onready var main_menu_button: Button = $PanelContainer/VBox/MainMenuButton

func _ready() -> void:
	hide()
	# Listen for the game-over event; populate + show when received
	EventBus.game_over_triggered.connect(_on_game_over)
	retry_button.pressed.connect(_on_retry)
	main_menu_button.pressed.connect(SceneManager.goto_main_menu)

func _on_game_over() -> void:
	score_label.text = "Score: %d" % GameManager.score
	show()

func _on_retry() -> void:
	SceneManager.goto_level(GameManager.current_level_id)
