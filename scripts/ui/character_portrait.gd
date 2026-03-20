## CharacterPortrait — game-CG style procedural character illustrations.
## Origin (0,0) is the character mid-torso. Negative Y is up.
## Left panel is 540 × 960 px; this Node2D sits at (270, 480).
class_name CharacterPortrait
extends Node2D

var _character: String = "narrator"
var _tween: Tween = null

func set_character(character_id: String) -> void:
	_character = character_id
	queue_redraw()

func fade_to(new_character: String) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "modulate:a", 0.0, 0.12)
	_tween.tween_callback(func() -> void:
		_character = new_character
		queue_redraw()
	)
	_tween.tween_property(self, "modulate:a", 1.0, 0.22)

func _draw() -> void:
	match _character:
		"coco":         _draw_coco()
		"gear_grandpa": _draw_gear_grandpa()
		"longing":      _draw_longing()
		_:              _draw_narrator()


# ── Drawing helpers ──────────────────────────────────────────────────────────

## Gradient-filled ellipse: bright centre fading to transparent/dark edge.
func _glow_oval(center: Vector2, rx: float, ry: float,
				col_in: Color, col_out: Color, segs: int = 40) -> void:
	var pts  := PackedVector2Array()
	var cols := PackedColorArray()
	pts.append(center)
	cols.append(col_in)
	for i in range(segs + 1):
		var a := TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		cols.append(col_out)
	draw_polygon(pts, cols)

## Uniform-colour filled ellipse.
func _oval(center: Vector2, rx: float, ry: float, col: Color, segs: int = 36) -> void:
	_glow_oval(center, rx, ry, col, col, segs)

## Gradient polygon: top vertices → col_top, bottom vertices → col_bot.
func _grad_poly(pts: PackedVector2Array, col_top: Color, col_bot: Color) -> void:
	if pts.size() == 0:
		return
	var min_y := pts[0].y
	var max_y := pts[0].y
	for p in pts:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var span := maxf(max_y - min_y, 1.0)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(col_top.lerp(col_bot, (p.y - min_y) / span))
	draw_polygon(pts, cols)

## Gear shape (teeth + hub).
func _gear(center: Vector2, inner_r: float, outer_r: float,
		   teeth: int, col: Color, col_dark: Color) -> void:
	var step := TAU / float(teeth)
	var pts  := PackedVector2Array()
	for i in range(teeth):
		var a0 := step * i - step * 0.22
		var a1 := step * i - step * 0.10
		var a2 := step * i + step * 0.10
		var a3 := step * i + step * 0.22
		pts.append(Vector2(cos(a0) * inner_r, sin(a0) * inner_r) + center)
		pts.append(Vector2(cos(a1) * outer_r, sin(a1) * outer_r) + center)
		pts.append(Vector2(cos(a2) * outer_r, sin(a2) * outer_r) + center)
		pts.append(Vector2(cos(a3) * inner_r, sin(a3) * inner_r) + center)
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(col)
	draw_polygon(pts, cols)
	draw_polyline(pts, col_dark, 1.5, true)
	_oval(center, inner_r * 0.40, inner_r * 0.40, col_dark)
	_oval(center, inner_r * 0.24, inner_r * 0.24, col)

## Outlined circle with fill.
func _circle_outlined(center: Vector2, r: float, fill: Color, outline: Color,
		outline_w: float = 2.0) -> void:
	draw_circle(center, r, fill)
	draw_circle(center, r, outline, false, outline_w)


