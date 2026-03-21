## WorldBackground — flat 2D top-down TD terrain.
##
## Everything is drawn procedurally in _draw() — no external sprites.
##   • Void   : dark strip outside grid
##   • Ground : dark-green buildable cells with grass-tuft and pebble decorations
##   • Shoulder: slightly lighter border framing the path
##   • Path   : warm sandy-brown road with edge shading and centre dashes
##   • Endpoints: coloured border highlight for spawn / goal cells
##
## All decoration positions are pre-generated once in setup() so _draw() is fast.
class_name WorldBackground
extends Node2D

const TILE_SIZE   : int     = 64
const GRID_COLS   : int     = 23
const GRID_ROWS   : int     = 13
const GRID_OFFSET : Vector2 = Vector2(48.0, 64.0)

# ── Colour palette ────────────────────────────────────────────────────────────
const COL_VOID      := Color(0.08, 0.10, 0.14)
const COL_GROUND    := Color(0.15, 0.24, 0.12)    ## dark grass
const COL_GROUND_LT := Color(0.18, 0.28, 0.14)    ## lighter patch variation
const COL_SHOULDER  := Color(0.20, 0.30, 0.18)    ## path border
const COL_PATH      := Color(0.66, 0.52, 0.30)    ## sandy road (main)
const COL_PATH_DK   := Color(0.58, 0.46, 0.26)    ## road shadow stripe
const COL_PATH_EDGE := Color(0.46, 0.36, 0.18)    ## road kerb
const COL_PATH_DASH := Color(0.76, 0.62, 0.38)    ## centre dash
const COL_GRID      := Color(0.0, 0.0, 0.0, 0.07) ## faint buildable grid
const COL_TUFT_A    := Color(0.12, 0.20, 0.09)    ## grass tuft dark
const COL_TUFT_B    := Color(0.22, 0.34, 0.16)    ## grass tuft light
const COL_PEBBLE    := Color(0.30, 0.30, 0.28)    ## pebble grey
const COL_SPAWN_RING := Color(0.28, 0.85, 0.38, 1.0)
const COL_GOAL_RING  := Color(0.90, 0.26, 0.20, 1.0)

# ── Level state ───────────────────────────────────────────────────────────────
var _path_set:    Dictionary = {}
var _shoulder_set: Dictionary = {}
var _spawn_tile:  Vector2i
var _goal_tile:   Vector2i

# ── Pre-generated decoration data ─────────────────────────────────────────────
## Each entry: { pos: Vector2, kind: int, r: float }
##   kind 0 = grass tuft (dark rect pair)
##   kind 1 = pebble (grey circle)
##   kind 2 = light ground patch
var _deco: Array = []

var _rng := RandomNumberGenerator.new()


# ── Public API ────────────────────────────────────────────────────────────────

func setup(waypoints: Array[Vector2i]) -> void:
	if waypoints.is_empty():
		return
	_spawn_tile = waypoints[0]
	_goal_tile  = waypoints[waypoints.size() - 1]
	_build_sets(waypoints)
	_rng.seed = 5381 + waypoints.hash()
	_generate_deco()
	queue_redraw()


# ── Path / shoulder computation ───────────────────────────────────────────────

func _build_sets(waypoints: Array[Vector2i]) -> void:
	_path_set = {}
	for i in range(waypoints.size() - 1):
		var a := waypoints[i]
		var b := waypoints[i + 1]
		if a.y == b.y:
			for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
				_path_set[Vector2i(x, a.y)] = true
		else:
			for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
				_path_set[Vector2i(a.x, y)] = true

	_shoulder_set = {}
	for pt: Vector2i in _path_set:
		for d: Vector2i in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var nb := pt + d
			if not _path_set.has(nb):
				_shoulder_set[nb] = true


# ── Decoration pre-generation ─────────────────────────────────────────────────

func _generate_deco() -> void:
	_deco = []
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var tv := Vector2i(col, row)
			if _path_set.has(tv):
				continue
			var cx := GRID_OFFSET.x + col * TILE_SIZE
			var cy := GRID_OFFSET.y + row * TILE_SIZE

			# 1-3 grass tufts per non-path cell
			var n_tufts := _rng.randi_range(0, 2)
			for _i in range(n_tufts):
				var px := cx + _rng.randf_range(8.0, TILE_SIZE - 8.0)
				var py := cy + _rng.randf_range(8.0, TILE_SIZE - 8.0)
				_deco.append({ pos = Vector2(px, py), kind = 0,
					r = _rng.randf_range(2.5, 4.5) })

			# Occasional pebble cluster (shoulder cells excluded — too close to path)
			if not _shoulder_set.has(tv) and _rng.randf() < 0.10:
				var px := cx + _rng.randf_range(10.0, TILE_SIZE - 10.0)
				var py := cy + _rng.randf_range(10.0, TILE_SIZE - 10.0)
				_deco.append({ pos = Vector2(px, py), kind = 1,
					r = _rng.randf_range(2.0, 3.5) })

			# Occasional lighter ground patch for colour variation
			if _rng.randf() < 0.18:
				var px := cx + _rng.randf_range(4.0, TILE_SIZE - 4.0)
				var py := cy + _rng.randf_range(4.0, TILE_SIZE - 4.0)
				_deco.append({ pos = Vector2(px, py), kind = 2,
					r = _rng.randf_range(5.0, 10.0) })


