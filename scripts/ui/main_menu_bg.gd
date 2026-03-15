## MainMenuBg — animated decorative background for the main menu.
## Draws a full-viewport tiled grass world with Kenney sprites,
## decorative tower stacks on the flanks, and patrolling enemy UFOs.
class_name MainMenuBg
extends Node2D

const BASE      := "res://assets/kenney_tower-defense-kit/Previews/"
const TILE      := 64
const COLS      := 27   ## ceil(1728 / 64)
const ROWS      := 15   ## ceil(960  / 64)
const BG_GRASS  := Color(0.16, 0.28, 0.12, 1.0)

## Decorative tower config: [col, row, type]  0=round-a  1=square-b
const TOWER_CFG := [
	[1,  3,  0],
	[2,  9,  1],
	[24, 2,  1],
	[25, 8,  0],
	[25, 12, 1],
]

var _tex:  Dictionary = {}
var _grid: Array      = []   ## [col][row] → key string
var _ufos: Array      = []
var _time: float      = 0.0


func _ready() -> void:
	_load_tex()
	_build_grid()
	_spawn_ufos()


func _load_tex() -> void:
	var names: Array[String] = [
		"tile", "tile-bump", "tile-rock", "tile-tree",
		"tower-round-bottom-a", "tower-round-middle-a", "tower-round-top-a",
		"tower-square-bottom-b", "tower-square-middle-b", "tower-square-top-b",
		"enemy-ufo-a", "enemy-ufo-b", "enemy-ufo-c", "enemy-ufo-d",
	]
	for n in names:
		var p := BASE + n + ".png"
		if ResourceLoader.exists(p):
			_tex[n] = load(p)


func _build_grid() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99991

	# Cells directly under tower stacks → plain tile so towers sit cleanly
	var reserved: Dictionary = {}
	for cfg in TOWER_CFG:
		for dy in range(-2, 4):
			reserved[Vector2i(cfg[0], cfg[1] + dy)] = true

	_grid = []
	for col in range(COLS):
		var col_arr: Array = []
		for row in range(ROWS):
			if reserved.has(Vector2i(col, row)):
				col_arr.append("tile")
			else:
				var r := rng.randf()
				if   r < 0.58: col_arr.append("tile")
				elif r < 0.74: col_arr.append("tile-bump")
				elif r < 0.88: col_arr.append("tile-rock")
				else:          col_arr.append("tile-tree")
		_grid.append(col_arr)


func _spawn_ufos() -> void:
	_ufos = [
		{x =  380.0, y = 148.0, spd =  40.0, tex = "enemy-ufo-a", sc = 0.58, a = 0.50},
		{x = 1640.0, y = 330.0, spd = -48.0, tex = "enemy-ufo-b", sc = 0.46, a = 0.42},
		{x =  120.0, y = 570.0, spd =  55.0, tex = "enemy-ufo-c", sc = 0.66, a = 0.55},
		{x = 1500.0, y = 770.0, spd = -34.0, tex = "enemy-ufo-d", sc = 0.52, a = 0.38},
	]


func _process(delta: float) -> void:
	_time += delta
	for u in _ufos:
		u.x += float(u.spd) * delta
		if u.spd > 0 and u.x >  1880.0: u.x = -130.0
		if u.spd < 0 and u.x < -180.0:  u.x =  1880.0
	queue_redraw()


func _draw() -> void:
	_draw_tiles()
	_draw_towers()
	_draw_ufos()
	_draw_vignette()


func _draw_tiles() -> void:
	for col in range(COLS):
		for row in range(ROWS):
			var key: String = _grid[col][row]
			var ox := float(col * TILE)
			var oy := float(row * TILE)
			draw_rect(Rect2(ox, oy, TILE, TILE), BG_GRASS)
			if _tex.has(key):
				draw_texture(_tex[key], Vector2(ox, oy))


func _draw_towers() -> void:
	for cfg in TOWER_CFG:
		var col: int = cfg[0]
		var row: int = cfg[1]
		var t:   int = cfg[2]
		var bk := "tower-round-bottom-a" if t == 0 else "tower-square-bottom-b"
		var mk := "tower-round-middle-a" if t == 0 else "tower-square-middle-b"
		var tk := "tower-round-top-a"    if t == 0 else "tower-square-top-b"
		# Gentle idle bob
		var bob := sin(_time * 0.75 + col * 1.3) * 2.5
		var ox  := float(col * TILE)
		var oy  := float(row * TILE) + bob
		if _tex.has(bk): draw_texture(_tex[bk], Vector2(ox, oy))
		if _tex.has(mk): draw_texture(_tex[mk], Vector2(ox, oy - 64.0))
		if _tex.has(tk): draw_texture(_tex[tk], Vector2(ox, oy - 128.0))


func _draw_ufos() -> void:
	for u in _ufos:
		if not _tex.has(u.tex):
			continue
		var tex: Texture2D = _tex[u.tex]
		var sc: float  = u.sc
		var w  := tex.get_width()  * sc
		var h  := tex.get_height() * sc
		var bob := sin(_time * 1.6 + float(u.y) * 0.012) * 4.5
		draw_texture_rect(tex,
			Rect2(u.x - w * 0.5, float(u.y) + bob - h * 0.5, w, h),
			false, Color(1.0, 1.0, 1.0, float(u.a)))


func _draw_vignette() -> void:
	## Smooth gradient dark border to focus attention on the centre panel.
	## draw_polygon() supports per-vertex PackedColorArray for gradient fills.
	var W := 1728.0
	var H :=  960.0
	var D :=  420.0  ## vignette depth

	# Left gradient: dark at left edge, transparent at right
	draw_polygon(
		PackedVector2Array([Vector2(0,0), Vector2(D,0), Vector2(D,H), Vector2(0,H)]),
		PackedColorArray([Color(0,0,0,0.78), Color(0,0,0,0), Color(0,0,0,0), Color(0,0,0,0.78)]))
	# Right gradient: transparent at left, dark at right edge
	draw_polygon(
		PackedVector2Array([Vector2(W-D,0), Vector2(W,0), Vector2(W,H), Vector2(W-D,H)]),
		PackedColorArray([Color(0,0,0,0), Color(0,0,0,0.78), Color(0,0,0,0.78), Color(0,0,0,0)]))
	# Top gradient: dark at top, transparent at bottom
	draw_polygon(
		PackedVector2Array([Vector2(0,0), Vector2(W,0), Vector2(W,D*0.45), Vector2(0,D*0.45)]),
		PackedColorArray([Color(0,0,0,0.50), Color(0,0,0,0.50), Color(0,0,0,0), Color(0,0,0,0)]))
	# Bottom gradient: transparent at top, dark at bottom edge
	draw_polygon(
		PackedVector2Array([Vector2(0,H-D*0.45), Vector2(W,H-D*0.45), Vector2(W,H), Vector2(0,H)]),
		PackedColorArray([Color(0,0,0,0), Color(0,0,0,0), Color(0,0,0,0.50), Color(0,0,0,0.50)]))
