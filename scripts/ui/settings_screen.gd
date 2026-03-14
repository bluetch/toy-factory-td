## SettingsScreen — music/sfx volume sliders, fullscreen toggle, back navigation.
class_name SettingsScreen
extends Control

@onready var music_slider:    HSlider     = $Panel/VBox/MusicRow/MusicSlider
@onready var music_value:     Label       = $Panel/VBox/MusicRow/MusicValueLabel
@onready var sfx_slider:      HSlider     = $Panel/VBox/SFXRow/SFXSlider
@onready var sfx_value:       Label       = $Panel/VBox/SFXRow/SFXValueLabel
@onready var fullscreen_btn:  CheckButton = $Panel/VBox/FullscreenRow/FullscreenButton
@onready var back_button:     Button      = $Panel/VBox/BackButton

func _ready() -> void:
	# Populate from saved settings
	music_slider.value = SaveManager.get_setting("music_volume") * 100.0
	sfx_slider.value   = SaveManager.get_setting("sfx_volume")   * 100.0
	fullscreen_btn.button_pressed = SaveManager.get_setting_bool("fullscreen")

	_update_music_label(music_slider.value)
	_update_sfx_label(sfx_slider.value)

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_btn.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)

# ── Slider callbacks ─────────────────────────────────────────

func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value / 100.0)
	_update_music_label(value)

func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)
	_update_sfx_label(value)
	AudioManager.play_ui_click()

func _on_fullscreen_toggled(pressed: bool) -> void:
	SaveManager.set_setting_bool("fullscreen", pressed)
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	SceneManager.settings_done()

# ── Label helpers ────────────────────────────────────────────

func _update_music_label(value: float) -> void:
	music_value.text = "%d%%" % int(value)

func _update_sfx_label(value: float) -> void:
	sfx_value.text = "%d%%" % int(value)
