## TowerPanel — displays available towers and costs for purchase.
## Player clicks a tower card to enter placement mode.
class_name TowerPanel
extends Control

## These should match the TowerData resources exactly
const TOWER_RESOURCES := [
	"res://data/towers/arrow_tower.tres",
	"res://data/towers/cannon_tower.tres",
	"res://data/towers/ice_tower.tres",
	"res://data/towers/lightning_tower.tres",
	"res://data/towers/sniper_tower.tres",
]

## Maps scene filename (without extension) to its Kenney base-sprite path
const TOWER_PREVIEWS: Dictionary = {
	"ArrowTower":     "res://assets/kenney_tower-defense-kit/Previews/tower-round-base.png",
	"CannonTower":    "res://assets/kenney_tower-defense-kit/Previews/tower-square-bottom-a.png",
	"IceTower":       "res://assets/kenney_tower-defense-kit/Previews/tower-round-crystals.png",
	"LightningTower": "res://assets/kenney_tower-defense-kit/Previews/tower-round-top-b.png",
	"SniperTower":    "res://assets/kenney_tower-defense-kit/Previews/tower-square-bottom-b.png",
}

@onready var tower_buttons_container: VBoxContainer = $VBoxContainer/TowerButtonsContainer

## Reference to GameWorld for triggering placement
var game_world: Node = null

func _ready() -> void:
	_build_tower_buttons()
	EventBus.gold_changed.connect(_on_gold_changed)

func set_game_world(gw: Node) -> void:
	game_world = gw

## Dynamically create one card per tower type
func _build_tower_buttons() -> void:
	for path in TOWER_RESOURCES:
		var data: TowerData = load(path)
		if data == null:
			push_warning("TowerPanel: Could not load " + path)
			continue

		# Outer card — PanelContainer gives a recessed look
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(148.0, 62.0)
		card.set_meta("build_cost", data.build_cost)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left",   6)
		margin.add_theme_constant_override("margin_right",  6)
		margin.add_theme_constant_override("margin_top",    4)
		margin.add_theme_constant_override("margin_bottom", 4)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		# --- Thumbnail ---
		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(48.0, 48.0)
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var scene_key: String = data.scene_path.get_file().get_basename()
		if TOWER_PREVIEWS.has(scene_key) and ResourceLoader.exists(TOWER_PREVIEWS[scene_key]):
			thumb.texture = load(TOWER_PREVIEWS[scene_key])
		hbox.add_child(thumb)

		# --- Labels ---
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var name_label := Label.new()
		name_label.text = data.tower_name
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var cost_label := Label.new()
		cost_label.text = "💰 %d" % data.build_cost
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.modulate = Color(1.0, 0.88, 0.25)

		vbox.add_child(name_label)
		vbox.add_child(cost_label)
		hbox.add_child(vbox)

		margin.add_child(hbox)
		card.add_child(margin)

		# --- Invisible overlay Button for click + hover ---
		var btn := Button.new()
		btn.flat = true
		btn.anchor_right  = 1.0
		btn.anchor_bottom = 1.0
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = data.description
		card.add_child(btn)

		tower_buttons_container.add_child(card)

		# Capture data for closure
		var captured_data := data
		btn.pressed.connect(func() -> void: _on_tower_button_pressed(captured_data))

func _on_tower_button_pressed(data: TowerData) -> void:
	AudioManager.play_ui_click()
	if game_world != null and game_world.has_method("begin_tower_placement"):
		game_world.begin_tower_placement(data)

## Dim cards the player can't afford
func _on_gold_changed(new_gold: int) -> void:
	for card in tower_buttons_container.get_children():
		if card is PanelContainer and card.has_meta("build_cost"):
			var cost: int = card.get_meta("build_cost")
			card.modulate.a = 1.0 if new_gold >= cost else 0.45
