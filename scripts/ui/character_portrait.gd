## CharacterPortrait — procedurally draws story character portraits.
## Call set_character(portrait_id) to switch characters.
class_name CharacterPortrait
extends Node2D

var _character: String = "narrator"

func set_character(character_id: String) -> void:
	_character = character_id
	queue_redraw()

func _draw() -> void:
	match _character:
		"coco":         _draw_coco()
		"gear_grandpa": _draw_gear_grandpa()
		"longing":      _draw_longing()
		_:              _draw_narrator()

## ── Coco: copper wind-up robot with gear-locket chest ──────────────────────
func _draw_coco() -> void:
	var copper      := Color(0.72, 0.45, 0.20)
	var copper_dark := Color(0.52, 0.30, 0.12)
	var copper_light:= Color(0.88, 0.62, 0.30)
	var amber       := Color(0.95, 0.72, 0.10)
	var glow        := Color(1.00, 0.82, 0.30, 0.18)

	# Ambient glow
	draw_circle(Vector2(0, -60), 130, glow)

	# Wind-up key (behind torso, right side)
	draw_rect(Rect2(52, -105, 14, 50), copper_dark)
	draw_rect(Rect2(44, -110, 30, 10), copper_dark)

	# Torso (trapezoid via polygon)
	var torso_pts := PackedVector2Array([
		Vector2(-48, -20), Vector2(48, -20),
		Vector2(38, 60),   Vector2(-38, 60)
	])
	draw_colored_polygon(torso_pts, copper)
	draw_polyline(PackedVector2Array([
		torso_pts[0], torso_pts[1], torso_pts[2], torso_pts[3], torso_pts[0]
	]), copper_dark, 2.0)

	# Torso highlight (panel lines)
	draw_line(Vector2(-28, -10), Vector2(-28, 50), copper_light, 1.0)
	draw_line(Vector2(28, -10),  Vector2(28, 50),  copper_light, 1.0)

	# Chest gear-slot locket
	draw_circle(Vector2(0, 20), 20, copper_dark)
	draw_circle(Vector2(0, 20), 16, Color(0.15, 0.12, 0.08))
	draw_circle(Vector2(0, 20), 10, amber * Color(1,1,1,0.7))
	# Gear teeth around locket
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		var p_inner := Vector2(cos(a) * 16, sin(a) * 16) + Vector2(0, 20)
		var p_outer := Vector2(cos(a) * 22, sin(a) * 22) + Vector2(0, 20)
		draw_line(p_inner, p_outer, copper_light, 3.0)

	# Neck
	draw_rect(Rect2(-12, -35, 24, 18), copper)

	# Head
	draw_circle(Vector2(0, -70), 46, copper)
	draw_circle(Vector2(0, -70), 46, copper_dark, false, 2.0)

	# Head panel seam
	draw_line(Vector2(-46, -70), Vector2(46, -70), copper_light, 1.0)

	# Eyes
	draw_circle(Vector2(-18, -72), 12, copper_dark)
	draw_circle(Vector2(18, -72),  12, copper_dark)
	draw_circle(Vector2(-18, -72), 8, amber)
	draw_circle(Vector2(18, -72),  8, amber)
	# Eye glow
	draw_circle(Vector2(-18, -72), 4, Color(1.0, 0.95, 0.5, 0.9))
	draw_circle(Vector2(18, -72),  4, Color(1.0, 0.95, 0.5, 0.9))

	# Ear-speakers
	draw_rect(Rect2(-58, -82, 12, 24), copper_dark)
	draw_rect(Rect2(46, -82, 12, 24),  copper_dark)

	# Mouth (thin slot)
	draw_rect(Rect2(-14, -52, 28, 5), copper_dark)

	# Arms
	var arm_pts_l := PackedVector2Array([
		Vector2(-48, -18), Vector2(-68, -10), Vector2(-74, 50), Vector2(-52, 56)
	])
	draw_colored_polygon(arm_pts_l, copper)
	draw_polyline(PackedVector2Array([arm_pts_l[0], arm_pts_l[1], arm_pts_l[2], arm_pts_l[3]]), copper_dark, 2.0)
	var arm_pts_r := PackedVector2Array([
		Vector2(48, -18), Vector2(68, -10), Vector2(74, 50), Vector2(52, 56)
	])
	draw_colored_polygon(arm_pts_r, copper)
	draw_polyline(PackedVector2Array([arm_pts_r[0], arm_pts_r[1], arm_pts_r[2], arm_pts_r[3]]), copper_dark, 2.0)

	# Legs
	draw_rect(Rect2(-36, 60, 28, 55), copper_dark)
	draw_rect(Rect2(8,   60, 28, 55), copper_dark)
	draw_rect(Rect2(-40, 108, 32, 12), copper)  # left foot
	draw_rect(Rect2(8,   108, 32, 12), copper)  # right foot

