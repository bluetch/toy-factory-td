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
## Queue of pending messages so rapid events don't stomp each other.
var _message_queue: Array[String] = []

## Dynamically-created wave announcement banner
var _wave_banner: Label = null
var _banner_tween: Tween = null
## Wave composition preview label (shown between waves)
var _wave_preview_label: Label = null

## Tween for pulsing the next-wave button
var _wave_btn_tween: Tween = null

## Red vignette overlay that pulses when lives are critically low
var _vignette: ColorRect = null
var _vignette_tween: Tween = null
const DANGER_LIVES := 3

## Boss HP bar — shown only when a boss is on the field
var _boss_bar_root: Control = null
var _boss_bar_fill: ColorRect = null
var _boss_bar_label: Label = null
var _boss_max_hp: float = 1.0
const BOSS_BAR_W := 440.0
const BOSS_BAR_H := 22.0

## Enemy count tracking (updated via EventBus.enemy_count_changed)
var _enemies_alive: int = 0
var _enemies_total: int = 0
## Current wave tracking (for refresh after count update)
var _wave_num: int = 0
var _wave_total: int = 0

func _ready() -> void:
	# Connect EventBus signals
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.game_speed_changed.connect(_on_speed_changed)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_count_changed.connect(_on_enemy_count_changed)
	EventBus.wave_bonus_awarded.connect(_on_wave_bonus_awarded)

	_build_wave_banner()
	_build_wave_preview()
	_build_vignette()
	_build_boss_bar()

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

	# Initial wave label (shows "0 / N" before first wave starts)
	var _init_level_res: Resource = load("res://data/levels/level_%d.tres" % GameManager.current_level_id)
	if _init_level_res != null and _init_level_res.get("waves") != null:
		_wave_total = (_init_level_res.get("waves") as Array).size()
	wave_label.text = "波次: 0 / %d" % _wave_total

	# Level name + difficulty from LevelData resource
	var level_res: Resource = _init_level_res
	if level_res != null and level_res.get("level_name") != null:
		var diff_idx: int = GameManager.current_difficulty
		level_name_label.text = "%s  [%s]" % [str(level_res.get("level_name")), GameManager.DIFFICULTY_NAMES[diff_idx]]
		level_name_label.add_theme_color_override("font_color", GameManager.DIFFICULTY_COLORS[diff_idx])

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
	_wave_num   = wave_number
	_wave_total = total_waves
	_enemies_alive = 0
	_enemies_total = 0
	# Hide the "Start Wave" button — it may still be visible if the wave auto-started
	_stop_wave_btn_pulse()
	next_wave_btn.hide()
	# Hide wave preview
	if _wave_preview_label != null:
		_wave_preview_label.modulate.a = 0.0
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

func _on_enemy_count_changed(alive: int, total: int) -> void:
	_enemies_alive = alive
	_enemies_total = total
	_refresh_wave_label()

func _refresh_wave_label() -> void:
	if _wave_num <= 0:
		return
	if _enemies_total > 0 and _enemies_alive > 0:
		wave_label.text = "波次 %d/%d  %d/%d" % [_wave_num, _wave_total, _enemies_alive, _enemies_total]
	else:
		wave_label.text = "波次: %d / %d" % [_wave_num, _wave_total]

## Build a small enemy-composition preview label shown between waves
func _build_wave_preview() -> void:
	_wave_preview_label = Label.new()
	_wave_preview_label.name = "WavePreviewLabel"
	_wave_preview_label.anchor_left   = 0.5
	_wave_preview_label.anchor_right  = 0.5
	_wave_preview_label.anchor_top    = 0.0
	_wave_preview_label.anchor_bottom = 0.0
	_wave_preview_label.offset_left   = -220.0
	_wave_preview_label.offset_right  = 220.0
	_wave_preview_label.offset_top    = 114.0
	_wave_preview_label.offset_bottom = 136.0
	_wave_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_preview_label.add_theme_font_size_override("font_size", 13)
	_wave_preview_label.add_theme_color_override("font_color", Color(0.75, 0.90, 1.00))
	_wave_preview_label.modulate.a = 0.0
	add_child(_wave_preview_label)

## Build the Boss HP bar panel (hidden until a boss spawns).
func _build_boss_bar() -> void:
	_boss_bar_root = Control.new()
	_boss_bar_root.anchor_left   = 0.5
	_boss_bar_root.anchor_right  = 0.5
	_boss_bar_root.anchor_top    = 0.0
	_boss_bar_root.anchor_bottom = 0.0
	_boss_bar_root.offset_left   = -BOSS_BAR_W * 0.5
	_boss_bar_root.offset_right  = BOSS_BAR_W * 0.5
	_boss_bar_root.offset_top    = 62.0   ## just below the 56px TopBar
	_boss_bar_root.offset_bottom = 62.0 + BOSS_BAR_H + 18.0
	_boss_bar_root.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	# Background track
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.08, 0.08, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boss_bar_root.add_child(bg)

	# Red fill bar
	_boss_bar_fill = ColorRect.new()
	_boss_bar_fill.color = Color(0.85, 0.15, 0.15)
	_boss_bar_fill.position = Vector2(2.0, 2.0)
	_boss_bar_fill.size = Vector2(BOSS_BAR_W - 4.0, BOSS_BAR_H - 4.0)
	_boss_bar_root.add_child(_boss_bar_fill)

	# Label "💀 BOSS"
	_boss_bar_label = Label.new()
	_boss_bar_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boss_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_boss_bar_label.add_theme_font_size_override("font_size", 12)
	_boss_bar_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	_boss_bar_label.text = "BOSS"
	_boss_bar_root.add_child(_boss_bar_label)

	_boss_bar_root.hide()
	add_child(_boss_bar_root)

	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)

