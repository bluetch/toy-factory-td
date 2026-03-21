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
var _msg_tween: Tween = null

## Dynamically-created wave announcement banner
var _wave_banner: Label = null
var _banner_tween: Tween = null
## Wave composition preview container (shown between waves) — holds sprite chips.
var _wave_preview_container: Control = null

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
	EventBus.kill_combo_awarded.connect(_on_kill_combo_awarded)

	_build_wave_banner()
	_build_wave_preview()
	_build_vignette()
	_build_boss_bar()
	_build_skill_button()

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
	if _wave_preview_container != null:
		_wave_preview_container.modulate.a = 0.0
	if _wave_banner == null:
		return
	var is_final := (wave_number == total_waves)
	if is_final:
		_wave_banner.text = "⚠ 最終波次 %d / %d ⚠" % [wave_number, total_waves]
		_wave_banner.add_theme_color_override("font_color", Color(1.0, 0.40, 0.25))
	else:
		_wave_banner.text = "— 波次 %d / %d —" % [wave_number, total_waves]
		_wave_banner.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	_wave_banner.pivot_offset = Vector2(200.0, 23.0)
	_wave_banner.scale = Vector2(0.6, 0.6)
	_wave_banner.modulate.a = 0.0
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_wave_banner, "modulate:a", 1.0, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(_wave_banner, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(2.2)
	_banner_tween.chain().set_parallel(true)
	_banner_tween.tween_property(_wave_banner, "modulate:a", 0.0, 0.40)
	_banner_tween.tween_property(_wave_banner, "scale", Vector2(1.1, 1.1), 0.40)

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

## Build the enemy-composition preview bar shown between waves.
## Displays actual enemy sprite thumbnails + counts instead of emoji text.
func _build_wave_preview() -> void:
	## Outer container anchored to top-center
	_wave_preview_container = Control.new()
	_wave_preview_container.name = "WavePreviewContainer"
	_wave_preview_container.anchor_left   = 0.5
	_wave_preview_container.anchor_right  = 0.5
	_wave_preview_container.anchor_top    = 0.0
	_wave_preview_container.anchor_bottom = 0.0
	_wave_preview_container.offset_left   = -260.0
	_wave_preview_container.offset_right  = 260.0
	_wave_preview_container.offset_top    = 108.0
	_wave_preview_container.offset_bottom = 142.0
	_wave_preview_container.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_wave_preview_container.modulate.a    = 0.0
	add_child(_wave_preview_container)

## Populate the wave-preview container with sprite chips for each enemy type.
## chips = [{ enemy_id, count, sprite_path, color }, ...]
func _build_wave_preview_chips(chips: Array) -> void:
	if _wave_preview_container == null or chips.is_empty():
		return
	# Clear previous chips
	for ch in _wave_preview_container.get_children():
		ch.queue_free()

	## Inner HBox — centred inside the Control via anchors
	var hbox := HBoxContainer.new()
	hbox.anchor_left   = 0.5
	hbox.anchor_right  = 0.5
	hbox.anchor_top    = 0.5
	hbox.anchor_bottom = 0.5
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	hbox.add_theme_constant_override("separation", 12)
	_wave_preview_container.add_child(hbox)

	## "下一波：" prefix
	var prefix := Label.new()
	prefix.text = "下一波："
	prefix.add_theme_font_size_override("font_size", 12)
	prefix.add_theme_color_override("font_color", Color(0.68, 0.82, 1.00, 0.90))
	prefix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(prefix)

	for entry in chips:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 4)

		## Enemy sprite thumbnail (28×28)
		var sp: String = entry.get("sprite_path", "")
		if sp != "" and ResourceLoader.exists(sp):
			var img := TextureRect.new()
			img.texture = load(sp)
			img.custom_minimum_size = Vector2(28, 28)
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			img.modulate     = entry.get("color", Color.WHITE)
			chip.add_child(img)

		## ×N count label, tinted to match the enemy
		var cnt := Label.new()
		cnt.text = "×%d" % entry.get("count", 0)
		cnt.add_theme_font_size_override("font_size", 13)
		cnt.add_theme_color_override("font_color", entry.get("color", Color(0.9, 0.9, 0.9)))
		cnt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.add_child(cnt)

		hbox.add_child(chip)

	_wave_preview_container.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_wave_preview_container, "modulate:a", 0.92, 0.35) \
		.set_trans(Tween.TRANS_SINE)


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
	_boss_bar_root.modulate.a = 0.0
	_boss_bar_root.show()
	var tw := create_tween()
	tw.tween_property(_boss_bar_root, "modulate:a", 1.0, 0.35) \
		.set_trans(Tween.TRANS_SINE)

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
			_message_timer = 0.0
			_fadeout_message()

