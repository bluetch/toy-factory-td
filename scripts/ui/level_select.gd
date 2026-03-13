## LevelSelect — shows level cards with lock/unlock state and best scores.
class_name LevelSelectUI
extends Control

@onready var back_button: Button = $BackButton
@onready var _easy_btn:   Button = $DifficultyRow/DifficultyButtons/EasyButton
@onready var _normal_btn: Button = $DifficultyRow/DifficultyButtons/NormalButton
@onready var _hard_btn:   Button = $DifficultyRow/DifficultyButtons/HardButton

## Level cards are named LevelCard1, LevelCard2, LevelCard3
@onready var level_cards: Array[Node] = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	# Difficulty buttons
	_easy_btn.pressed.connect(func() -> void:   _set_difficulty(GameManager.Difficulty.EASY))
	_normal_btn.pressed.connect(func() -> void: _set_difficulty(GameManager.Difficulty.NORMAL))
	_hard_btn.pressed.connect(func() -> void:   _set_difficulty(GameManager.Difficulty.HARD))
	_refresh_difficulty_buttons()

	for i in range(1, SaveManager.MAX_LEVEL + 1):
		var card: Node = get_node_or_null("LevelsContainer/LevelCard%d" % i)
		if card == null:
			continue
		level_cards.append(card)
		var unlocked := SaveManager.is_level_unlocked(i)

		# Locked overlay
		var locked_overlay := card.get_node_or_null("VBoxContainer/LockedOverlay") as Control
		if locked_overlay:
			locked_overlay.visible = not unlocked

		# Best score label
		var score_label := card.get_node_or_null("VBoxContainer/BestScore") as Label
		if score_label:
			if unlocked:
				var best := SaveManager.get_high_score(i)
				score_label.text = "Best: %d" % best if best > 0 else "Not played"
			else:
				score_label.text = "Locked"

		# Play button
		var play_btn := card.get_node_or_null("VBoxContainer/PlayButton") as Button
		if play_btn:
			play_btn.disabled = not unlocked
			var level_id := i  # capture for lambda
			play_btn.pressed.connect(func() -> void:
				AudioManager.play_ui_click()
				SceneManager.goto_level(level_id)
			)

func _set_difficulty(diff: GameManager.Difficulty) -> void:
	AudioManager.play_ui_click()
	GameManager.current_difficulty = diff
	_refresh_difficulty_buttons()

func _refresh_difficulty_buttons() -> void:
	var diff: GameManager.Difficulty = GameManager.current_difficulty
	_easy_btn.modulate   = Color(1.0, 1.0, 1.0, 1.0) if diff == GameManager.Difficulty.EASY   else Color(0.6, 0.6, 0.6, 1.0)
	_normal_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if diff == GameManager.Difficulty.NORMAL else Color(0.6, 0.6, 0.6, 1.0)
	_hard_btn.modulate   = Color(1.0, 1.0, 1.0, 1.0) if diff == GameManager.Difficulty.HARD   else Color(0.6, 0.6, 0.6, 1.0)

func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	SceneManager.goto_main_menu()
