## UpgradePanel — shown when a placed tower is selected.
## Displays stats, upgrade cost, and sell value.
class_name UpgradePanel
extends Control

@onready var tower_name_label:  Label  = $VBoxContainer/TowerNameLabel
@onready var level_label:       Label  = $VBoxContainer/LevelLabel
@onready var stats_label:       Label  = $VBoxContainer/StatsLabel
@onready var upgrade_button:    Button = $VBoxContainer/UpgradeButton
@onready var sell_button:       Button = $VBoxContainer/SellButton

var _current_tower: Node = null

## Dynamically-created label showing next-level stat preview
var _next_stats_label: Label = null

## Two-step sell confirmation state
var _sell_confirm: bool = false
var _sell_confirm_timer: float = 0.0
const SELL_CONFIRM_TIMEOUT := 2.5

func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	EventBus.gold_changed.connect(_on_gold_changed)
	# Close button — top-right corner of the panel
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 0.85))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.4, 0.35, 1.0))
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.anchor_left   = 1.0
	close_btn.anchor_top    = 0.0
	close_btn.anchor_right  = 1.0
	close_btn.anchor_bottom = 0.0
	close_btn.offset_left   = -26.0
	close_btn.offset_top    = 2.0
	close_btn.offset_right  = -2.0
	close_btn.offset_bottom = 26.0
	add_child(close_btn)
	close_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		EventBus.tower_deselected.emit()
		hide()
	)
	# Build next-level preview label dynamically (avoids scene changes)
	_next_stats_label = Label.new()
	_next_stats_label.add_theme_font_size_override("font_size", 11)
	_next_stats_label.add_theme_color_override("font_color", Color(0.50, 0.95, 0.50))
	_next_stats_label.visible = false
	$VBoxContainer.add_child(_next_stats_label)
	$VBoxContainer.move_child(_next_stats_label, stats_label.get_index() + 1)

func _process(delta: float) -> void:
	if _sell_confirm:
		_sell_confirm_timer -= delta
		if _sell_confirm_timer <= 0.0:
			_sell_confirm = false
			_reset_sell_button()
		else:
			# Show remaining seconds so the player knows the window is closing
			var sell_val: int = _current_tower.get_sell_value() \
				if (is_instance_valid(_current_tower) and _current_tower.has_method("get_sell_value")) else 0
			sell_button.text = "確認出售  +%d 金  (%d)" % [sell_val, int(ceil(_sell_confirm_timer))]

## Populate fields from a BaseTower node
func populate(tower: Node) -> void:
	_current_tower = tower
	var data: TowerData = tower.tower_data if "tower_data" in tower else null
	if data == null:
		return

	tower_name_label.text = data.tower_name
	var lvl: int = tower.current_level if "current_level" in tower else 0
	var max_lvl: int = data.upgrades.size()
	level_label.text = "等級：%d / %d" % [lvl + 1, max_lvl + 1]

	var cur_dmg  := data.get_damage(lvl)
	var cur_spd  := data.get_attack_speed(lvl)
	var cur_rng  := data.get_range(lvl)
	var cur_text := "傷害：%.0f  速度：%.1f/s  射程：%.0f" % [cur_dmg, cur_spd, cur_rng]
	# Show slow stats for ice-type towers
	if data.slow_factor < 1.0:
		var pct := (1.0 - data.get_slow_factor(lvl)) * 100.0
		var dur := data.get_slow_duration(lvl)
		cur_text += "  減速：%.0f%% %.1fs" % [pct, dur]
	# Show chain count for lightning tower
	if data.base_chain_count > 0:
		cur_text += "  跳數：%d" % data.get_chain_count(lvl)
	# Show splash radius for cannon tower
	if data.splash_radius > 0.0:
		cur_text += "  爆炸：%.0fpx" % data.get_splash_radius(lvl)
	stats_label.text = cur_text

	var can_upgrade: bool = tower.has_method("can_upgrade") and tower.can_upgrade()
	var upgrade_cost: int = tower.get_upgrade_cost() if tower.has_method("get_upgrade_cost") else 0
	upgrade_button.visible = can_upgrade

	# Next-level stats preview
	if _next_stats_label != null:
		if can_upgrade:
			var next_lvl := lvl + 1
			var nxt_text := "升後：%.0f傷  %.1f/s  %.0f射" % [
				data.get_damage(next_lvl),
				data.get_attack_speed(next_lvl),
				data.get_range(next_lvl)
			]
			if data.slow_factor < 1.0:
				var n_pct := (1.0 - data.get_slow_factor(next_lvl)) * 100.0
				var n_dur := data.get_slow_duration(next_lvl)
				nxt_text += "  減速：%.0f%% %.1fs" % [n_pct, n_dur]
			if data.base_chain_count > 0:
				nxt_text += "  跳數：%d" % data.get_chain_count(next_lvl)
			if data.splash_radius > 0.0:
				nxt_text += "  爆炸：%.0fpx" % data.get_splash_radius(next_lvl)
			_next_stats_label.text = nxt_text
			_next_stats_label.visible = true
		else:
			_next_stats_label.visible = false

	if can_upgrade:
		var affordable: bool = GameManager.can_afford(upgrade_cost)
		upgrade_button.text = "升級  %d 金" % upgrade_cost
		upgrade_button.disabled = not affordable
		var cost_color := Color(0.45, 0.90, 0.45) if affordable else Color(1.0, 0.40, 0.35)
		upgrade_button.add_theme_color_override("font_color",          cost_color)
		upgrade_button.add_theme_color_override("font_disabled_color", cost_color)

	var sell_val: int = tower.get_sell_value() if tower.has_method("get_sell_value") else 0
	sell_button.text = "出售  +%d 金" % sell_val
	sell_button.remove_theme_color_override("font_color")
	_sell_confirm = false