## Wave completion gold bonus notification.
func _on_wave_bonus_awarded(amount: int) -> void:
	show_message("波次完成！ +%d 金" % amount)

## Kill-streak combo bonus notification.
func _on_kill_combo_awarded(amount: int) -> void:
	show_message("⚡ 連擊！ +%d 金" % amount)

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
	message_label.modulate.a = 0.0
	message_label.show()
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_property(message_label, "modulate:a", 1.0, 0.18)
	_message_timer = MESSAGE_DURATION

func _fadeout_message() -> void:
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_property(message_label, "modulate:a", 0.0, 0.25)
	_msg_tween.tween_callback(func() -> void:
		message_label.hide()
		if not _message_queue.is_empty():
			_show_message_now(_message_queue.pop_front())
	)

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
	# Rebuild the visual wave preview with actual enemy sprite thumbnails
	var wm: Node = get_tree().get_first_node_in_group("wave_manager")
	if wm != null and wm.has_method("get_wave_preview_entries") and _wave_preview_container != null:
		_build_wave_preview_chips(wm.get_wave_preview_entries(wave_number - 1))

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

var _prev_lives: int = -1
var _lives_tween: Tween = null
func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "❤ %d" % new_lives
	## Shake + red flash when a life is lost
	if _prev_lives > 0 and new_lives < _prev_lives:
		if _lives_tween != null and _lives_tween.is_valid():
			_lives_tween.kill()
		lives_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		_lives_tween = create_tween()
		## Quick lateral shake: left-right-left-center
		var orig_x := lives_label.position.x
		_lives_tween.tween_property(lives_label, "position:x", orig_x - 5.0, 0.04)
		_lives_tween.tween_property(lives_label, "position:x", orig_x + 5.0, 0.05)
		_lives_tween.tween_property(lives_label, "position:x", orig_x - 3.0, 0.04)
		_lives_tween.tween_property(lives_label, "position:x", orig_x,       0.04)
		_lives_tween.tween_property(lives_label, "scale", Vector2(1.3, 1.3), 0.06) \
			.set_trans(Tween.TRANS_BACK)
		_lives_tween.tween_property(lives_label, "scale", Vector2.ONE, 0.14)
		_lives_tween.tween_callback(func() -> void:
			lives_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		)
	_prev_lives = new_lives
	if new_lives <= DANGER_LIVES and new_lives > 0:
		_start_vignette_pulse()
	else:
		_stop_vignette_pulse()

var _prev_gold: int = -1
var _gold_tween: Tween = null
func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "💰 %d" % new_gold
	if _prev_gold >= 0 and new_gold != _prev_gold:
		if _gold_tween != null and _gold_tween.is_valid():
			_gold_tween.kill()
			gold_label.scale = Vector2.ONE
		_gold_tween = create_tween()
		if new_gold < _prev_gold:
			## Spend: orange pulse
			gold_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
			_gold_tween.tween_property(gold_label, "scale", Vector2(1.22, 1.22), 0.07) \
				.set_trans(Tween.TRANS_BACK)
			_gold_tween.tween_property(gold_label, "scale", Vector2.ONE, 0.12)
		else:
			## Gain: green flash
			gold_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45))
			_gold_tween.tween_property(gold_label, "scale", Vector2(1.15, 1.15), 0.06) \
				.set_trans(Tween.TRANS_BACK)
			_gold_tween.tween_property(gold_label, "scale", Vector2.ONE, 0.10)
		_gold_tween.tween_callback(func() -> void:
			gold_label.add_theme_color_override("font_color", Color(0.97, 0.84, 0.38))
		)
	_prev_gold = new_gold

