## TowerPanel — displays available towers and costs for purchase.
## Player clicks a tower card to enter placement mode.
class_name TowerPanel
extends Control

## These should match the TowerData resources exactly
const TOWER_RESOURCES := [
	"res://data/towers/arrow_tower.tres",
	"res://data/towers/cannon_tower.tres",
	"res://data/towers/ice_tower.tres",
]

@onready var tower_buttons_container: VBoxContainer = $TowerButtonsContainer

## Reference to GameWorld for triggering placement
var game_world: Node = null

func _ready() -> void:
	_build_tower_buttons()
	EventBus.gold_changed.connect(_on_gold_changed)

func set_game_world(gw: Node) -> void:
	game_world = gw

## Dynamically create one button per tower type
func _build_tower_buttons() -> void:
	for path in TOWER_RESOURCES:
		var data: TowerData = load(path)
		if data == null:
			push_warning("TowerPanel: Could not load " + path)
			continue
		var btn := Button.new()
		btn.text = "%s\n%d 💰" % [data.tower_name, data.build_cost]
		btn.custom_minimum_size = Vector2(120.0, 60.0)
		btn.tooltip_text = data.description
		tower_buttons_container.add_child(btn)
		# Capture data for closure
		var captured_data := data
		btn.pressed.connect(func() -> void: _on_tower_button_pressed(captured_data))

func _on_tower_button_pressed(data: TowerData) -> void:
	if game_world != null and game_world.has_method("begin_tower_placement"):
		game_world.begin_tower_placement(data)

## Dim buttons the player can't afford
func _on_gold_changed(new_gold: int) -> void:
	for child in tower_buttons_container.get_children():
		if child is Button:
			# Try to parse the cost from button text (second line)
			var lines := (child as Button).text.split("\n")
			if lines.size() >= 2:
				var cost_str := lines[1].replace(" 💰", "").strip_edges()
				if cost_str.is_valid_int():
					child.modulate.a = 1.0 if new_gold >= int(cost_str) else 0.5