# ── Coco — copper wind-up robot girl ────────────────────────────────────────
func _draw_coco() -> void:
	var copper        := Color(0.72, 0.45, 0.20)
	var copper_hi     := Color(0.95, 0.68, 0.35)   # highlight
	var copper_sh     := Color(0.38, 0.22, 0.08)   # deep shadow
	var copper_mid    := Color(0.58, 0.36, 0.14)   # mid-tone
	var amber         := Color(0.98, 0.76, 0.14)
	var amber_glow    := Color(1.00, 0.88, 0.40, 0.22)
	var dark_bg       := Color(0.06, 0.04, 0.12, 0.0)

	# ── Background atmospheric glow ──
	_glow_oval(Vector2(0, -80), 200, 290,
		Color(0.80, 0.50, 0.12, 0.28),
		Color(0.10, 0.06, 0.18, 0.0), 48)
	_glow_oval(Vector2(0, -80), 110, 160,
		Color(0.95, 0.68, 0.20, 0.18),
		Color(0.95, 0.68, 0.20, 0.0), 40)

	# ── Ground shadow ──
	_oval(Vector2(0, 340), 90, 18, Color(0.0, 0.0, 0.0, 0.35), 32)

	# ── Legs ──
	var leg_l := PackedVector2Array([
		Vector2(-56, 70), Vector2(-22, 70),
		Vector2(-18, 320), Vector2(-52, 320)])
	var leg_r := PackedVector2Array([
		Vector2(22, 70), Vector2(56, 70),
		Vector2(52, 320), Vector2(18, 320)])
	_grad_poly(leg_l, copper_mid, copper_sh)
	_grad_poly(leg_r, copper_mid, copper_sh)
	draw_polyline(leg_l, copper_sh, 1.5, true)
	draw_polyline(leg_r, copper_sh, 1.5, true)

	# Feet
	var foot_l := PackedVector2Array([
		Vector2(-62, 315), Vector2(-10, 315),
		Vector2(-8,  338), Vector2(-64, 338)])
	var foot_r := PackedVector2Array([
		Vector2(10, 315), Vector2(62, 315),
		Vector2(64, 338), Vector2(8,  338)])
	_grad_poly(foot_l, copper, copper_sh)
	_grad_poly(foot_r, copper, copper_sh)

	# ── Wind-up key (behind right shoulder) ──
	draw_rect(Rect2(75, -180, 16, 65), copper_sh)
	draw_rect(Rect2(65, -188, 36, 14), copper_sh)
	draw_rect(Rect2(65, -202, 36, 14), copper_sh)
	draw_rect(Rect2(67, -202, 12, 28), copper_sh)  # left prong

	# ── Arms ──
	var arm_l := PackedVector2Array([
		Vector2(-82, -120), Vector2(-115, -90),
		Vector2(-120, 90),  Vector2(-80, 95)])
	var arm_r := PackedVector2Array([
		Vector2(82, -120), Vector2(115, -90),
		Vector2(120, 90),  Vector2(80, 95)])
	_grad_poly(arm_l, copper_mid, copper_sh)
	draw_polyline(arm_l, copper_sh, 1.5, true)
	_grad_poly(arm_r, copper_mid, copper_sh)
	draw_polyline(arm_r, copper_sh, 1.5, true)
	# Hand-claws
	for i in range(3):
		var fy := 90.0 + i * 12.0
		draw_circle(Vector2(-120 + i * 4, fy), 7, copper_mid)
		draw_circle(Vector2(120 - i * 4, fy), 7, copper_mid)

	# ── Torso ──
	var torso := PackedVector2Array([
		Vector2(-82, -125), Vector2(82, -125),
		Vector2(68, 78),    Vector2(-68, 78)])
	_grad_poly(torso, copper, copper_sh)
	draw_polyline(torso, copper_sh, 2.0, true)
	# Panel lines (left/right seam)
	draw_line(Vector2(-40, -110), Vector2(-40, 60), copper_hi, 1.0)
	draw_line(Vector2(40, -110),  Vector2(40, 60),  copper_hi, 1.0)
	# Horizontal panel seam at mid-torso
	draw_line(Vector2(-68, -20), Vector2(68, -20), copper_sh, 1.0)

	# ── Chest gear-locket ──
	_gear(Vector2(0, 0), 28, 36, 8, copper_mid, copper_sh)
	draw_circle(Vector2(0, 0), 22, Color(0.10, 0.08, 0.05))
	draw_circle(Vector2(0, 0), 15, amber * Color(1, 1, 1, 0.85))
	draw_circle(Vector2(0, 0), 8,  Color(1.0, 0.95, 0.60))
	# Locket glow
	_glow_oval(Vector2(0, 0), 20, 20,
		Color(1.0, 0.90, 0.40, 0.40), Color(1.0, 0.70, 0.10, 0.0), 24)

	# ── Neck ──
	var neck := PackedVector2Array([
		Vector2(-18, -138), Vector2(18, -138),
		Vector2(14, -118),  Vector2(-14, -118)])
	_grad_poly(neck, copper, copper_mid)
	# Neck ring details
	draw_rect(Rect2(-18, -138, 36, 5), copper_sh)
	draw_rect(Rect2(-18, -122, 36, 5), copper_sh)

	# ── Head ──
	# Slight oval (taller than wide) for robot-girl proportions
	_glow_oval(Vector2(0, -220), 92, 92, copper, copper_mid, 40)
	draw_circle(Vector2(0, -220), 90, copper_sh, false, 2.5)
	# Face plate (lighter lower half of head)
	_glow_oval(Vector2(0, -210), 70, 62,
		Color(0.88, 0.60, 0.28, 0.80), Color(0.88, 0.60, 0.28, 0.0), 36)
	# Head panel seam (horizontal)
	draw_line(Vector2(-90, -222), Vector2(90, -222), copper_hi, 1.0)

	# ── Ear-speakers ──
	draw_rect(Rect2(-105, -250, 16, 34), copper_sh)
	draw_rect(Rect2(-105, -242, 16, 18), Color(0.08, 0.06, 0.04))
	draw_rect(Rect2(89, -250, 16, 34),  copper_sh)
	draw_rect(Rect2(89, -242, 16, 18),  Color(0.08, 0.06, 0.04))
	# Speaker grille dots
	for gy in range(3):
		draw_circle(Vector2(-97, -242 + gy * 6), 2, copper_mid)
		draw_circle(Vector2( 97, -242 + gy * 6), 2, copper_mid)

	# ── Eyes ──
	var eye_l := Vector2(-30, -228)
	var eye_r := Vector2( 30, -228)
	# Socket
	draw_circle(eye_l, 22, copper_sh)
	draw_circle(eye_r, 22, copper_sh)
	# Iris — bright amber
	draw_circle(eye_l, 17, amber)
	draw_circle(eye_r, 17, amber)
	# Iris gradient (inner bright)
	_glow_oval(eye_l, 17, 17, Color(1.0, 0.95, 0.55), amber * Color(1,1,1,0), 24)
	_glow_oval(eye_r, 17, 17, Color(1.0, 0.95, 0.55), amber * Color(1,1,1,0), 24)
	# Pupil
	draw_circle(eye_l, 10, Color(0.04, 0.03, 0.02))
	draw_circle(eye_r, 10, Color(0.04, 0.03, 0.02))
	# Specular highlight (upper-left)
	draw_circle(eye_l + Vector2(-5, -5), 5, Color(1.0, 0.98, 0.90, 0.95))
	draw_circle(eye_r + Vector2(-5, -5), 5, Color(1.0, 0.98, 0.90, 0.95))
	# Eye glow rim
	draw_circle(eye_l, 22, amber_glow, false, 2.0)
	draw_circle(eye_r, 22, amber_glow, false, 2.0)

	# ── Antennae ──
	draw_line(Vector2(-18, -310), Vector2(-30, -270), copper_mid, 3.0)
	draw_line(Vector2(18, -310),  Vector2(30, -270),  copper_mid, 3.0)
	draw_circle(Vector2(-18, -312), 7, amber)
	draw_circle(Vector2( 18, -312), 7, amber)
	_glow_oval(Vector2(-18, -312), 10, 10,
		Color(1.0, 0.90, 0.30, 0.50), Color(1.0, 0.90, 0.30, 0.0), 16)
	_glow_oval(Vector2( 18, -312), 10, 10,
		Color(1.0, 0.90, 0.30, 0.50), Color(1.0, 0.90, 0.30, 0.0), 16)

	# ── Mouth ──
	draw_rect(Rect2(-20, -192, 40, 7), copper_sh)
	# Smile line
	for i in range(4):
		var t := float(i) / 3.0
		var sx := lerpf(-14.0, 14.0, t)
		var sy := -188.0 + sin(t * PI) * 4.0
		draw_circle(Vector2(sx, sy), 1.8, copper_hi)

	# ── Torso rim light (right edge) ──
	draw_line(Vector2(68, -115), Vector2(68, 68),  Color(1.0, 0.75, 0.30, 0.28), 4.0)
	draw_line(Vector2(-68, -115), Vector2(-68, 68), Color(0.95, 0.65, 0.20, 0.18), 3.0)


