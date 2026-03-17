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

func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

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

	stats_label.text = "傷害：%.0f  速度：%.1f/s  射程：%.0f" % [
		data.get_damage(lvl),
		data.get_attack_speed(lvl),
		data.get_range(lvl)
	]

	var can_upgrade: bool = tower.has_method("can_upgrade") and tower.can_upgrade()
	var upgrade_cost: int = tower.get_upgrade_cost() if tower.has_method("get_upgrade_cost") else 0
	upgrade_button.visible = can_upgrade
	if can_upgrade:
		var affordable: bool = GameManager.can_afford(upgrade_cost)
		upgrade_button.text = "升級\n%d 💰" % upgrade_cost
		upgrade_button.disabled = not affordable
		var cost_color := Color(0.45, 0.90, 0.45) if affordable else Color(1.0, 0.40, 0.35)
		upgrade_button.add_theme_color_override("font_color",          cost_color)
		upgrade_button.add_theme_color_override("font_disabled_color", cost_color)

	var sell_val: int = tower.get_sell_value() if tower.has_method("get_sell_value") else 0
	sell_button.text = "出售\n+%d 💰" % sell_val

func _on_upgrade_pressed() -> void:
	if _current_tower == null:
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
	AudioManager.play_ui_click()
	var gw: Node = get_tree().get_first_node_in_group("game_world")
	if gw and gw.has_method("sell_selected_tower"):
		gw.sell_selected_tower()
	hide()