# ── Main draw ─────────────────────────────────────────────────────────────────

func _draw() -> void:
	# -- Void background
	draw_rect(Rect2(0.0, 0.0, 1728.0, 960.0), COL_VOID)

	# -- Base cell fill
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var tv  := Vector2i(col, row)
			var rx  := GRID_OFFSET.x + col * TILE_SIZE
			var ry  := GRID_OFFSET.y + row * TILE_SIZE
			var rect := Rect2(rx, ry, float(TILE_SIZE), float(TILE_SIZE))

			if _path_set.has(tv):
				_draw_path_cell(rx, ry, col, row)
			elif _shoulder_set.has(tv):
				draw_rect(rect, COL_SHOULDER)
			else:
				draw_rect(rect, COL_GROUND)
				# subtle faint grid lines on buildable area only
				draw_line(Vector2(rx, ry), Vector2(rx + TILE_SIZE, ry), COL_GRID)
				draw_line(Vector2(rx, ry), Vector2(rx, ry + TILE_SIZE), COL_GRID)

	# -- Ground decorations (tufts / pebbles / patches)
	for d in _deco:
		match d.kind:
			0:   # grass tuft — two short dark strokes
				var p: Vector2 = d.pos
				var r: float   = d.r
				draw_rect(Rect2(p.x - r * 0.5, p.y - r, r, r * 2.2), COL_TUFT_A)
				draw_rect(Rect2(p.x + r * 0.2, p.y - r * 0.7, r * 0.8, r * 1.8),
					COL_TUFT_B)
			1:   # pebble — small grey circle
				draw_circle(d.pos, d.r, COL_PEBBLE)
				draw_circle(d.pos + Vector2(d.r * 1.6, d.r * 0.4), d.r * 0.7,
					COL_PEBBLE)
			2:   # ground colour patch — faint lighter oval
				draw_circle(d.pos, d.r,
					Color(COL_GROUND_LT.r, COL_GROUND_LT.g, COL_GROUND_LT.b, 0.55))

	# -- Endpoint highlights
	_draw_endpoint(_spawn_tile, COL_SPAWN_RING)
	_draw_endpoint(_goal_tile,  COL_GOAL_RING)


func _draw_path_cell(rx: float, ry: float, col: int, row: int) -> void:
	var ts := float(TILE_SIZE)
	# Base fill — alternating subtle stripe for texture
	var stripe := (col + row) % 2 == 0
	draw_rect(Rect2(rx, ry, ts, ts), COL_PATH_DK if stripe else COL_PATH)
	# Top and left edge shadow (kerb effect)
	draw_rect(Rect2(rx, ry, ts, 3.0),  COL_PATH_EDGE)
	draw_rect(Rect2(rx, ry, 3.0, ts),  COL_PATH_EDGE)
	# Centre dash line — only on horizontal or vertical runs
	# (drawn as a small bright rectangle at cell centre)
	var cx := rx + ts * 0.5
	var cy := ry + ts * 0.5
	draw_rect(Rect2(cx - 3.0, cy - 1.5, 6.0, 3.0), COL_PATH_DASH)


func _draw_endpoint(tv: Vector2i, col: Color) -> void:
	var rx  := GRID_OFFSET.x + tv.x * float(TILE_SIZE)
	var ry  := GRID_OFFSET.y + tv.y * float(TILE_SIZE)
	var ts  := float(TILE_SIZE)
	var inset := 3.0
	# Semi-transparent fill
	draw_rect(Rect2(rx + inset, ry + inset, ts - inset * 2, ts - inset * 2),
		Color(col.r, col.g, col.b, 0.18))
	# Bold border
	var bw := 3.0
	draw_rect(Rect2(rx + inset, ry + inset, ts - inset * 2, bw), col)
	draw_rect(Rect2(rx + inset, ry + ts - inset - bw, ts - inset * 2, bw), col)
	draw_rect(Rect2(rx + inset, ry + inset, bw, ts - inset * 2), col)
	draw_rect(Rect2(rx + ts - inset - bw, ry + inset, bw, ts - inset * 2), col)
	# Inner corner dots for a cleaner highlight feel
	draw_circle(Vector2(rx + inset + bw * 1.5, ry + inset + bw * 1.5), 2.5, col)
	draw_circle(Vector2(rx + ts - inset - bw * 1.5, ry + inset + bw * 1.5), 2.5, col)
	draw_circle(Vector2(rx + inset + bw * 1.5, ry + ts - inset - bw * 1.5), 2.5, col)
	draw_circle(Vector2(rx + ts - inset - bw * 1.5, ry + ts - inset - bw * 1.5), 2.5, col)
