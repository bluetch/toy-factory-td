## WorldBackground — industrial factory-floor map art.
## The path is drawn as a lighter concrete walkway with edge borders and
## centre-line dashes — no Kenney sprites (which carry grass elements).
## Non-path tiles use zone-specific procedural concrete/metal details.
class_name WorldBackground
extends Node2D

const TILE_SIZE: int = 64
const GRID_COLS: int = 23
const GRID_ROWS: int = 13
const GRID_OFFSET: Vector2 = Vector2(48.0, 64.0)

# ── Colour palette ──────────────────────────────────────────────────────────
const COL_VOID        := Color(0.06, 0.06, 0.08, 1.0)   ## dark void around map

## Floor zones
const COL_CONCRETE    := Color(0.68, 0.66, 0.62, 1.0)   ## standard concrete
const COL_METAL       := Color(0.54, 0.56, 0.60, 1.0)   ## metal plate (cool)
const COL_METAL_ALT   := Color(0.50, 0.52, 0.56, 1.0)   ## checkerboard alt
const COL_PROC        := Color(0.60, 0.66, 0.72, 1.0)   ## processing zone (blue tint)
const COL_CLEAN       := Color(0.76, 0.74, 0.70, 1.0)   ## clean assembly area
const COL_SHOULDER    := Color(0.63, 0.61, 0.57, 1.0)   ## path border strip

## Path
const COL_PATH        := Color(0.80, 0.78, 0.74, 1.0)   ## walkway — lighter than floor
const COL_PATH_EDGE   := Color(0.92, 0.90, 0.86, 0.80)  ## raised-edge highlight
const COL_PATH_DASH   := Color(0.92, 0.90, 0.86, 0.42)  ## centre-line dash

## Detail colours
const COL_SEAM        := Color(0.38, 0.37, 0.34, 0.30)  ## tile seam line
const COL_BOLT        := Color(0.36, 0.36, 0.38, 0.85)
const COL_BOLT_HI     := Color(0.76, 0.76, 0.74, 0.55)
const COL_TECH        := Color(0.38, 0.60, 0.88, 0.28)  ## processing traces

## Map border/shadow
const COL_SLAB_SHADOW := Color(0.0, 0.0, 0.0, 0.50)
const COL_SLAB_EDGE   := Color(0.58, 0.57, 0.54, 0.65)  ## bright top/left slab edge

## Markers
const COL_SPAWN_RING  := Color(0.32, 0.86, 0.40, 0.85)
const COL_GOAL_RING   := Color(0.90, 0.30, 0.26, 0.85)

enum ZoneType { STANDARD, METAL, PROCESSING, CLEAN, SHOULDER, PATH }

var _tiles:      Array[Array] = []
var _waypoints:  Array[Vector2i] = []
var _spawn_tile: Vector2i
var _goal_tile:  Vector2i
var _flow:       Dictionary = {}   ## Vector2i → Vector2i  (direction of enemy travel)


# ── Public API ───────────────────────────────────────────────────────────────

func setup(waypoints: Array[Vector2i]) -> void:
	_waypoints = waypoints
	_build_tiles(waypoints)
	queue_redraw()


# ── Build tile data ──────────────────────────────────────────────────────────

func _build_tiles(waypoints: Array[Vector2i]) -> void:
	if waypoints.is_empty():
		return
	_spawn_tile = waypoints[0]
	_goal_tile  = waypoints[waypoints.size() - 1]

	# ── 1. Path cells and flow direction ──
	var path_set: Dictionary = {}
	_flow = {}
	for i in range(waypoints.size() - 1):
		var a := waypoints[i]
		var b := waypoints[i + 1]
		var dir := Vector2i(sign(b.x - a.x), sign(b.y - a.y))
		if a.y == b.y:
			for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
				path_set[Vector2i(x, a.y)] = true
				_flow[Vector2i(x, a.y)]    = dir
		else:
			for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
				path_set[Vector2i(a.x, y)] = true
				_flow[Vector2i(a.x, y)]    = dir

	# ── 2. Shoulder cells (1 tile from path) ──
	var shoulder: Dictionary = {}
	for pt: Vector2i in path_set:
		for d: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var nb := pt + d
			if not path_set.has(nb):
				shoulder[nb] = true

	# ── 3. Assign zones ──
	var rng := RandomNumberGenerator.new()
	rng.seed = 5678
	_tiles = []
	for col in range(GRID_COLS):
		var column: Array = []
		for row in range(GRID_ROWS):
			var tv := Vector2i(col, row)
			if path_set.has(tv):
				column.append({z = ZoneType.PATH, rnd = 0})
			elif shoulder.has(tv):
				column.append({z = ZoneType.SHOULDER, rnd = rng.randi() % 4})
			else:
				column.append({z = _zone_at(col, row), rnd = rng.randi() % 4})
		_tiles.append(column)