## ── Gear Grandpa: round steam-clockwork toy ────────────────────────────────
func _draw_gear_grandpa() -> void:
	var bronze      := Color(0.50, 0.32, 0.14)
	var bronze_dark := Color(0.32, 0.20, 0.08)
	var bronze_light:= Color(0.70, 0.50, 0.22)
	var steam_white := Color(0.85, 0.85, 0.85, 0.70)
	var eye_yellow  := Color(0.90, 0.78, 0.12)
	var glow        := Color(0.80, 0.55, 0.15, 0.14)

	# Glow
	draw_circle(Vector2(0, -30), 150, glow)

	# Steam pipes (behind body)
	draw_rect(Rect2(-58, -115, 16, 55), bronze_dark)
	draw_rect(Rect2(42,  -115, 16, 55), bronze_dark)
	# Steam puffs
	draw_circle(Vector2(-50, -118), 10, steam_white)
	draw_circle(Vector2(-44, -128), 7,  Color(steam_white.r, steam_white.g, steam_white.b, 0.50))
	draw_circle(Vector2(50, -118),  10, steam_white)
	draw_circle(Vector2(44, -128),  7,  Color(steam_white.r, steam_white.g, steam_white.b, 0.50))

	# Main body (large circle)
	draw_circle(Vector2(0, -10), 88, bronze)
	draw_circle(Vector2(0, -10), 88, bronze_dark, false, 3.0)

	# Body rivets
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		var rp := Vector2(cos(a) * 84, sin(a) * 84) + Vector2(0, -10)
		draw_circle(rp, 4, bronze_dark)

	# Face plate (slightly lighter oval)
	var face_pts := PackedVector2Array()
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		face_pts.append(Vector2(cos(a) * 62, sin(a) * 52) + Vector2(0, -15))
	draw_colored_polygon(face_pts, bronze_light * Color(1,1,1,0.6))

	# Monocle left eye (gear-shaped)
	draw_circle(Vector2(-26, -28), 22, bronze_dark)
	draw_circle(Vector2(-26, -28), 18, Color(0.10, 0.08, 0.05))
	draw_circle(Vector2(-26, -28), 12, eye_yellow)
	draw_circle(Vector2(-26, -28), 6,  Color(1,1,0.8))
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		draw_line(
			Vector2(cos(a) * 18, sin(a) * 18) + Vector2(-26, -28),
			Vector2(cos(a) * 24, sin(a) * 24) + Vector2(-26, -28),
			bronze_dark, 4.0
		)

	# Small right eye
	draw_circle(Vector2(28, -28), 16, bronze_dark)
	draw_circle(Vector2(28, -28), 12, Color(0.10, 0.08, 0.05))
	draw_circle(Vector2(28, -28), 8,  eye_yellow)
	draw_circle(Vector2(28, -28), 4,  Color(1, 1, 0.8))

	# Monocle chain
	draw_line(Vector2(-8, -28), Vector2(28, -28), bronze_dark, 2.0)

	# Nose: small gear bolt
	draw_circle(Vector2(0, -8), 6, bronze_dark)
	draw_circle(Vector2(0, -8), 4, bronze_light)

	# Mouth/mustache (curved line)
	for i in range(10):
		var t: float = float(i) / 9.0
		var x1 := lerpf(-38.0, 38.0, t)
		var x2 := lerpf(-38.0, 38.0, t + 0.1)
		var y1: float = 8 + sin(t * PI) * 12
		var y2: float = 8 + sin((t + 0.1) * PI) * 12
		draw_line(Vector2(x1, y1), Vector2(x2, y2), bronze_dark, 3.5)

	# Beard gears (3 small gears at bottom)
	for g in range(3):
		var gx: float = (g - 1) * 34.0
		draw_circle(Vector2(gx, 34), 14, bronze_dark)
		draw_circle(Vector2(gx, 34), 10, bronze)
		for i in range(6):
			var a: float = TAU * float(i) / 6.0
			draw_line(
				Vector2(cos(a) * 10, sin(a) * 10) + Vector2(gx, 34),
				Vector2(cos(a) * 15, sin(a) * 15) + Vector2(gx, 34),
				bronze_dark, 3.0
			)

	# Hat (small top hat)
	draw_rect(Rect2(-52, -102, 104, 14), bronze_dark)  # brim
	draw_rect(Rect2(-36, -140, 72, 40),  bronze_dark)  # crown
	# Hat band
	draw_rect(Rect2(-36, -104, 72, 6),   bronze_light)

