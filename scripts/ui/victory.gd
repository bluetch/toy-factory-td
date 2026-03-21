## VictoryUI — shown when the player survives all waves.
## Starts hidden; displays itself when EventBus.victory_triggered fires.
## High-score saving and level unlock are handled by GameManager.victory()
## before this signal is emitted, so we only need to display the results.
class_name VictoryUI
extends Control

@onready var score_label:       Label  = $PanelContainer/VBox/StatBox/StatVBox/ScoreLabel
@onready var high_score_label:  Label  = $PanelContainer/VBox/StatBox/StatVBox/HighScoreLabel
@onready var enemies_label:     Label  = $PanelContainer/VBox/StatBox/StatVBox/EnemiesLabel
@onready var towers_label:      Label  = $PanelContainer/VBox/StatBox/StatVBox/TowersLabel
@onready var next_level_button: Button = $PanelContainer/VBox/NextLevelButton
@onready var main_menu_button:  Button = $PanelContainer/VBox/MainMenuButton

## Dynamically injected difficulty label
var _diff_label: Label = null

func _ready() -> void:
	hide()
	EventBus.victory_triggered.connect(_on_victory)
	next_level_button.pressed.connect(_on_next_level_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	# Inject difficulty label at the bottom of the stat box
	_diff_label = Label.new()
	_diff_label.add_theme_font_size_override("font_size", 13)
	towers_label.get_parent().add_child(_diff_label)

func _on_victory() -> void:
	AudioManager.play_victory_sting()
	AudioManager.play_track("victory")
	var level_id := GameManager.current_level_id
	score_label.text      = "分數：%d" % GameManager.score
	high_score_label.text = "最佳：%d" % SaveManager.get_high_score(level_id)
	enemies_label.text    = "擊殺敵人：%d" % AchievementManager.get_session_enemies()
	towers_label.text     = "建造防禦塔：%d" % AchievementManager.get_session_towers()
	var di := GameManager.current_difficulty
	_diff_label.text = "難度：%s" % GameManager.DIFFICULTY_NAMES[di]
	_diff_label.add_theme_color_override("font_color", GameManager.DIFFICULTY_COLORS[di])

	var next_level := level_id + 1
	if next_level <= SaveManager.MAX_LEVEL:
		next_level_button.text     = "下一關 (%d) ▶" % next_level
		next_level_button.disabled = false
	else:
		# Last level cleared — offer epilogue
		next_level_button.text     = "觀看結局 ▶"
		next_level_button.disabled = false

	# Entrance animation: panel spring scale-in + staggered stat reveal
	var panel: Control = $PanelContainer
	panel.scale      = Vector2(0.65, 0.65)
	panel.modulate.a = 0.0
	var stats: Array[Label] = [score_label, high_score_label, enemies_label, towers_label, _diff_label]
	for lbl in stats:
		if lbl != null:
			lbl.modulate.a = 0.0
	show()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.38) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	for i in range(stats.size()):
		var lbl: Label = stats[i]
		if lbl == null:
			continue
		tw.tween_property(lbl, "modulate:a", 1.0, 0.20).set_delay(0.22 + float(i) * 0.12)

func _on_next_level_pressed() -> void:
	AudioManager.play_ui_click()
	var level_id   := GameManager.current_level_id
	var next_level := level_id + 1
	if next_level <= SaveManager.MAX_LEVEL:
		GameManager.prepare_carry_gold()
		# Show Roguelike skill-pick screen before proceeding
		_show_skill_select(func() -> void:
			SceneManager.goto_level_outro(level_id, func() -> void:
				SceneManager.goto_level(next_level)
			)
		)
	else:
		SceneManager.goto_level_outro(level_id, func() -> void:
			SceneManager.goto_story("epilogue", func() -> void:
				SceneManager.goto_main_menu()
			)
		)


func _show_skill_select(next: Callable) -> void:
	var skills := SkillManager.pick_random_skills(3)
	var screen  := SkillSelectScreen.new()
	get_tree().root.add_child(screen)
	screen.show_and_pick(skills, func(skill_id: String) -> void:
		SkillManager.apply(skill_id)
		next.call()
	)

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_click()
	SkillManager.reset()
	SceneManager.goto_main_menu()
