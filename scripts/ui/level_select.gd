## LevelSelect — shows level cards with lock/unlock state and best scores.
class_name LevelSelectUI
extends Control

@onready var back_button: Button = $BackButton
## Level cards are named LevelCard1, LevelCard2, LevelCard3
@onready var level_cards: Array[Node] = []

func _ready() -> void:
	back_button.pressed.connect(SceneManager.goto_main_menu)

	for i in range(1, 4):
		var card := get_node_or_null("LevelsContainer/LevelCard%d" % i)
		if card == null:
			continue
		level_cards.append(card)
		var unlocked := SaveManager.is_level_unlocked(i)

		# Locked overlay
		var locked_overlay := card.get_node_or_null("LockedOverlay") as Control
		if locked_overlay:
			locked_overlay.visible = not unlocked

		# Best score label
		var score_label := card.get_node_or_null("BestScore") as Label
		if score_label:
			if unlocked:
				var best := SaveManager.get_high_score(i)
				score_label.text = "Best: %d" % best if best > 0 else "Not played"
			else:
				score_label.text = "Locked"

		# Play button
		var play_btn := card.get_node_or_null("PlayButton") as Button
		if play_btn:
			play_btn.disabled = not unlocked
			var level_id := i  # capture for lambda
			play_btn.pressed.connect(func() -> void: SceneManager.goto_level(level_id))