## ── Narrator: decorative gear mandala ──────────────────────────────────────
func _draw_narrator() -> void:
	var c1 := Color(0.40, 0.55, 0.80, 0.20)
	var c2 := Color(0.60, 0.75, 1.00, 0.35)
	var c3 := Color(0.80, 0.90, 1.00, 0.15)

	# Outer ring
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		draw_circle(Vector2(cos(a) * 120, sin(a) * 120), 8, c2)

	# Middle gear
	for i in range(16):
		var a: float = TAU * float(i) / 16.0
		var p1 := Vector2(cos(a) * 72, sin(a) * 72)
		var p2 := Vector2(cos(a) * 90, sin(a) * 90)
		draw_line(p1, p2, c1, 5.0)
	draw_circle(Vector2.ZERO, 72, c3)
	draw_circle(Vector2.ZERO, 72, c2, false, 2.0)

	# Inner gear
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		var p1 := Vector2(cos(a) * 38, sin(a) * 38)
		var p2 := Vector2(cos(a) * 50, sin(a) * 50)
		draw_line(p1, p2, c2, 6.0)
	draw_circle(Vector2.ZERO, 38, Color(0.20, 0.30, 0.55, 0.30))

	# Center dot
	draw_circle(Vector2.ZERO, 12, c2)
	draw_circle(Vector2.ZERO, 6,  Color(0.85, 0.92, 1.0, 0.80))

	# Spokes
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		draw_line(Vector2(cos(a) * 50, sin(a) * 50),
				  Vector2(cos(a) * 112, sin(a) * 112), c1, 1.5)

## ── Longing: shadowy abstract ───────────────────────────────────────────────
func _draw_longing() -> void:
	var shadow := Color(0.12, 0.06, 0.22, 0.60)
	var glow   := Color(0.55, 0.20, 0.80, 0.40)
	var core   := Color(0.75, 0.40, 1.00, 0.85)

	# Outer dark mass (irregular blob)
	for i in range(5):
		var r: float = 80.0 + i * 12.0
		var pts := PackedVector2Array()
		for j in range(16):
			var a: float = TAU * float(j) / 16.0
			var nr: float = r + sin(a * 3.7 + float(i)) * 20
			pts.append(Vector2(cos(a) * nr, sin(a) * nr))
		draw_colored_polygon(pts, Color(shadow.r, shadow.g, shadow.b, shadow.a * 0.3))

	draw_circle(Vector2.ZERO, 60, glow)
	draw_circle(Vector2.ZERO, 30, core)
	draw_circle(Vector2.ZERO, 12, Color(1.0, 0.9, 1.0, 0.95))

	# Floating eye shapes
	for i in range(6):
		var a: float = TAU * float(i) / 6.0
		var ep := Vector2(cos(a) * 85, sin(a) * 85)
		draw_circle(ep, 7, core)
		draw_circle(ep, 3, Color(1, 1, 1, 0.9))