var _prev_score: int  = -1
var _score_tween: Tween = null
func _on_score_changed(new_score: int) -> void:
	score_label.text = "⭐ %d" % new_score
	if _prev_score >= 0 and new_score > _prev_score:
		if _score_tween != null and _score_tween.is_valid():
			_score_tween.kill()
			score_label.scale = Vector2.ONE
		_score_tween = create_tween()
		score_label.add_theme_color_override("font_color", Color(0.60, 1.00, 0.70))
		_score_tween.tween_property(score_label, "scale", Vector2(1.20, 1.20), 0.07) \
			.set_trans(Tween.TRANS_BACK)
		_score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.12)
		_score_tween.tween_callback(func() -> void:
			score_label.add_theme_color_override("font_color", Color(0.78, 0.90, 1.00))
		)
	_prev_score = new_score

func _on_speed_changed(new_speed: float) -> void:
	speed_button.text = "%.0f×" % new_speed
	## Tint: white=1×, amber=2×, hot-orange=3×
	if new_speed >= 3.0:
		speed_button.add_theme_color_override("font_color", Color(1.0, 0.50, 0.18))
	elif new_speed >= 2.0:
		speed_button.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	else:
		speed_button.remove_theme_color_override("font_color")

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


## ── Skill button (bottom-left of screen) ────────────────────────────────────

var _skill_panel: PanelContainer = null

func _build_skill_button() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.18, 0.90)
	style.set_border_width_all(1)
	style.border_color = Color(0.55, 0.40, 0.85, 0.75)
	style.set_corner_radius_all(6)

	var btn := Button.new()
	btn.text = "⚡ 技能"
	btn.flat = false
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.80, 0.70, 1.0, 0.90))
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.anchor_left   = 0.0;  btn.anchor_right  = 0.0
	btn.anchor_top    = 1.0;  btn.anchor_bottom = 1.0
	btn.offset_left   = 54.0;  btn.offset_right  = 130.0
	btn.offset_top    = -38.0; btn.offset_bottom = -10.0
	add_child(btn)
	btn.pressed.connect(_on_skill_btn_pressed)


func _on_skill_btn_pressed() -> void:
	AudioManager.play_ui_click()
	if is_instance_valid(_skill_panel):
		_skill_panel.queue_free()
		_skill_panel = null
		return
	_build_skill_panel()


func _build_skill_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.16, 0.96)
	style.set_border_width_all(1)
	style.border_color = Color(0.55, 0.40, 0.85, 0.80)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.50)
	style.shadow_size  = 6

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left   = 0.0;  panel.anchor_right  = 0.0
	panel.anchor_top    = 1.0;  panel.anchor_bottom = 1.0
	panel.offset_left   = 54.0;  panel.offset_right  = 310.0
	panel.offset_top    = -220.0; panel.offset_bottom = -44.0
	panel.modulate.a = 0.0
	panel.offset_top += 18.0
	add_child(panel)
	_skill_panel = panel
	var _enter_tw := panel.create_tween()
	_enter_tw.set_parallel(true)
	_enter_tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	_enter_tw.tween_property(panel, "offset_top", panel.offset_top - 18.0, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "當前技能"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.60, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", Color(0.55, 0.40, 0.85, 0.40))
	vbox.add_child(sep)

	var RARITY_COLORS_LOCAL: Array[Color] = [
		Color(0.62, 0.65, 0.70, 1.0),
		Color(0.28, 0.55, 1.00, 1.0),
		Color(0.80, 0.35, 1.00, 1.0),
	]
	var has_any := false
	for s: SkillData in SkillManager._pool:
		var n := SkillManager.get_skill_stack(s.skill_id)
		if n == 0:
			continue
		has_any = true
		var rc := RARITY_COLORS_LOCAL[s.rarity]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon_l := Label.new()
		icon_l.text = s.icon
		icon_l.add_theme_font_size_override("font_size", 16)
		row.add_child(icon_l)
		var info_l := Label.new()
		info_l.text = "%s ×%d" % [s.skill_name, n]
		info_l.add_theme_font_size_override("font_size", 12)
		info_l.add_theme_color_override("font_color", rc)
		info_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_l)
		vbox.add_child(row)

	if not has_any:
		var empty := Label.new()
		empty.text = "尚未選擇任何技能"
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.75))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty)
