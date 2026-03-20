## TowerPanel — displays available towers and costs for purchase.
## Each tower card uses a single pre-assembled Kenney "build" image as its icon
## (no compositing). The build images already show a complete, unified tower.
class_name TowerPanel
extends Control

const TOWER_RESOURCES := [
	"res://data/towers/arrow_tower.tres",
	"res://data/towers/cannon_tower.tres",
	"res://data/towers/ice_tower.tres",
	"res://data/towers/lightning_tower.tres",
	"res://data/towers/sniper_tower.tres",
]

const _K := "res://assets/kenney_tower-defense-kit/Previews/"

## One pre-assembled image per tower — already a complete, unified tower silhouette.
## Chosen to be visually distinct (round vs square, different heights/shapes).
const TOWER_ICON: Dictionary = {
	"ArrowTower":     _K + "tower-round-build-b.png",   ## round, mid-height, red base
	"CannonTower":    _K + "tower-square-build-d.png",   ## square, pointed purple roof
	"IceTower":       _K + "tower-round-build-c.png",    ## round, wide dark base
	"LightningTower": _K + "tower-round-build-d.png",    ## round, flame on top
	"SniperTower":    _K + "tower-square-build-e.png",   ## square, tall blue/purple
}

const ICON_SIZE : int = 64   ## display size for the tower icon

@onready var tower_buttons_container: VBoxContainer = $VBoxContainer/TowerButtonsContainer
var game_world: Node = null

func _ready() -> void:
	_build_tower_buttons()
	EventBus.gold_changed.connect(_on_gold_changed)

func set_game_world(gw: Node) -> void:
	game_world = gw

func _build_tower_buttons() -> void:
	for path in TOWER_RESOURCES:
		var data: TowerData = load(path)
		if data == null:
			push_warning("TowerPanel: Could not load " + path)
			continue

		var scene_key: String = data.scene_path.get_file().get_basename()
		var icon_path: String = TOWER_ICON.get(scene_key, "")
		var icon_tex: Texture2D = null
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon_tex = load(icon_path) as Texture2D

		# --- Card ---
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.07, 0.12, 0.26, 0.92)
		card_style.set_border_width_all(2)
		card_style.border_color = Color(0.55, 0.43, 0.18, 0.80)
		card_style.set_corner_radius_all(5)
		card_style.set_content_margin_all(0.0)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(148.0, float(ICON_SIZE) + 10.0)
		card.add_theme_stylebox_override("panel", card_style)
		card.set_meta("build_cost", data.build_cost)
		card.set_meta("card_style", card_style)
		card.set_meta("base_cost_text", "%d 金" % data.build_cost)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left",   6)
		margin.add_theme_constant_override("margin_right",  6)
		margin.add_theme_constant_override("margin_top",    4)
		margin.add_theme_constant_override("margin_bottom", 4)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		# --- Icon ---
		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(float(ICON_SIZE), float(ICON_SIZE))
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		thumb.texture = icon_tex
		hbox.add_child(thumb)

		# --- Labels ---
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var name_label := Label.new()
		name_label.text = data.tower_name
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.72, 1.0))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var cost_label := Label.new()
		cost_label.text = "%d 金" % data.build_cost
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color", Color(0.97, 0.84, 0.38, 1.0))

		vbox.add_child(name_label)
		vbox.add_child(cost_label)
		hbox.add_child(vbox)
		card.set_meta("cost_label", cost_label)

		margin.add_child(hbox)
		card.add_child(margin)

		# --- Hotkey badge ---
		var hotkey_idx := TOWER_RESOURCES.find(path)
		if hotkey_idx >= 0:
			var badge := Label.new()
			badge.text = str(hotkey_idx + 1)
			badge.add_theme_font_size_override("font_size", 10)
			badge.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70, 0.85))
			badge.position = Vector2(5.0, 3.0)
			card.add_child(badge)

		# --- Invisible click button ---
		var btn := Button.new()
		btn.flat = true
		btn.anchor_right  = 1.0
		btn.anchor_bottom = 1.0
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = data.description
		card.add_child(btn)

		tower_buttons_container.add_child(card)

		var captured_data := data
		btn.pressed.connect(func() -> void: _on_tower_button_pressed(captured_data))

func _on_tower_button_pressed(data: TowerData) -> void:
	if not GameManager.can_afford(data.build_cost):
		AudioManager.play_invalid_placement()
		return
	AudioManager.play_ui_click()
	if game_world != null and game_world.has_method("begin_tower_placement"):
		game_world.begin_tower_placement(data)

func _on_gold_changed(new_gold: int) -> void:
	for card in tower_buttons_container.get_children():
		if card is PanelContainer and card.has_meta("build_cost"):
			var cost: int = card.get_meta("build_cost")
			var can: bool = new_gold >= cost
			card.modulate.a = 1.0 if can else 0.55
			if card.has_meta("card_style"):
				var st: StyleBoxFlat = card.get_meta("card_style")
				st.border_color = Color(0.72, 0.58, 0.22, 0.95) if can \
						else Color(0.35, 0.28, 0.12, 0.55)
			if card.has_meta("cost_label"):
				var lbl: Label = card.get_meta("cost_label")
				if can:
					lbl.text = card.get_meta("base_cost_text")
					lbl.add_theme_color_override("font_color", Color(0.97, 0.84, 0.38, 1.0))
				else:
					lbl.text = "差 %d 金" % (cost - new_gold)
					lbl.add_theme_color_override("font_color", Color(1.0, 0.40, 0.35, 1.0))
