## MainMenuBg — cinematic painted-landscape background for the main menu.
## Draws a layered scene: sky gradient → far mountains → near mountains →
## forest treeline → ground → centre glow → decorative tower stacks → UFOs → vignette.
class_name MainMenuBg
extends Node2D

const BASE   := "res://assets/kenney_tower-defense-kit/Previews/"
const W      := 1728.0
const H      :=  960.0
const HORIZ  :=  420.0   ## Y coordinate of the horizon line

## Decorative tower stacks: [world_x, base_y, type]  0=round-a  1=square-b
const TOWERS := [
	[  95.0,  H - 60.0, 0],
	[ 195.0,  H - 60.0, 1],
	[1520.0,  H - 60.0, 1],
	[1630.0,  H - 60.0, 0],
	[ 820.0,  H - 60.0, 0],   ## distant centre tower (smaller scale)
]

var _tex:  Dictionary = {}
var _ufos: Array      = []
var _time: float      = 0.0


func _ready() -> void:
	_load_tex()
	_spawn_ufos()


func _load_tex() -> void:
	var names: Array[String] = [
		"tower-round-bottom-a", "tower-round-middle-a", "tower-round-top-a",
		"tower-square-bottom-b", "tower-square-middle-b", "tower-square-top-b",
		"enemy-ufo-a", "enemy-ufo-b", "enemy-ufo-c", "enemy-ufo-d",
	]
	for n in names:
		var p := BASE + n + ".png"
		if ResourceLoader.exists(p):
			_tex[n] = load(p)


func _spawn_ufos() -> void:
	_ufos = [
		{x =  520.0, y = HORIZ - 110.0, spd =  38.0, tex = "enemy-ufo-a", sc = 0.50, a = 0.38},
		{x = 1400.0, y = HORIZ -  55.0, spd = -44.0, tex = "enemy-ufo-b", sc = 0.38, a = 0.30},
		{x =  200.0, y = HORIZ +  80.0, spd =  52.0, tex = "enemy-ufo-c", sc = 0.62, a = 0.45},
		{x = 1600.0, y = HORIZ + 200.0, spd = -30.0, tex = "enemy-ufo-d", sc = 0.44, a = 0.32},
	]


func _process(delta: float) -> void:
	_time += delta
	for u in _ufos:
		u.x += float(u.spd) * delta
		if u.spd > 0 and u.x >  W + 140.0: u.x = -130.0
		if u.spd < 0 and u.x < -180.0:     u.x =  W + 130.0
	queue_redraw()


func _draw() -> void:
	_draw_sky()
	_draw_mountains_far()
	_draw_mountains_near()
	_draw_treeline()
	_draw_ground()
	_draw_center_glow()
	_draw_towers()
	_draw_ufos()
	_draw_vignette()


# ── Helpers ─────────────────────────────────────────────────────────────────

## Sine-based hill profile: returns Y offset above the horizon at world-X.
## freq controls horizontal frequency; phase shifts the curve.
func _hill(x: float, freq: float, phase: float) -> float:
	return abs(sin(x * freq + phase)) * 180.0 + sin(x * freq * 0.37 + phase * 1.7) * 60.0


## Draw a filled ellipse using draw_polygon() with 48 segments.
func draw_ellipse_aa(center: Vector2, rx: float, ry: float, col: Color) -> void:
	const SEG := 48
	var pts := PackedVector2Array()
	pts.resize(SEG)
	for i in range(SEG):
		var a := TAU * i / SEG
		pts[i] = center + Vector2(cos(a) * rx, sin(a) * ry)
	var cols := PackedColorArray()
	cols.resize(SEG)
	cols.fill(col)
	draw_polygon(pts, cols)


# ── Layer drawing ────────────────────────────────────────────────────────────

func _draw_sky() -> void:
	## Deep navy at top → dusty olive-green near horizon.
	var sky_top  := Color(0.05, 0.07, 0.18, 1.0)
	var sky_mid  := Color(0.10, 0.14, 0.28, 1.0)
	var sky_horiz := Color(0.22, 0.22, 0.16, 1.0)
	var split    := HORIZ * 0.5

	## Upper half — navy gradient
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, split), Vector2(0, split)]),
		PackedColorArray([sky_top, sky_top, sky_mid, sky_mid]))
	## Lower sky — navy to olive
	draw_polygon(
		PackedVector2Array([Vector2(0, split), Vector2(W, split), Vector2(W, HORIZ), Vector2(0, HORIZ)]),
		PackedColorArray([sky_mid, sky_mid, sky_horiz, sky_horiz]))