# ── 齒輪爺爺 — rotund steampunk clockwork grandfather ───────────────────────
func _draw_gear_grandpa() -> void:
	var bronze      := Color(0.52, 0.34, 0.14)
	var bronze_hi   := Color(0.78, 0.56, 0.24)
	var bronze_sh   := Color(0.28, 0.17, 0.06)
	var bronze_mid  := Color(0.42, 0.27, 0.10)
	var eye_gold    := Color(0.92, 0.80, 0.14)
	var steam_col   := Color(0.82, 0.82, 0.82, 0.55)

	# ── Background glow ──
	_glow_oval(Vector2(0, -40), 210, 280,
		Color(0.65, 0.42, 0.10, 0.25),
		Color(0.12, 0.08, 0.02, 0.0), 48)

	# ── Ground shadow ──
	_oval(Vector2(0, 330), 100, 20, Color(0, 0, 0, 0.35), 32)

	# ── Legs (short stubby) ──
	var leg_l := PackedVector2Array([Vector2(-60, 100), Vector2(-18, 100), Vector2(-16, 290), Vector2(-58, 290)])
	var leg_r := PackedVector2Array([Vector2(18, 100),  Vector2(60, 100),  Vector2(58, 290),  Vector2(16, 290)])
	_grad_poly(leg_l, bronze, bronze_sh)
	_grad_poly(leg_r, bronze, bronze_sh)
	# Feet (rounded squares)
	_oval(Vector2(-38, 308), 38, 20, bronze_sh, 24)
	_oval(Vector2( 38, 308), 38, 20, bronze_sh, 24)

	# ── Steam pipes behind ──
	draw_rect(Rect2(-78, -280, 20, 120), bronze_sh)
	draw_rect(Rect2( 58, -280, 20, 120), bronze_sh)
	# Pipe caps
	draw_rect(Rect2(-82, -282, 28, 10), bronze_sh)
	draw_rect(Rect2( 54, -282, 28, 10), bronze_sh)
	# Steam puffs
	for i in range(3):
		var off := float(i)
		_oval(Vector2(-68, -285 - off * 18), 12 - off * 2.5, 12 - off * 2.5,
			Color(steam_col.r, steam_col.g, steam_col.b, steam_col.a * (1.0 - off * 0.3)))
		_oval(Vector2( 68, -285 - off * 18), 12 - off * 2.5, 12 - off * 2.5,
			Color(steam_col.r, steam_col.g, steam_col.b, steam_col.a * (1.0 - off * 0.3)))

	# ── Arms (wide short arms) ──
	var arm_l := PackedVector2Array([
		Vector2(-100, -80), Vector2(-145, -50), Vector2(-148, 60), Vector2(-105, 70)])
	var arm_r := PackedVector2Array([
		Vector2(100, -80), Vector2(145, -50), Vector2(148, 60), Vector2(105, 70)])
	_grad_poly(arm_l, bronze, bronze_sh)
	draw_polyline(arm_l, bronze_sh, 1.5, true)
	_grad_poly(arm_r, bronze, bronze_sh)
	draw_polyline(arm_r, bronze_sh, 1.5, true)
	# Cog wrist bands
	_gear(Vector2(-128, 55), 16, 22, 6, bronze_mid, bronze_sh)
	_gear(Vector2( 128, 55), 16, 22, 6, bronze_mid, bronze_sh)

	# ── Main body (large round) ──
	_glow_oval(Vector2(0, 0), 108, 108, bronze, bronze_sh, 40)
	draw_circle(Vector2(0, 0), 108, bronze_sh, false, 3.0)
	# Body rivets
	for i in range(12):
		var a := TAU * float(i) / 12.0
		draw_circle(Vector2(cos(a) * 104, sin(a) * 104), 5, bronze_sh)
		draw_circle(Vector2(cos(a) * 104, sin(a) * 104), 3, bronze_hi)
	# Belly plate / panel
	_glow_oval(Vector2(0, 30), 65, 52,
		Color(bronze_hi.r, bronze_hi.g, bronze_hi.b, 0.45),
		Color(bronze_hi.r, bronze_hi.g, bronze_hi.b, 0.0), 32)
	# Central big gear
	_gear(Vector2(0, 28), 30, 40, 10, bronze_mid, bronze_sh)
	draw_circle(Vector2(0, 28), 24, Color(0.12, 0.08, 0.04))
	draw_circle(Vector2(0, 28), 16, bronze_hi)
	draw_circle(Vector2(0, 28),  8, Color(0.92, 0.75, 0.18))

	# ── Face ──
	_oval(Vector2(0, -45), 74, 64,
		Color(bronze_hi.r, bronze_hi.g, bronze_hi.b, 0.55), 36)

	# Left monocle eye (big)
	_circle_outlined(Vector2(-30, -58), 28, bronze_sh, bronze_sh)
	draw_circle(Vector2(-30, -58), 24, Color(0.06, 0.05, 0.03))
	draw_circle(Vector2(-30, -58), 17, eye_gold)
	_glow_oval(Vector2(-30, -58), 17, 17,
		Color(1.0, 0.95, 0.55), Color(0.90, 0.70, 0.10, 0.0), 24)
	draw_circle(Vector2(-30, -58), 10, Color(0.04, 0.03, 0.01))
	draw_circle(Vector2(-38, -66),  6, Color(1.0, 0.96, 0.85, 0.90))  # specular
	# Monocle gear ring
	for i in range(8):
		var a := TAU * float(i) / 8.0
		draw_line(
			Vector2(cos(a) * 24, sin(a) * 24) + Vector2(-30, -58),
			Vector2(cos(a) * 30, sin(a) * 30) + Vector2(-30, -58),
			bronze_sh, 4.0)

	# Right small eye
	_circle_outlined(Vector2(30, -58), 19, bronze_sh, bronze_sh)
	draw_circle(Vector2(30, -58), 15, Color(0.06, 0.05, 0.03))
	draw_circle(Vector2(30, -58), 10, eye_gold)
	draw_circle(Vector2(30, -58),  6, Color(0.04, 0.03, 0.01))
	draw_circle(Vector2(24, -65),   4, Color(1.0, 0.96, 0.85, 0.88))

	# Monocle chain
	for i in range(8):
		var t := float(i) / 7.0
		draw_circle(Vector2(lerpf(-2.0, 28.0, t), -55.0 + sin(t * PI) * 4.0), 2.0, bronze_sh)

	# Nose bolt
	draw_circle(Vector2(2, -35), 7, bronze_sh)
	draw_circle(Vector2(2, -35), 4, bronze_hi)

	# Moustache
	for i in range(12):
		var t := float(i) / 11.0
		var mx := lerpf(-50.0, 50.0, t)
		var my := -14.0 + sin(t * PI) * 14.0
		draw_circle(Vector2(mx, my), 4.0 + sin(t * PI) * 2.0, bronze_sh)

	# Beard gears (arc of 4)
	for g in range(4):
		var a := PI * 0.18 + float(g) * PI * 0.22
		var gp := Vector2(cos(a) * 68, sin(a) * 68) + Vector2(0, 20)
		_gear(gp, 12, 17, 6, bronze_mid, bronze_sh)

	# ── Hat ──
	# Brim
	_grad_poly(PackedVector2Array([
		Vector2(-76, -120), Vector2(76, -120),
		Vector2(62, -110),  Vector2(-62, -110)]),
		bronze_sh, bronze_mid)
	# Crown
	_grad_poly(PackedVector2Array([
		Vector2(-50, -230), Vector2(50, -230),
		Vector2(60, -120),  Vector2(-60, -120)]),
		Color(0.20, 0.12, 0.05), bronze_sh)
	# Hat band
	draw_rect(Rect2(-60, -128, 120, 10), eye_gold * Color(1,1,1,0.70))
	# Hat gear emblem
	_gear(Vector2(0, -178), 14, 20, 7, bronze_mid, bronze_sh)
	draw_circle(Vector2(0, -178), 9, Color(0.10, 0.07, 0.03))
	draw_circle(Vector2(0, -178), 5, eye_gold)

	# ── Rim light ──
	draw_circle(Vector2(0, 0), 108, Color(0.95, 0.75, 0.30, 0.15), false, 5.0)