func _zone_at(col: int, row: int) -> ZoneType:
	var fc := float(col)
	var fr := float(row)
	var metal_s := clampf((5.0 - fc - fr) / 5.0, 0.0, 1.0)
	var proc_s  := clampf(minf((fc - 17.0) / 5.0, (3.5 - fr) / 3.5), 0.0, 1.0)
	var clean_s := clampf(minf((fc - 14.0) / 8.0, (fr - 7.0) / 5.0), 0.0, 1.0)
	var best    := maxf(metal_s, maxf(proc_s, clean_s))
	if best < 0.25:     return ZoneType.STANDARD
	if metal_s == best: return ZoneType.METAL
	if proc_s  == best: return ZoneType.PROCESSING
	return ZoneType.CLEAN


func _is_path(col: int, row: int) -> bool:
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return false
	return _tiles[col][row].z == ZoneType.PATH


# ── Drawing ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	if _tiles.is_empty():
		return
	_draw_void_bg()
	_draw_slab_shadow()
	# Pass 1: base tile colours
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			_draw_tile_base(col, row)
	# Pass 2: tile detail (bolts, circuit traces, seams)
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			_draw_tile_detail(col, row)
	# Pass 3: path edge borders (raised-ledge highlight around walkway)
	_draw_path_edge_borders()
	# Pass 4: path centre-line dashes and markers
	_draw_path_centre_lines()
	_draw_spawn_goal_markers()


func _draw_void_bg() -> void:
	draw_rect(Rect2(0, 0, 1728, 960), COL_VOID)
	## Faint dot grid in the void — industrial environment feel
	var dot := Color(0.11, 0.11, 0.14, 1.0)
	for gx in range(0, 1728, 32):
		for gy in range(0, 960, 32):
			var in_grid: bool = (gx >= GRID_OFFSET.x - 2 and gx <= GRID_OFFSET.x + GRID_COLS * TILE_SIZE + 2
				and gy >= GRID_OFFSET.y - 2 and gy <= GRID_OFFSET.y + GRID_ROWS * TILE_SIZE + 2)
			if not in_grid:
				draw_rect(Rect2(gx - 1, gy - 1, 2, 2), dot)


func _draw_slab_shadow() -> void:
	var x0 := GRID_OFFSET.x
	var y0 := GRID_OFFSET.y
	var x1 := x0 + GRID_COLS * TILE_SIZE
	var y1 := y0 + GRID_ROWS * TILE_SIZE
	var d   := 12.0
	## Bottom shadow
	draw_polygon(
		PackedVector2Array([Vector2(x0+d,y1), Vector2(x1+d,y1), Vector2(x1+d,y1+d), Vector2(x0+d,y1+d)]),
		PackedColorArray([COL_SLAB_SHADOW, COL_SLAB_SHADOW, Color(0,0,0,0), Color(0,0,0,0)]))
	## Right shadow
	draw_polygon(
		PackedVector2Array([Vector2(x1,y0+d), Vector2(x1+d,y0+d), Vector2(x1+d,y1+d), Vector2(x1,y1+d)]),
		PackedColorArray([Color(0,0,0,0), COL_SLAB_SHADOW, COL_SLAB_SHADOW, Color(0,0,0,0)]))
	## Bright top/left slab edges
	draw_line(Vector2(x0, y0), Vector2(x1, y0), COL_SLAB_EDGE, 1.5)
	draw_line(Vector2(x0, y0), Vector2(x0, y1), COL_SLAB_EDGE, 1.5)


