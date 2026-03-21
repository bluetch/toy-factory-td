## SkillSelectScreen — full-screen Roguelike skill-pick overlay.
##
## Instantiate dynamically and add to scene root, then call show_and_pick().
## The CanvasLayer (layer=20) ensures it renders above all in-game UI.
##
## Usage:
##   var screen := SkillSelectScreen.new()
##   get_tree().root.add_child(screen)
##   screen.show_and_pick(SkillManager.pick_random_skills(3), func(id): ...)
class_name SkillSelectScreen
extends CanvasLayer

const RARITY_COLORS: Array[Color] = [
	Color(0.62, 0.65, 0.70, 1.0),   ## common  — silver-grey
	Color(0.28, 0.55, 1.00, 1.0),   ## rare    — azure blue
	Color(0.80, 0.35, 1.00, 1.0),   ## epic    — royal purple
]
const RARITY_BG: Array[Color] = [
	Color(0.06, 0.08, 0.14, 0.97),
	Color(0.04, 0.07, 0.20, 0.97),
	Color(0.10, 0.04, 0.18, 0.97),
]
const RARITY_NAMES: Array[String] = ["普通", "稀有", "史詩"]

const CARD_W := 220.0
const CARD_H := 300.0
const CARD_GAP := 30.0
const VIEWPORT_W := 1728.0
const VIEWPORT_H := 960.0

var _callback: Callable
var _done: bool = false
var _root_ctrl: Control = null   ## animated root; stored for entrance tween


func _ready() -> void:
	layer = 20


## Call once after adding to tree to populate and display.
func show_and_pick(skills: Array[SkillData], callback: Callable) -> void:
	_callback = callback
	_done     = false
	_build_ui(skills)


# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui(skills: Array[SkillData]) -> void:
	# Dark dimming overlay
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.80)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# Root control for entrance animation
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_root_ctrl = root

	# ── Title ──────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "選擇技能升級"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.60, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left  = 0.5;  title.anchor_right  = 0.5
	title.anchor_top   = 0.0;  title.anchor_bottom = 0.0
	title.offset_left  = -220.0; title.offset_right  = 220.0
	title.offset_top   = 100.0;  title.offset_bottom = 145.0
	root.add_child(title)

	var sub := Label.new()
	sub.text = "在本次關卡中永久有效"
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.68, 0.68, 0.65, 0.80))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_left  = 0.5;  sub.anchor_right  = 0.5
	sub.anchor_top   = 0.0;  sub.anchor_bottom = 0.0
	sub.offset_left  = -220.0; sub.offset_right  = 220.0
	sub.offset_top   = 148.0;  sub.offset_bottom = 174.0
	root.add_child(sub)

	# ── Skill cards ────────────────────────────────────────────────────
	var total_w := CARD_W * skills.size() + CARD_GAP * (skills.size() - 1)
	var card_x  := (VIEWPORT_W - total_w) * 0.5
	var card_y  := 195.0

	var cards: Array[PanelContainer] = []
	for i in range(skills.size()):
		var c := _build_card(root, skills[i], card_x + i * (CARD_W + CARD_GAP), card_y)
		if c != null:
			cards.append(c)

	# ── Skill summary strip at bottom ─────────────────────────────────
	_build_summary_bar(root)

	# ── Entrance animation — dim + title/sub fade first, then cards stagger ──
	root.modulate.a = 0.0
	root.scale        = Vector2(0.92, 0.92)
	root.pivot_offset = Vector2(VIEWPORT_W * 0.5, VIEWPORT_H * 0.5)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(root, "scale", Vector2.ONE, 0.22)

	# Cards drop-in with stagger
	for i in range(cards.size()):
		var c: PanelContainer = cards[i]
		c.modulate.a = 0.0
		var orig_y: float = c.position.y
		c.position.y = orig_y - 28.0
		var card_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tw.tween_interval(0.18 + float(i) * 0.11)
		card_tw.tween_property(c, "modulate:a", 1.0, 0.24)
		card_tw.parallel().tween_property(c, "position:y", orig_y, 0.28)