func _draw_mountains_far() -> void:
	## Back range — dark desaturated navy, gentle silhouette.
	var col := Color(0.10, 0.12, 0.22, 1.0)
	var pts  := PackedVector2Array()
	pts.append(Vector2(0.0, HORIZ))
	var steps := 80
	for i in range(steps + 1):
		var x := W * i / steps
		var h := _hill(x, 0.0028, 0.0) + _hill(x, 0.0011, 2.1)
		pts.append(Vector2(x, HORIZ - h * 0.55))
	pts.append(Vector2(W, HORIZ))
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(col)
	draw_polygon(pts, cols)


func _draw_mountains_near() -> void:
	## Front range — slightly lighter warm-grey; different rhythm creates depth.
	var col_bot := Color(0.15, 0.16, 0.20, 1.0)
	var col_top := Color(0.12, 0.13, 0.17, 1.0)
	var pts_bot := PackedVector2Array()
	var pts_top := PackedVector2Array()
	var steps   := 100
	for i in range(steps + 1):
		var x  := W * i / steps
		var h  := _hill(x, 0.0042, 1.3) + _hill(x, 0.0018, 3.7)
		var yy := HORIZ - h * 0.45
		pts_top.append(Vector2(x, yy))
		pts_bot.append(Vector2(x, HORIZ))
	## Build polygon: top contour + reversed bottom
	var poly := PackedVector2Array()
	for p in pts_top: poly.append(p)
	for i in range(pts_bot.size() - 1, -1, -1): poly.append(pts_bot[i])

	var cols := PackedColorArray()
	cols.resize(poly.size())
	for i in range(poly.size()):
		## Gradient: lighter at peak (top of poly), darker at horizon base
		var frac := float(i) / float(poly.size())
		cols[i] = col_top.lerp(col_bot, frac)
	draw_polygon(poly, cols)


func _draw_treeline() -> void:
	## Bumpy forest polygon, dips toward the centre so the menu panel is clear.
	var col_top  := Color(0.11, 0.20, 0.09, 1.0)
	var col_base := Color(0.09, 0.16, 0.07, 1.0)
	var steps    := 120
	var poly     := PackedVector2Array()
	poly.append(Vector2(0.0, HORIZ + 80.0))
	for i in range(steps + 1):
		var x   := W * i / steps
		## Base treeline height — tall at edges, low in centre
		var centre_dip := 1.0 - exp(-pow((x - W * 0.5) / (W * 0.18), 2.0)) * 0.55
		var tree_h: float = maxf((sin(x * 0.018 + 0.5) * 30.0 + abs(sin(x * 0.057 + 1.2)) * 45.0
			+ abs(sin(x * 0.031 + 2.8)) * 28.0) * centre_dip, 2.0)
		poly.append(Vector2(x, HORIZ + 80.0 - tree_h))
	poly.append(Vector2(W, HORIZ + 80.0))
	var cols := PackedColorArray()
	cols.resize(poly.size())
	for i in range(poly.size()):
		var frac := float(i) / float(poly.size())
		cols[i] = col_top.lerp(col_base, frac * 0.5)
	draw_polygon(poly, cols)


func _draw_ground() -> void:
	## Flat grass field from treeline base to bottom of screen.
	var grass_light := Color(0.13, 0.22, 0.10, 1.0)
	var grass_dark  := Color(0.08, 0.14, 0.06, 1.0)
	var ground_y    := HORIZ + 80.0
	draw_polygon(
		PackedVector2Array([
			Vector2(0,   ground_y), Vector2(W, ground_y),
			Vector2(W,   H),        Vector2(0, H)]),
		PackedColorArray([grass_light, grass_light, grass_dark, grass_dark]))


func _draw_center_glow() -> void:
	## Warm radial bloom behind the menu panel to draw the eye.
	var cx := W * 0.5
	var cy := H * 0.50
	## Layers from outer to inner: large dim → small bright
	var layers := [
		[480.0, 260.0, Color(0.60, 0.40, 0.10, 0.04)],
		[340.0, 190.0, Color(0.65, 0.45, 0.12, 0.07)],
		[240.0, 140.0, Color(0.70, 0.52, 0.15, 0.10)],
		[160.0,  90.0, Color(0.75, 0.58, 0.18, 0.12)],
		[ 90.0,  50.0, Color(0.80, 0.65, 0.22, 0.10)],
	]
	for layer in layers:
		draw_ellipse_aa(Vector2(cx, cy), float(layer[0]), float(layer[1]), layer[2] as Color)


func _draw_towers() -> void:
	for i in range(TOWERS.size()):
		var cfg: Array = TOWERS[i]
		var bx:  float = cfg[0]
		var by:  float = cfg[1]
		var t:   int   = cfg[2]
		## Gentle independent bob per tower
		var bob := sin(_time * 0.68 + i * 1.57) * 3.0
		## Centre tower slightly smaller and more transparent (distant feel)
		var sc  := 0.75 if i == 4 else 1.0
		var al  := 0.70 if i == 4 else 0.88
		_draw_tower_silhouette(bx, by + bob, t, sc, al)


