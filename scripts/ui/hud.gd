## HUD — in-game heads-up display.
## Shows lives, gold, score, current wave, speed toggle, pause button.
## Also hosts the TowerPanel and UpgradePanel overlays.
class_name HUD
extends Control

@onready var lives_label:      Label   = $TopBar/HBoxContainer/LivesLabel
@onready var gold_label:       Label   = $TopBar/HBoxContainer/GoldLabel
@onready var score_label:      Label   = $TopBar/HBoxContainer/ScoreLabel
@onready var wave_label:       Label   = $TopBar/HBoxContainer/WaveLabel
@onready var level_name_label: Label   = $TopBar/HBoxContainer/LevelNameLabel
@onready var speed_button:   Button  = $TopBar/HBoxContainer/SpeedButton
@onready var pause_button:   Button  = $TopBar/HBoxContainer/PauseButton
@onready var next_wave_btn:  Button  = $TopBar/HBoxContainer/NextWaveButton
@onready var message_label:  Label   = $MessageLabel
@onready var tower_panel:    Control = $TowerPanel
@onready var upgrade_panel:  Control = $UpgradePanel

## Reference to GameWorld (set externally or found via get_parent chain)
var game_world: Node = null

var _message_timer: float = 0.0
const MESSAGE_DURATION := 2.0

## Dynamically-created wave announcement banner
var _wave_banner: Label = null
var _banner_tween: Tween = null

## Tween for pulsing the next-wave button
var _wave_btn_tween: Tween = null

## Red vignette overlay that pulses when lives are critically low
var _vignette: ColorRect = null
var _vignette_tween: Tween = null
const DANGER_LIVES := 3