func _build_card(parent: Control, skill: SkillData, x: float, y: float) -> PanelContainer:
	var rc  := RARITY_COLORS[skill.rarity]
	var stacks := SkillManager.get_skill_stack(skill.skill_id)
	var at_max := skill.max_stacks > 0 and stacks >= skill.max_stacks

	# Card panel
	var style := StyleBoxFlat.new()
	style.bg_color = RARITY_BG[skill.rarity]
	style.set_border_width_all(2)
	style.border_color = rc if not at_max else rc.darkened(0.4)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(rc.r, rc.g, rc.b, 0.30)
	style.shadow_size  = 8

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", style)
	card.position           = Vector2(x, y)
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	if not at_max:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# Top rarity badge
	var rarity_lbl := Label.new()
	rarity_lbl.text = RARITY_NAMES[skill.rarity]
	rarity_lbl.add_theme_font_size_override("font_size", 11)
	rarity_lbl.add_theme_color_override("font_color", rc)
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_lbl)

	# Big emoji icon
	var icon_lbl := Label.new()
	icon_lbl.text = skill.icon
	icon_lbl.add_theme_font_size_override("font_size", 52)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = skill.skill_name
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.96, 0.78, 1.0) if not at_max else Color(0.55, 0.55, 0.55, 0.75))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Description
	var desc_m := MarginContainer.new()
	desc_m.add_theme_constant_override("margin_left",  14)
	desc_m.add_theme_constant_override("margin_right", 14)
	var desc_lbl := Label.new()
	desc_lbl.text = skill.description
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.76, 0.88))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_m.add_child(desc_lbl)
	vbox.add_child(desc_m)

	# Stack indicator
	if stacks > 0:
		var pips := ""
		for i in range(skill.max_stacks):
			pips += "● " if i < stacks else "○ "
		var stack_lbl := Label.new()
		stack_lbl.text = pips.strip_edges()
		stack_lbl.add_theme_font_size_override("font_size", 11)
		stack_lbl.add_theme_color_override("font_color", rc.lightened(0.2))
		stack_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(stack_lbl)
	elif at_max:
		var max_lbl := Label.new()
		max_lbl.text = "已達上限"
		max_lbl.add_theme_font_size_override("font_size", 11)
		max_lbl.add_theme_color_override("font_color", Color(0.65, 0.32, 0.32, 0.85))
		max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(max_lbl)

	if at_max:
		card.modulate.a = 0.45
		return card

	# Hover + click
	var btn := Button.new()
	btn.flat          = true
	btn.anchor_right  = 1.0
	btn.anchor_bottom = 1.0
	card.add_child(btn)

	btn.mouse_entered.connect(func() -> void:
		card.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
			.tween_property(card, "scale", Vector2(1.06, 1.06), 0.12)
		style.border_color = rc.lightened(0.35)
		style.shadow_size  = 16
	)
	btn.mouse_exited.connect(func() -> void:
		card.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) \
			.tween_property(card, "scale", Vector2.ONE, 0.14)
		style.border_color = rc
		style.shadow_size  = 8
	)
	btn.pressed.connect(func() -> void: _on_pick(skill, card))
	return card


## Bottom bar listing already-active skills.
func _build_summary_bar(parent: Control) -> void:
	var active: Array[String] = []
	# Collect skill ids with stacks > 0 from SkillManager pool
	for s: SkillData in SkillManager._pool:
		if SkillManager.get_skill_stack(s.skill_id) > 0:
			active.append("%s ×%d" % [s.skill_name, SkillManager.get_skill_stack(s.skill_id)])

	if active.is_empty():
		return

	var bar := Label.new()
	bar.text = "已選技能：" + "  ".join(active)
	bar.add_theme_font_size_override("font_size", 11)
	bar.add_theme_color_override("font_color", Color(0.60, 0.60, 0.58, 0.72))
	bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.anchor_left  = 0.5;  bar.anchor_right  = 0.5
	bar.anchor_top   = 1.0;  bar.anchor_bottom = 1.0
	bar.offset_left  = -500.0; bar.offset_right  = 500.0
	bar.offset_top   = -52.0;  bar.offset_bottom = -22.0
	parent.add_child(bar)


# ── Selection handler ─────────────────────────────────────────────────────────

func _on_pick(skill: SkillData, card: PanelContainer) -> void:
	if _done:
		return
	_done = true
	AudioManager.play_ui_click()

	# Flash the card → fade whole screen → callback
	var tw := create_tween()
	tw.tween_property(card, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.07)
	tw.tween_property(card, "modulate", Color.WHITE, 0.18)
	tw.tween_interval(0.10)
	tw.tween_property(_root_ctrl, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func() -> void:
		_callback.call(skill.skill_id)
		queue_free()
	)