func _draw_tile_base(col: int, row: int) -> void:
	var cell: Dictionary = _tiles[col][row]
	var ox := GRID_OFFSET.x + col * TILE_SIZE
	var oy := GRID_OFFSET.y + row * TILE_SIZE
	var base: Color
	match cell.z:
		ZoneType.PATH:     base = COL_PATH
		ZoneType.SHOULDER: base = COL_SHOULDER
		ZoneType.METAL:    base = COL_METAL if (col + row) % 2 == 0 else COL_METAL_ALT
		ZoneType.PROCESSING: base = COL_PROC
		ZoneType.CLEAN:    base = COL_CLEAN
		_:                 base = COL_CONCRETE
	draw_rect(Rect2(ox, oy, TILE_SIZE, TILE_SIZE), base)


func _draw_tile_detail(col: int, row: int) -> void:
	var cell: Dictionary = _tiles[col][row]
	var ox := GRID_OFFSET.x + col * TILE_SIZE
	var oy := GRID_OFFSET.y + row * TILE_SIZE
	match cell.z:
		ZoneType.METAL:
			## Raised plate look: bright top-left, dark bottom-right edges
			draw_line(Vector2(ox,    oy),    Vector2(ox+TILE_SIZE, oy),    Color(0.70, 0.72, 0.76, 0.55), 1.5)
			draw_line(Vector2(ox,    oy),    Vector2(ox, oy+TILE_SIZE),    Color(0.70, 0.72, 0.76, 0.55), 1.5)
			draw_line(Vector2(ox,    oy+TILE_SIZE), Vector2(ox+TILE_SIZE, oy+TILE_SIZE), Color(0.28, 0.28, 0.30, 0.55), 1.5)
			draw_line(Vector2(ox+TILE_SIZE, oy),    Vector2(ox+TILE_SIZE, oy+TILE_SIZE), Color(0.28, 0.28, 0.30, 0.55), 1.5)
			_draw_bolts(ox, oy)
		ZoneType.PROCESSING:
			draw_rect(Rect2(ox, oy, TILE_SIZE, TILE_SIZE), COL_SEAM, false, 1.0)
			if cell.rnd <= 1:
				var ly := oy + TILE_SIZE * 0.5
				draw_line(Vector2(ox, ly), Vector2(ox+TILE_SIZE, ly), COL_TECH, 1.5)
				draw_circle(Vector2(ox + 16, ly), 2.5, COL_TECH)
				draw_circle(Vector2(ox + 48, ly), 2.5, COL_TECH)
			elif cell.rnd == 2:
				var lx := ox + TILE_SIZE * 0.5
				draw_line(Vector2(lx, oy), Vector2(lx, oy+TILE_SIZE), COL_TECH, 1.5)
				draw_circle(Vector2(lx, oy + 16), 2.5, COL_TECH)
				draw_circle(Vector2(lx, oy + 48), 2.5, COL_TECH)
			else:
				_draw_bolts(ox, oy)
		ZoneType.CLEAN:
			draw_rect(Rect2(ox, oy, TILE_SIZE, TILE_SIZE), COL_SEAM, false, 1.0)
			if cell.rnd == 0:
				var cx := ox + 32.0; var cy := oy + 32.0
				var cc := Color(0.52, 0.51, 0.48, 0.32)
				draw_line(Vector2(cx-7, cy), Vector2(cx+7, cy), cc, 1.0)
				draw_line(Vector2(cx, cy-7), Vector2(cx, cy+7), cc, 1.0)
		ZoneType.SHOULDER:
			draw_rect(Rect2(ox, oy, TILE_SIZE, TILE_SIZE), COL_SEAM, false, 1.0)
		ZoneType.STANDARD:
			draw_rect(Rect2(ox, oy, TILE_SIZE, TILE_SIZE), COL_SEAM, false, 1.0)
			if cell.rnd == 0:
				_draw_bolts(ox, oy)
		ZoneType.PATH:
			pass   ## path gets its own pass


