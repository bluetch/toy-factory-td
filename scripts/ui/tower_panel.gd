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

## Base platform sprite per tower — matches the in-game Body sprite.
const TOWER_BASE_ICON: Dictionary = {
	"ArrowTower":     _K + "tower-round-base.png",
	"CannonTower":    _K + "tower-square-bottom-a.png",
	"IceTower":       _K + "tower-round-base.png",
	"LightningTower": _K + "tower-round-base.png",
	"SniperTower":    _K + "tower-square-bottom-a.png",
}

## Weapon overlay sprite per tower — matches the Turret/Weapon sprite.
const TOWER_WEAPON_ICON: Dictionary = {
	"ArrowTower":     _K + "weapon-ballista.png",
	"CannonTower":    _K + "weapon-cannon.png",
	"IceTower":       _K + "tower-round-crystals.png",
	"LightningTower": _K + "tower-round-crystals.png",
	"SniperTower":    _K + "weapon-turret.png",
}

## Body modulate — must match the Body Sprite2D modulate in each tower scene.
const TOWER_BODY_COLOR: Dictionary = {
	"ArrowTower":     Color(0.72, 1.00, 0.62, 1.0),
	"CannonTower":    Color(1.00, 0.72, 0.42, 1.0),
	"IceTower":       Color(0.55, 0.88, 1.00, 1.0),
	"LightningTower": Color(1.00, 0.92, 0.22, 1.0),
	"SniperTower":    Color(0.75, 0.48, 1.00, 1.0),
}

## Weapon modulate — must match the Weapon Sprite2D modulate in each tower scene.
const TOWER_WEAPON_COLOR: Dictionary = {
	"ArrowTower":     Color(0.60, 0.95, 0.50, 1.0),
	"CannonTower":    Color(1.00, 0.60, 0.25, 1.0),
	"IceTower":       Color(0.28, 0.80, 1.00, 1.0),
	"LightningTower": Color(0.85, 1.00, 0.22, 1.0),
	"SniperTower":    Color(0.68, 0.38, 1.00, 1.0),
}

## Role tag shown on each card (short Traditional Chinese label).
const TOWER_ROLE: Dictionary = {
	"ArrowTower":     "高速",
	"CannonTower":    "範圍",
	"IceTower":       "減速",
	"LightningTower": "鏈電",
	"SniperTower":    "穿甲",
}

