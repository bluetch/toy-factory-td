## MainMenu — title screen with staggered button entrance and hover animations.
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

	_animate_entrance()


## Staggered fade-in entrance for all menu buttons.
## Uses modulate only — avoids modifying position on Container children
## (VBoxContainer overrides child positions on layout refresh, causing snaps).
func _animate_entrance() -> void:
	var buttons: Array[Button] = [play_button, level_select_button, settings_button, quit_button]
	for i in range(buttons.size()):
		var btn := buttons[i]
		if btn == null:
			continue
		btn.modulate.a = 0.0
		var delay := 0.12 + i * 0.10
		var tw := btn.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_interval(delay)
		tw.tween_property(btn, "modulate:a", 1.0, 0.30)
		_wire_hover(btn)


func _wire_hover(btn: Button) -> void:
	btn.mouse_entered.connect(func() -> void:
		## Set pivot to button centre so scale expands equally in all directions
		## (avoids visual overflow into neighbouring buttons).
		btn.pivot_offset = btn.size / 2.0
		btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
			.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12)
	)
	btn.mouse_exited.connect(func() -> void:
		btn.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) \
			.tween_property(btn, "scale", Vector2.ONE, 0.14)
	)


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