# ── Longing — ethereal shadow entity ────────────────────────────────────────
func _draw_longing() -> void:
	var void_col    := Color(0.04, 0.02, 0.10)
	var shadow      := Color(0.12, 0.06, 0.25, 0.85)
	var violet      := Color(0.55, 0.22, 0.88)
	var violet_glow := Color(0.55, 0.22, 0.88, 0.0)
	var white_core  := Color(0.92, 0.85, 1.00)

	# ── Deep void background ──
	_glow_oval(Vector2(0, -60), 240, 340,
		Color(0.18, 0.08, 0.35, 0.45),
		Color(0.04, 0.02, 0.10, 0.0), 48)

	# ── Ground shadow ──
	_oval(Vector2(0, 340), 60, 12, Color(0.05, 0.02, 0.12, 0.55), 24)

	# ── Shadow body — layered irregular blobs ──
	for layer in range(5):
		var r: float = 130.0 - layer * 6.0
		var pts := PackedVector2Array()
		for j in range(20):
			var a := TAU * float(j) / 20.0
			var nr: float = r + sin(a * 4.1 + float(layer) * 1.3) * 22 \
				+ cos(a * 2.7 + float(layer) * 0.8) * 14
			pts.append(Vector2(cos(a) * nr, sin(a) * nr * 1.4) + Vector2(0, -60))
		var alpha: float = 0.18 + layer * 0.10
		var cols := PackedColorArray()
		cols.resize(pts.size())
		cols.fill(Color(shadow.r, shadow.g, shadow.b, alpha))
		draw_polygon(pts, cols)

	# ── Wispy tendrils ──
	var tendril_pts := [
		[Vector2(-90, 120), Vector2(-140, 180), Vector2(-160, 260), Vector2(-120, 330)],
		[Vector2( 90, 120), Vector2( 140, 200), Vector2( 130, 290), Vector2(  90, 340)],
		[Vector2(-50, 140), Vector2(-80,  230), Vector2(-60,  310)],
		[Vector2( 50, 140), Vector2( 90,  250), Vector2( 70,  320)],
	]
	for tendril in tendril_pts:
		for i in range(tendril.size() - 1):
			var t_frac := float(i) / float(tendril.size())
			var w: float = 14.0 * (1.0 - t_frac)
			draw_line(tendril[i], tendril[i + 1],
				Color(shadow.r, shadow.g, shadow.b, 0.55 - t_frac * 0.45), w)

	# ── Inner violet glow ──
	_glow_oval(Vector2(0, -60), 70, 90,
		Color(violet.r, violet.g, violet.b, 0.35),
		Color(violet.r, violet.g, violet.b, 0.0), 40)
	_glow_oval(Vector2(0, -60), 35, 45,
		Color(violet.r, violet.g, violet.b, 0.55),
		Color(violet.r, violet.g, violet.b, 0.0), 32)

	# ── Core bright pulse ──
	_glow_oval(Vector2(0, -60), 15, 15,
		Color(white_core.r, white_core.g, white_core.b, 0.90),
		Color(white_core.r, white_core.g, white_core.b, 0.0), 24)

	# ── Floating eyes (three pairs at different heights) ──
	var eye_positions := [
		[Vector2(-45, -150), Vector2(45, -150)],   # high pair
		[Vector2(-62, -55),  Vector2(62, -55)],    # mid pair
		[Vector2(-35, 40),   Vector2(35, 40)],     # low pair
	]
	for pair_idx in range(eye_positions.size()):
		var pair: Array = eye_positions[pair_idx]
		var r_outer: float = 11.0 - pair_idx * 1.5
		for ep_v in pair:
			var ep: Vector2 = ep_v
			# Eye glow
			_glow_oval(ep, r_outer + 8, r_outer + 8,
				Color(violet.r, violet.g, violet.b, 0.35),
				Color(violet.r, violet.g, violet.b, 0.0), 16)
			# Eye fill
			draw_circle(ep, r_outer, violet)
			draw_circle(ep, r_outer * 0.55, white_core)
			# Slit pupil
			draw_line(ep + Vector2(0, -r_outer * 0.55),
					  ep + Vector2(0,  r_outer * 0.55),
					  Color(0.04, 0.02, 0.08), 3.0)

	# ── Particle wisps ──
	var wisp_offsets := [
		Vector2(-130, -200), Vector2(120, -220), Vector2(-160, -80),
		Vector2(150, -40),   Vector2(-100, 200), Vector2(110, 220),
	]
	for wp in wisp_offsets:
		_glow_oval(wp, 8, 8,
			Color(violet.r, violet.g, violet.b, 0.38),
			Color(violet.r, violet.g, violet.b, 0.0), 12)