func _on_upgrade_pressed() -> void:
	if not is_instance_valid(_current_tower):
		return
	var upgrade_cost: int = _current_tower.get_upgrade_cost() if _current_tower.has_method("get_upgrade_cost") else 0
	if not GameManager.can_afford(upgrade_cost):
		AudioManager.play_invalid_placement()
		return
	AudioManager.play_ui_click()
	var gw: Node = get_tree().get_first_node_in_group("game_world")
	if gw and gw.has_method("upgrade_selected_tower"):
		gw.upgrade_selected_tower()
	# Refresh display
	if _current_tower and is_instance_valid(_current_tower):
		populate(_current_tower)
	else:
		hide()

func _on_sell_pressed() -> void:
	if not _sell_confirm:
		# First press: arm the confirmation
		_sell_confirm = true
		_sell_confirm_timer = SELL_CONFIRM_TIMEOUT
		var sell_val: int = _current_tower.get_sell_value() if (is_instance_valid(_current_tower) and _current_tower.has_method("get_sell_value")) else 0
		sell_button.text = "確認出售  +%d 金" % sell_val
		sell_button.add_theme_color_override("font_color", Color(1.0, 0.55, 0.10))
		AudioManager.play_ui_click()
		return
	# Second press within timeout: execute sell
	_sell_confirm = false
	AudioManager.play_ui_click()
	var gw: Node = get_tree().get_first_node_in_group("game_world")
	if gw and gw.has_method("sell_selected_tower"):
		gw.sell_selected_tower()
	hide()

func _reset_sell_button() -> void:
	if _current_tower == null or not is_instance_valid(_current_tower):
		return
	var sell_val: int = _current_tower.get_sell_value() if _current_tower.has_method("get_sell_value") else 0
	sell_button.text = "出售  +%d 金" % sell_val
	sell_button.remove_theme_color_override("font_color")

## Refresh upgrade button affordability whenever gold changes.
func _on_gold_changed(_new_gold: int) -> void:
	if not visible or _current_tower == null or not is_instance_valid(_current_tower):
		return
	if not _current_tower.has_method("can_upgrade") or not _current_tower.can_upgrade():
		return
	var upgrade_cost: int = _current_tower.get_upgrade_cost() if _current_tower.has_method("get_upgrade_cost") else 0
	var affordable: bool = GameManager.can_afford(upgrade_cost)
	upgrade_button.disabled = not affordable
	var cost_color := Color(0.45, 0.90, 0.45) if affordable else Color(1.0, 0.40, 0.35)
	upgrade_button.add_theme_color_override("font_color",          cost_color)
	upgrade_button.add_theme_color_override("font_disabled_color", cost_color)