func _on_boss_spawned(boss: Node) -> void:
	if _boss_bar_root == null:
		return
	_boss_max_hp = boss._max_health if "_max_health" in boss else 1.0
	if _boss_bar_fill != null:
		_boss_bar_fill.size.x = BOSS_BAR_W - 4.0
	if _boss_bar_label != null:
		_boss_bar_label.text = "BOSS"
	_boss_bar_root.show()

func _on_boss_health_changed(current_hp: float, max_hp: float) -> void:
	if _boss_bar_fill == null or _boss_bar_root == null:
		return
	var pct := clampf(current_hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var target_w := (BOSS_BAR_W - 4.0) * pct
	var t := create_tween()
	t.tween_property(_boss_bar_fill, "size:x", target_w, 0.1)
	# Color shifts: green > 60%, amber 30-60%, red < 30%
	var bar_color: Color
	if pct > 0.6:
		bar_color = Color(0.25, 0.80, 0.25)
	elif pct > 0.3:
		bar_color = Color(0.85, 0.55, 0.10)
	else:
		bar_color = Color(1.0, 0.20, 0.20)
	_boss_bar_fill.color = bar_color
	if _boss_bar_label != null:
		_boss_bar_label.text = "BOSS  %.0f%%" % (pct * 100.0)
	if pct <= 0.0:
		# Hide bar 1.5 s after boss dies
		get_tree().create_timer(1.5, true, false, true).timeout.connect(
			func() -> void:
				if _boss_bar_root != null:
					_boss_bar_root.hide()
		)

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
			# Show next queued message if any.
			if not _message_queue.is_empty():
				_show_message_now(_message_queue.pop_front())

## Wave completion gold bonus notification.
func _on_wave_bonus_awarded(amount: int) -> void:
	show_message("波次完成！ +%d 金" % amount)

## Show a brief floating message (e.g. "Not enough gold!").
## If a message is already displaying, the new one is queued instead of
## stomping the current message.
func show_message(text: String) -> void:
	if _message_timer > 0.0:
		# A message is already showing — queue this one (cap queue at 3).
		if _message_queue.size() < 3:
			_message_queue.append(text)
	else:
		_show_message_now(text)

func _show_message_now(text: String) -> void:
	message_label.text = text
	message_label.show()
	_message_timer = MESSAGE_DURATION

## Called by WaveManager.next_wave_ready signal
func on_next_wave_ready(wave_number: int, total_waves: int) -> void:
	_wave_num   = wave_number
	_wave_total = total_waves
	_enemies_alive = 0
	_enemies_total = 0
	wave_label.text = "波次: %d / %d" % [_wave_num, _wave_total]
	next_wave_btn.text = "開始波次 %d ▶" % wave_number
	next_wave_btn.show()
	_start_wave_btn_pulse()
	# Show enemy composition preview for the upcoming wave
	var wm: Node = get_tree().get_first_node_in_group("wave_manager")
	if wm != null and wm.has_method("get_wave_preview_string") and _wave_preview_label != null:
		var preview: String = wm.get_wave_preview_string(wave_number - 1)
		if preview.length() > 0:
			_wave_preview_label.text = "下一波：" + preview
			_wave_preview_label.modulate.a = 0.85

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
	lives_label.text = "命 %d" % new_lives
	if new_lives <= DANGER_LIVES and new_lives > 0:
		_start_vignette_pulse()
	else:
		_stop_vignette_pulse()

var _prev_gold: int = -1
var _gold_tween: Tween = null
func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "金 %d" % new_gold
	# Brief scale-pulse when gold is spent (decreases)
	if _prev_gold > 0 and new_gold < _prev_gold:
		if _gold_tween != null and _gold_tween.is_valid():
			_gold_tween.kill()
			gold_label.scale = Vector2(1.0, 1.0)
		_gold_tween = create_tween()
		_gold_tween.tween_property(gold_label, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_BACK)
		_gold_tween.tween_property(gold_label, "scale", Vector2(1.0,  1.0),  0.12).set_trans(Tween.TRANS_BACK)
	_prev_gold = new_gold

func _on_score_changed(new_score: int) -> void:
	score_label.text = "分 %d" % new_score

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