func _ready() -> void:
	# Connect EventBus signals
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.game_speed_changed.connect(_on_speed_changed)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.wave_started.connect(_on_wave_started)

	_build_wave_banner()
	_build_vignette()

	speed_button.pressed.connect(_on_speed_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	next_wave_btn.pressed.connect(_on_next_wave_pressed)
	next_wave_btn.hide()
	message_label.hide()
	upgrade_panel.hide()

	# Initial values
	_on_lives_changed(GameManager.lives)
	_on_gold_changed(GameManager.gold)
	_on_score_changed(GameManager.score)
	_on_speed_changed(GameManager.game_speed)

	# Level name + difficulty from LevelData resource
	var level_res: Resource = load("res://data/levels/level_%d.tres" % GameManager.current_level_id)
	if level_res != null and level_res.get("level_name") != null:
		var diff_names := ["簡單", "普通", "困難"]
		var diff_colors := [Color(0.50, 0.90, 0.50), Color(0.85, 0.80, 0.40), Color(1.0, 0.45, 0.35)]
		var diff_idx: int = GameManager.current_difficulty
		var diff_str: String = diff_names[diff_idx]
		level_name_label.text = "%s  [%s]" % [str(level_res.get("level_name")), diff_str]
		level_name_label.add_theme_color_override("font_color", diff_colors[diff_idx])

## Build a centered wave banner label (hidden until a wave starts)
func _build_wave_banner() -> void:
	_wave_banner = Label.new()
	_wave_banner.name = "WaveBanner"
	_wave_banner.anchor_left   = 0.5
	_wave_banner.anchor_right  = 0.5
	_wave_banner.anchor_top    = 0.0
	_wave_banner.anchor_bottom = 0.0
	_wave_banner.offset_left   = -200.0
	_wave_banner.offset_right  = 200.0
	_wave_banner.offset_top    = 64.0
	_wave_banner.offset_bottom = 110.0
	_wave_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_banner.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_wave_banner.add_theme_font_size_override("font_size", 28)
	_wave_banner.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	_wave_banner.modulate.a = 0.0
	add_child(_wave_banner)

## Called by EventBus.wave_started
func _on_wave_started(wave_number: int, total_waves: int) -> void:
	if _wave_banner == null:
		return
	_wave_banner.text = "— 波次 %d / %d —" % [wave_number, total_waves]
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_wave_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(2.5)
	_banner_tween.tween_property(_wave_banner, "modulate:a", 0.0, 0.5)

	# Also update wave label immediately
	wave_label.text = "波次: %d / %d" % [wave_number, total_waves]

## Build a full-screen red vignette that pulses on low lives
func _build_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.anchor_right  = 1.0
	_vignette.anchor_bottom = 1.0
	_vignette.grow_horizontal = 2
	_vignette.grow_vertical   = 2
	_vignette.color = Color(0.85, 0.0, 0.0, 0.0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.z_index = -1    ## render below HUD elements
	add_child(_vignette)

func _start_vignette_pulse() -> void:
	if _vignette_tween != null and _vignette_tween.is_valid():
		return   ## already pulsing
	_vignette_tween = create_tween().set_loops()
	_vignette_tween.tween_property(_vignette, "color:a", 0.28, 0.6).set_trans(Tween.TRANS_SINE)
	_vignette_tween.tween_property(_vignette, "color:a", 0.0,  0.6).set_trans(Tween.TRANS_SINE)

func _stop_vignette_pulse() -> void:
	if _vignette_tween != null and _vignette_tween.is_valid():
		_vignette_tween.kill()
		_vignette_tween = null
	if _vignette != null:
		_vignette.color.a = 0.0

## Called by GameWorld
func set_game_world(gw: Node) -> void:
	game_world = gw

func _process(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			message_label.hide()

## Show a brief floating message (e.g. "Not enough gold!")
func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	_message_timer = MESSAGE_DURATION

## Called by WaveManager.next_wave_ready signal
func on_next_wave_ready(wave_number: int, total_waves: int) -> void:
	var current := wave_number - 1
	wave_label.text = "波次: %d / %d" % [current, total_waves]
	next_wave_btn.text = "開始波次 %d ▶" % wave_number
	next_wave_btn.show()
	_start_wave_btn_pulse()

## Pulse the next-wave button to draw the player's eye
func _start_wave_btn_pulse() -> void:
	_stop_wave_btn_pulse()
	_wave_btn_tween = create_tween().set_loops()
	_wave_btn_tween.tween_property(next_wave_btn, "modulate", Color(1.3, 1.3, 0.8, 1.0), 0.5) \
		.set_trans(Tween.TRANS_SINE)
	_wave_btn_tween.tween_property(next_wave_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5) \
		.set_trans(Tween.TRANS_SINE)

func _stop_wave_btn_pulse() -> void:
	if _wave_btn_tween != null and _wave_btn_tween.is_valid():
		_wave_btn_tween.kill()
		_wave_btn_tween = null
	next_wave_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

## Called every frame by WaveManager.next_wave_countdown signal
func on_wave_countdown(seconds: float) -> void:
	if seconds > 0.0:
		next_wave_btn.text = "開始波次 ▶  (%d)" % int(ceil(seconds))
	else:
		next_wave_btn.text = "準備中…"

func on_all_waves_done() -> void:
	_stop_wave_btn_pulse()
	next_wave_btn.hide()
	wave_label.text = "全部波次完成！"

## Show upgrade panel for the selected tower
func show_upgrade_panel(tower: Node) -> void:
	upgrade_panel.show()
	if upgrade_panel.has_method("populate"):
		upgrade_panel.populate(tower)

func hide_upgrade_panel() -> void:
	upgrade_panel.hide()

# ---- EventBus callbacks ----

func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "❤ %d" % new_lives
	if new_lives <= DANGER_LIVES and new_lives > 0:
		_start_vignette_pulse()
	else:
		_stop_vignette_pulse()

func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "💰 %d" % new_gold

func _on_score_changed(new_score: int) -> void:
	score_label.text = "⭐ %d" % new_score

func _on_speed_changed(new_speed: float) -> void:
	speed_button.text = "%.0fx" % new_speed

func _on_game_paused() -> void:
	pause_button.text = "▶ 繼續"

func _on_game_resumed() -> void:
	pause_button.text = "⏸ 暫停"

func _on_speed_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.toggle_speed()

func _on_pause_pressed() -> void:
	AudioManager.play_ui_click()
	if GameManager.state == GameManager.GameState.PAUSED:
		GameManager.resume_game()
	else:
		GameManager.pause_game()

func _on_next_wave_pressed() -> void:
	AudioManager.play_ui_click()
	_stop_wave_btn_pulse()
	next_wave_btn.hide()
	# GameWorld owns WaveManager, look it up
	var wm: Node = get_tree().get_first_node_in_group("wave_manager")
	if wm and wm.has_method("start_next_wave"):
		wm.start_next_wave()