# ── Narrator — celestial compass-rose mandala ────────────────────────────────
func _draw_narrator() -> void:
	var navy     := Color(0.10, 0.14, 0.35)
	var silver   := Color(0.72, 0.80, 0.95)
	var gold     := Color(0.88, 0.75, 0.25)
	var pale     := Color(0.88, 0.92, 1.00, 0.30)
	var gold_glow := Color(0.95, 0.82, 0.30, 0.0)

	# ── Background deep space ──
	_glow_oval(Vector2.ZERO, 240, 240,
		Color(0.12, 0.18, 0.40, 0.55),
		Color(0.04, 0.06, 0.15, 0.0), 48)

	# ── Scattered stars ──
	var star_pos := [
		Vector2(-180, -200), Vector2(160, -220), Vector2(-220, 40),
		Vector2(210, 80),    Vector2(-150, 180), Vector2(140, -80),
		Vector2(-80, -260),  Vector2(200, 200),  Vector2(-200, -50),
		Vector2(60, 240),
	]
	for i in range(star_pos.size()):
		var sp: Vector2 = star_pos[i]
		var sr: float = 2.5 + (i % 3) * 1.2
		draw_circle(sp, sr, Color(silver.r, silver.g, silver.b, 0.75))
		# Star cross
		draw_line(sp + Vector2(-sr * 2, 0), sp + Vector2(sr * 2, 0),
			Color(silver.r, silver.g, silver.b, 0.35), 1.0)
		draw_line(sp + Vector2(0, -sr * 2), sp + Vector2(0, sr * 2),
			Color(silver.r, silver.g, silver.b, 0.35), 1.0)

	# ── Outer orbit ring ──
	draw_circle(Vector2.ZERO, 175, Color(silver.r, silver.g, silver.b, 0.12), false, 1.5)
	draw_circle(Vector2.ZERO, 172, Color(silver.r, silver.g, silver.b, 0.08), false, 1.0)

	# ── 8 outer spoke medallions ──
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var mp := Vector2(cos(a) * 175, sin(a) * 175)
		_glow_oval(mp, 14, 14,
			Color(gold.r, gold.g, gold.b, 0.60), Color(gold.r, gold.g, gold.b, 0.0), 16)
		draw_circle(mp, 8, navy)
		draw_circle(mp, 5, gold)

	# ── Spoke lines ──
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var d1 := Vector2(cos(a) * 80, sin(a) * 80)
		var d2 := Vector2(cos(a) * 160, sin(a) * 160)
		draw_line(d1, d2, Color(silver.r, silver.g, silver.b, 0.22), 2.0)

	# ── Outer large gear ring ──
	_gear(Vector2.ZERO, 108, 124, 16, Color(navy.r, navy.g, navy.b, 0.80),
		Color(silver.r, silver.g, silver.b, 0.30))

	# ── Mid gear ──
	_gear(Vector2.ZERO, 74, 90, 12, Color(0.14, 0.20, 0.42, 0.90),
		Color(silver.r, silver.g, silver.b, 0.35))

	# ── Cardinal direction markers (N/S/E/W spear tips) ──
	for i in range(4):
		var a := TAU * float(i) / 4.0 - TAU * 0.25
		var tip  := Vector2(cos(a) * 108, sin(a) * 108)
		var base1 := Vector2(cos(a + 0.18) * 74, sin(a + 0.18) * 74)
		var base2 := Vector2(cos(a - 0.18) * 74, sin(a - 0.18) * 74)
		var pts := PackedVector2Array([tip, base1, base2])
		var cols := PackedColorArray([gold, Color(gold.r, gold.g, gold.b, 0.55),
			Color(gold.r, gold.g, gold.b, 0.55)])
		draw_polygon(pts, cols)

	# ── Inner circle ──
	draw_circle(Vector2.ZERO, 74, Color(0.08, 0.11, 0.28))
	draw_circle(Vector2.ZERO, 74, Color(silver.r, silver.g, silver.b, 0.28), false, 1.5)

	# ── Eye of the cosmos ──
	# Outer iris
	draw_circle(Vector2.ZERO, 48, Color(0.20, 0.30, 0.62))
	# Iris glow
	_glow_oval(Vector2.ZERO, 48, 48,
		Color(gold.r, gold.g, gold.b, 0.30), Color(gold.r, gold.g, gold.b, 0.0), 32)
	# Iris ring
	draw_circle(Vector2.ZERO, 48, Color(gold.r, gold.g, gold.b, 0.55), false, 2.0)
	# Pupil
	draw_circle(Vector2.ZERO, 28, Color(0.04, 0.06, 0.16))
	# Inner glow
	_glow_oval(Vector2.ZERO, 22, 22,
		Color(0.65, 0.75, 1.00, 0.60), Color(0.30, 0.45, 0.90, 0.0), 32)
	# Iris details — 8 petal shapes
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var p_in  := Vector2(cos(a) * 29, sin(a) * 29)
		var p_out := Vector2(cos(a) * 46, sin(a) * 46)
		draw_line(p_in, p_out, Color(gold.r, gold.g, gold.b, 0.35), 3.0)
	# Central star
	draw_circle(Vector2.ZERO, 12, Color(0.80, 0.88, 1.00, 0.90))
	draw_circle(Vector2.ZERO,  6, Color(1.00, 1.00, 1.00, 1.00))
	# Star cross sparkle
	for i in range(4):
		var a := TAU * float(i) / 4.0
		draw_line(Vector2(cos(a) * 7, sin(a) * 7),
				  Vector2(cos(a) * 18, sin(a) * 18),
				  Color(1.0, 0.95, 0.80, 0.70), 2.0)