func _draw_path_edge_borders() -> void:
	## For each path tile, draw a bright highlight on every edge that borders a non-path tile.
	## This creates a crisp "raised-ledge" outline that cleanly separates the walkway
	## from the surrounding factory floor without using any sprites.
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			if not _is_path(col, row):
				continue
			var ox := GRID_OFFSET.x + col * TILE_SIZE
			var oy := GRID_OFFSET.y + row * TILE_SIZE
			## Top edge
			if not _is_path(col, row - 1):
				draw_line(Vector2(ox, oy), Vector2(ox + TILE_SIZE, oy), COL_PATH_EDGE, 2.5)
			## Bottom edge
			if not _is_path(col, row + 1):
				draw_line(Vector2(ox, oy + TILE_SIZE), Vector2(ox + TILE_SIZE, oy + TILE_SIZE),
					COL_PATH_EDGE, 2.5)
			## Left edge
			if not _is_path(col - 1, row):
				draw_line(Vector2(ox, oy), Vector2(ox, oy + TILE_SIZE), COL_PATH_EDGE, 2.5)
			## Right edge
			if not _is_path(col + 1, row):
				draw_line(Vector2(ox + TILE_SIZE, oy), Vector2(ox + TILE_SIZE, oy + TILE_SIZE),
					COL_PATH_EDGE, 2.5)


func _draw_path_centre_lines() -> void:
	## Draw small dashes along the centre of straight path segments.
	## Corner cells are skipped — the edge treatment is enough there.
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			if not _is_path(col, row):
				continue
			var tv  := Vector2i(col, row)
			var dir := _flow.get(tv, Vector2i.ZERO) as Vector2i
			if dir == Vector2i.ZERO:
				continue
			var ox := GRID_OFFSET.x + col * TILE_SIZE
			var oy := GRID_OFFSET.y + row * TILE_SIZE
			var cx := ox + 32.0
			var cy := oy + 32.0
			var has_h: bool = _is_path(col - 1, row) or _is_path(col + 1, row)
			var has_v: bool = _is_path(col, row - 1) or _is_path(col, row + 1)
			## Only draw dashes on straight (non-corner) tiles
			if has_h and has_v:
				continue
			## 3 dashes per tile, evenly spaced
			var dash_w := 10.0
			var dash_h :=  3.0
			var spacing := 18.0
			if has_h:
				## Horizontal dashes
				for i in range(3):
					var dx := ox + 11.0 + i * spacing
					draw_rect(Rect2(dx, cy - dash_h * 0.5, dash_w, dash_h), COL_PATH_DASH)
			else:
				## Vertical dashes
				for i in range(3):
					var dy := oy + 11.0 + i * spacing
					draw_rect(Rect2(cx - dash_h * 0.5, dy, dash_h, dash_w), COL_PATH_DASH)


func _draw_spawn_goal_markers() -> void:
	_draw_marker(_spawn_tile, COL_SPAWN_RING, Color(0.20, 0.68, 0.28, 0.20))
	_draw_marker(_goal_tile,  COL_GOAL_RING,  Color(0.78, 0.20, 0.16, 0.20))


func _draw_marker(tile: Vector2i, ring_col: Color, fill_col: Color) -> void:
	var cx := GRID_OFFSET.x + tile.x * TILE_SIZE + 32.0
	var cy := GRID_OFFSET.y + tile.y * TILE_SIZE + 32.0
	## Radial fill
	var pts  := PackedVector2Array()
	var cols := PackedColorArray()
	pts.append(Vector2(cx, cy));  cols.append(fill_col)
	for i in range(33):
		var a := TAU * i / 32.0
		pts.append(Vector2(cx + cos(a) * 26, cy + sin(a) * 26))
		cols.append(Color(fill_col.r, fill_col.g, fill_col.b, 0.0))
	draw_polygon(pts, cols)
	## Outer ring
	draw_circle(Vector2(cx, cy), 26, ring_col, false, 2.5)
	## Inner dot
	draw_circle(Vector2(cx, cy), 6, ring_col)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _draw_bolts(ox: float, oy: float) -> void:
	var m := 7.0
	for c in [Vector2(ox+m, oy+m), Vector2(ox+TILE_SIZE-m, oy+m),
			  Vector2(ox+m, oy+TILE_SIZE-m), Vector2(ox+TILE_SIZE-m, oy+TILE_SIZE-m)]:
		draw_circle(c, 3.0, COL_BOLT)
		draw_circle(c - Vector2(0.8, 0.8), 1.2, COL_BOLT_HI)