## Draw a single procedural tower silhouette — no texture tiles, no seams.
func _draw_tower_silhouette(cx: float, base_y: float, t: int, sc: float, al: float) -> void:
	var col_wall  := Color(0.28, 0.32, 0.38, al)
	var col_edge  := Color(0.40, 0.46, 0.54, al)
	var col_top   := Color(0.50, 0.58, 0.68, al)
	var col_base  := Color(0.22, 0.26, 0.32, al)

	if t == 0:
		## Round tower: narrower body, rounded battlement
		var bw := 36.0 * sc   ## body width
		var bh := 110.0 * sc  ## body height
		## Base platform
		draw_rect(Rect2(cx - bw * 0.75, base_y - 12.0 * sc, bw * 1.5, 12.0 * sc), col_base)
		## Tower body
		draw_rect(Rect2(cx - bw * 0.5, base_y - bh, bw, bh), col_wall)
		## Subtle edge highlight
		draw_rect(Rect2(cx - bw * 0.5, base_y - bh, 3.0 * sc, bh), col_edge)
		## Battlements (3 merlons)
		var merlon_w := bw / 3.5
		for m in range(3):
			var mx := cx - bw * 0.5 + m * (bw / 2.5)
			draw_rect(Rect2(mx, base_y - bh - 14.0 * sc, merlon_w, 14.0 * sc), col_top)
		## Embrasure fill between merlons
		draw_rect(Rect2(cx - bw * 0.5, base_y - bh - 7.0 * sc, bw, 7.0 * sc), col_wall)
	else:
		## Square tower: wider, blocky, with a flat cap and side flanges
		var bw := 42.0 * sc
		var bh := 120.0 * sc
		## Base platform
		draw_rect(Rect2(cx - bw * 0.80, base_y - 14.0 * sc, bw * 1.6, 14.0 * sc), col_base)
		## Tower body
		draw_rect(Rect2(cx - bw * 0.5, base_y - bh, bw, bh), col_wall)
		## Edge highlights
		draw_rect(Rect2(cx - bw * 0.5, base_y - bh, 4.0 * sc, bh), col_edge)
		draw_rect(Rect2(cx + bw * 0.5 - 4.0 * sc, base_y - bh, 4.0 * sc, bh), col_edge)
		## Cap / roof block
		draw_rect(Rect2(cx - bw * 0.62, base_y - bh - 16.0 * sc, bw * 1.24, 16.0 * sc), col_top)
		## Cannon stub on top
		draw_rect(Rect2(cx - 6.0 * sc, base_y - bh - 28.0 * sc, 12.0 * sc, 14.0 * sc),
			Color(0.35, 0.40, 0.48, al))


func _draw_ufos() -> void:
	for u in _ufos:
		if not _tex.has(u.tex):
			continue
		var tex: Texture2D = _tex[u.tex]
		var sc: float  = u.sc
		var tw  := tex.get_width()  * sc
		var th  := tex.get_height() * sc
		var bob := sin(_time * 1.4 + float(u.y) * 0.015) * 5.0
		draw_texture_rect(tex,
			Rect2(float(u.x) - tw * 0.5, float(u.y) + bob - th * 0.5, tw, th),
			false, Color(1.0, 1.0, 1.0, float(u.a)))


func _draw_vignette() -> void:
	## Smooth gradient dark border focuses attention on the centre.
	var D := 380.0
	## Left
	draw_polygon(
		PackedVector2Array([Vector2(0,0), Vector2(D,0), Vector2(D,H), Vector2(0,H)]),
		PackedColorArray([Color(0,0,0,0.82), Color(0,0,0,0), Color(0,0,0,0), Color(0,0,0,0.82)]))
	## Right
	draw_polygon(
		PackedVector2Array([Vector2(W-D,0), Vector2(W,0), Vector2(W,H), Vector2(W-D,H)]),
		PackedColorArray([Color(0,0,0,0), Color(0,0,0,0.82), Color(0,0,0,0.82), Color(0,0,0,0)]))
	## Top
	draw_polygon(
		PackedVector2Array([Vector2(0,0), Vector2(W,0), Vector2(W,D*0.5), Vector2(0,D*0.5)]),
		PackedColorArray([Color(0,0,0,0.55), Color(0,0,0,0.55), Color(0,0,0,0), Color(0,0,0,0)]))
	## Bottom
	draw_polygon(
		PackedVector2Array([Vector2(0,H-D*0.5), Vector2(W,H-D*0.5), Vector2(W,H), Vector2(0,H)]),
		PackedColorArray([Color(0,0,0,0), Color(0,0,0,0), Color(0,0,0,0.55), Color(0,0,0,0.55)]))
