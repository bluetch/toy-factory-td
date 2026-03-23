## PauseMenu — overlay shown when game is paused.
## Provides inline music/SFX volume sliders so the player never
## has to leave the game world to adjust audio.
class_name PauseMenu
extends Control

@onready var resume_button:    Button  = $PanelContainer/VBox/ResumeButton
@onready var restart_button:   Button  = $PanelContainer/VBox/RestartButton
@onready var music_slider:     HSlider = $PanelContainer/VBox/VolumeSection/VolVBox/MusicRow/MusicSlider
@onready var music_value_lbl:  Label   = $PanelContainer/VBox/VolumeSection/VolVBox/MusicRow/MusicValueLabel
@onready var sfx_slider:       HSlider = $PanelContainer/VBox/VolumeSection/VolVBox/SFXRow/SFXSlider
@onready var sfx_value_lbl:    Label   = $PanelContainer/VBox/VolumeSection/VolVBox/SFXRow/SFXValueLabel
@onready var main_menu_button: Button  = $PanelContainer/VBox/MainMenuButton
@onready var quit_button:      Button  = $PanelContainer/VBox/QuitButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	EventBus.game_paused.connect(_on_pause_show)
	EventBus.game_resumed.connect(_on_pause_hide)
	hide()

func _on_pause_show() -> void:
	## Sync sliders to current saved volume before showing.
	music_slider.set_value_no_signal(SaveManager.get_setting("music_volume") * 100.0)
	sfx_slider.set_value_no_signal(SaveManager.get_setting("sfx_volume") * 100.0)
	_update_music_label(music_slider.value)
	_update_sfx_label(sfx_slider.value)

	var panel: Control = $PanelContainer
	panel.scale      = Vector2(0.82, 0.82)
	panel.modulate.a = 0.0
	show()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _on_pause_hide() -> void:
	var panel: Control = $PanelContainer
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.88, 0.88), 0.14)
	tw.tween_property(panel, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(hide)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause_game"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

# ── Button callbacks ──────────────────────────────────────────

func _on_resume_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.resume_game()

func _on_restart_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.resume_game()
	SceneManager.goto_level(GameManager.current_level_id)

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.resume_game()
	SceneManager.goto_main_menu()

func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit()

# ── Slider callbacks ──────────────────────────────────────────

func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value / 100.0)
	_update_music_label(value)

func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)
	_update_sfx_label(value)

func _update_music_label(value: float) -> void:
	music_value_lbl.text = "%d%%" % int(value)

func _update_sfx_label(value: float) -> void:
	sfx_value_lbl.text = "%d%%" % int(value)