## Accent colour per tower type — used for card border, bg tint, and UI highlights.
## Derived from the average of body+weapon colors for visual cohesion.
const TOWER_ACCENT: Dictionary = {
	"ArrowTower":     Color(0.30, 0.92, 0.44, 1.0),
	"CannonTower":    Color(1.00, 0.55, 0.20, 1.0),
	"IceTower":       Color(0.28, 0.82, 1.00, 1.0),
	"LightningTower": Color(1.00, 0.92, 0.18, 1.0),
	"SniperTower":    Color(0.72, 0.44, 1.00, 1.0),
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
		var base_tex: Texture2D  = null
		var weap_tex: Texture2D  = null
		var base_path: String = TOWER_BASE_ICON.get(scene_key, "")
		var weap_path: String = TOWER_WEAPON_ICON.get(scene_key, "")
		if base_path != "" and ResourceLoader.exists(base_path):
			base_tex = load(base_path) as Texture2D
		if weap_path != "" and ResourceLoader.exists(weap_path):
			weap_tex = load(weap_path) as Texture2D
		var accent: Color = TOWER_ACCENT.get(scene_key, Color(0.55, 0.43, 0.18, 1.0))

		# --- Card ---
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.06, 0.10, 0.22, 0.95)
		card_style.set_border_width_all(2)
		card_style.border_color = accent
		card_style.set_corner_radius_all(6)
		card_style.set_content_margin_all(0.0)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(148.0, float(ICON_SIZE) + 16.0)
		card.pivot_offset = Vector2(74.0, (float(ICON_SIZE) + 16.0) * 0.5)
		card.add_theme_stylebox_override("panel", card_style)
		var _eff := SkillManager.effective_build_cost(data.build_cost)
		card.set_meta("build_cost", _eff)
		card.set_meta("card_style", card_style)
		card.set_meta("base_cost_text", "%d 金" % _eff)
		card.set_meta("accent", accent)

		# Thin accent stripe at top of card
		var stripe := ColorRect.new()
		stripe.color = Color(accent.r, accent.g, accent.b, 0.55)
		stripe.custom_minimum_size = Vector2(0, 3)
		stripe.anchor_right = 1.0
		stripe.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var vbox_outer := VBoxContainer.new()
		vbox_outer.add_theme_constant_override("separation", 0)
		vbox_outer.add_child(stripe)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left",   6)
		margin.add_theme_constant_override("margin_right",  6)
		margin.add_theme_constant_override("margin_top",    4)
		margin.add_theme_constant_override("margin_bottom", 4)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		# --- Icon: tinted bg + composite base + weapon overlay ---
		var icon_bg_style := StyleBoxFlat.new()
		icon_bg_style.bg_color = Color(accent.r * 0.14, accent.g * 0.14, accent.b * 0.14, 0.96)
		icon_bg_style.set_corner_radius_all(6)
		icon_bg_style.set_border_width_all(1)
		icon_bg_style.border_color = Color(accent.r, accent.g, accent.b, 0.50)
		var icon_bg := PanelContainer.new()
		icon_bg.custom_minimum_size = Vector2(float(ICON_SIZE), float(ICON_SIZE))
		icon_bg.add_theme_stylebox_override("panel", icon_bg_style)

		## Base layer — exact modulate from the tower's Body Sprite2D in the scene
		var body_color: Color = TOWER_BODY_COLOR.get(scene_key, accent)
		var thumb_base := TextureRect.new()
		thumb_base.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb_base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb_base.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		thumb_base.texture  = base_tex
		thumb_base.modulate = body_color
		icon_bg.add_child(thumb_base)

		## Weapon overlay — exact modulate from the tower's Weapon Sprite2D in the scene
		var weap_color: Color = TOWER_WEAPON_COLOR.get(scene_key, accent.lightened(0.20))
		var thumb_weap := TextureRect.new()
		thumb_weap.anchor_left   = 0.08
		thumb_weap.anchor_right  = 0.92
		thumb_weap.anchor_top    = 0.0
		thumb_weap.anchor_bottom = 0.70
		thumb_weap.grow_horizontal = Control.GROW_DIRECTION_BOTH
		thumb_weap.grow_vertical   = Control.GROW_DIRECTION_BOTH
		thumb_weap.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb_weap.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		thumb_weap.texture  = weap_tex
		thumb_weap.modulate = weap_color
		icon_bg.add_child(thumb_weap)

		hbox.add_child(icon_bg)

		# --- Labels ---
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		## Top row: tower name + role tag
		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 4)

		var name_label := Label.new()
		name_label.text = data.tower_name
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", accent.lightened(0.35))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		## Role tag pill (e.g. "範圍", "減速")
		var role_style := StyleBoxFlat.new()
		role_style.bg_color = Color(accent.r * 0.30, accent.g * 0.30, accent.b * 0.30, 0.90)
		role_style.set_corner_radius_all(3)
		role_style.set_content_margin_all(2.0)
		var role_panel := PanelContainer.new()
		role_panel.add_theme_stylebox_override("panel", role_style)
		var role_lbl := Label.new()
		role_lbl.text = TOWER_ROLE.get(scene_key, "")
		role_lbl.add_theme_font_size_override("font_size", 9)
		role_lbl.add_theme_color_override("font_color", accent.lightened(0.50))
		role_panel.add_child(role_lbl)

		top_row.add_child(name_label)
		top_row.add_child(role_panel)

		var cost_label := Label.new()
		cost_label.text = card.get_meta("base_cost_text")
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color", Color(0.97, 0.84, 0.38, 1.0))

		var tid := scene_key
		var eff_dmg  := data.base_damage       * SkillManager.get_damage_mult(tid)
		var eff_spd  := data.base_attack_speed * SkillManager.get_speed_mult(tid)
		var stats_label := Label.new()
		stats_label.text = "⚔ %.0f  •  ⏱ %.1f/s" % [eff_dmg, eff_spd]
		stats_label.add_theme_font_size_override("font_size", 10)
		stats_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.78, 0.85))

		vbox.add_child(top_row)
		vbox.add_child(cost_label)
		vbox.add_child(stats_label)
		hbox.add_child(vbox)
		card.set_meta("cost_label", cost_label)
		card.set_meta("icon_bg_style", icon_bg_style)

		margin.add_child(hbox)
		vbox_outer.add_child(margin)
		card.add_child(vbox_outer)

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

		# Staggered fade-in entrance
		var card_idx := TOWER_RESOURCES.find(path)
		card.modulate.a = 0.0
		var entrance_tw := card.create_tween()
		entrance_tw.tween_interval(0.12 + float(card_idx) * 0.09)
		entrance_tw.tween_property(card, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)

		# Hover: scale up card + thicken border for a 3A "lift" effect
		var captured_card := card
		btn.mouse_entered.connect(func() -> void:
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(captured_card, "scale", Vector2(1.055, 1.055), 0.12)
			if captured_card.has_meta("card_style"):
				(captured_card.get_meta("card_style") as StyleBoxFlat).set_border_width_all(3)
		)
		btn.mouse_exited.connect(func() -> void:
			var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(captured_card, "scale", Vector2.ONE, 0.15)
			if captured_card.has_meta("card_style"):
				(captured_card.get_meta("card_style") as StyleBoxFlat).set_border_width_all(2)
		)

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
			var accent: Color = card.get_meta("accent") if card.has_meta("accent") \
					else Color(0.55, 0.43, 0.18, 1.0)
			card.modulate.a = 1.0 if can else 0.50
			if card.has_meta("card_style"):
				var st: StyleBoxFlat = card.get_meta("card_style")
				st.border_color = accent if can \
						else Color(accent.r * 0.45, accent.g * 0.45, accent.b * 0.45, 0.55)
			if card.has_meta("cost_label"):
				var lbl: Label = card.get_meta("cost_label")
				if can:
					lbl.text = card.get_meta("base_cost_text")
					lbl.add_theme_color_override("font_color", Color(0.97, 0.84, 0.38, 1.0))
				else:
					lbl.text = "差 %d 金" % (cost - new_gold)
					lbl.add_theme_color_override("font_color", Color(1.0, 0.40, 0.35, 1.0))
