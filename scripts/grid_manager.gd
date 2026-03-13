## GridManager — manages tile state and renders the grid overlay.
## Attach to a Node2D in GameWorld.
## Call setup(level_data) once after the scene loads.
class_name GridManager
extends Node2D

enum CellType {
	BUILDABLE,       ## Player can place a tower here
	PATH,            ## Enemy path — cannot build
	OCCUPIED,        ## Tower is placed here
}

## Visual colors for cell types
const COLOR_BUILDABLE := Color(0.24, 0.46, 0.18, 0.70)
const COLOR_PATH      := Color(0.66, 0.50, 0.26, 0.92)
const COLOR_OCCUPIED  := Color(0.14, 0.20, 0.58, 0.65)
const COLOR_HOVER     := Color(0.98, 0.92, 0.18, 0.50)
const COLOR_INVALID   := Color(0.88, 0.10, 0.10, 0.50)
const COLOR_GRID_LINE := Color(0.0, 0.0, 0.0, 0.12)

## Sandy gravel color for path texture dots
const COLOR_GRAVEL    := Color(0.38, 0.28, 0.12, 0.20)

const TILE_SIZE: int = 64
const GRID_COLS: int = 23
const GRID_ROWS: int = 13
const GRID_OFFSET: Vector2 = Vector2(48.0, 64.0)

## Amount of positional jitter applied to grid line endpoints (pixels)
const JITTER_AMT := 0.8

## 2D array [col][row] -> CellType
var _grid: Array[Array] = []
## Tile currently being hovered for placement preview
var _hover_tile: Vector2i = Vector2i(-1, -1)
## Whether placement mode is active (shows hover highlight)
var _placement_mode: bool = false
## Precomputed jitter offsets for each grid intersection (GRID_COLS+1 × GRID_ROWS+1)
var _jitter: Array[Array] = []


func _ready() -> void:
	_init_jitter()
	_init_grid()


## Precompute a stable set of small random offsets for every grid intersection point.
## Using a fixed seed ensures the wobbly look is consistent across redraws.
func _init_jitter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	_jitter = []
	for col in range(GRID_COLS + 1):
		var col_arr: Array = []
		for row in range(GRID_ROWS + 1):
			var jx := rng.randf_range(-JITTER_AMT, JITTER_AMT)
			var jy := rng.randf_range(-JITTER_AMT, JITTER_AMT)
			col_arr.append(Vector2(jx, jy))
		_jitter.append(col_arr)


## Initialize all cells as BUILDABLE
func _init_grid() -> void:
	_grid = []
	for col in range(GRID_COLS):
		var column: Array = []
		for row in range(GRID_ROWS):
			column.append(CellType.BUILDABLE)
		_grid.append(column)


## Called by GameWorld after loading level data.
## Marks all path tiles from waypoints.
func setup(waypoints: Array[Vector2i]) -> void:
	_init_jitter()
	_init_grid()
	_mark_path(waypoints)
	queue_redraw()


## Expand waypoint segments into individual path cells
func _mark_path(waypoints: Array[Vector2i]) -> void:
	for i in range(waypoints.size() - 1):
		var from := waypoints[i]
		var to   := waypoints[i + 1]
		# Horizontal segment
		if from.y == to.y:
			var min_x := mini(from.x, to.x)
			var max_x := maxi(from.x, to.x)
			for x in range(min_x, max_x + 1):
				_set_cell(x, from.y, CellType.PATH)
		# Vertical segment
		else:
			var min_y := mini(from.y, to.y)
			var max_y := maxi(from.y, to.y)
			for y in range(min_y, max_y + 1):
				_set_cell(from.x, y, CellType.PATH)


func _set_cell(col: int, row: int, type: CellType) -> void:
	if col >= 0 and col < GRID_COLS and row >= 0 and row < GRID_ROWS:
		_grid[col][row] = type


## Returns cell type at tile coordinates
func get_cell(tile: Vector2i) -> CellType:
	if not _is_valid_tile(tile):
		return CellType.PATH  # treat out-of-bounds as non-buildable
	return _grid[tile.x][tile.y]


## Returns true if a tower can be placed on this tile
func can_build(tile: Vector2i) -> bool:
	return get_cell(tile) == CellType.BUILDABLE


## Mark tile as occupied by a tower
func place_tower(tile: Vector2i) -> void:
	_set_cell(tile.x, tile.y, CellType.OCCUPIED)
	queue_redraw()


## Mark tile as buildable again (tower sold/removed)
func remove_tower(tile: Vector2i) -> void:
	_set_cell(tile.x, tile.y, CellType.BUILDABLE)
	queue_redraw()


## Convert world position to tile coordinates
func world_to_tile(world_pos: Vector2) -> Vector2i:
	var local_pos := world_pos - GRID_OFFSET
	var col := int(local_pos.x) / TILE_SIZE
	var row := int(local_pos.y) / TILE_SIZE
	return Vector2i(col, row)


## Convert tile coordinates to world position (center of tile)
func tile_to_world(tile: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(
		tile.x * TILE_SIZE + TILE_SIZE * 0.5,
		tile.y * TILE_SIZE + TILE_SIZE * 0.5
	)


## Set placement hover tile (call from GameWorld on mouse move)
func set_hover(tile: Vector2i, valid: bool) -> void:
	_placement_mode = true
	_hover_tile = tile
	queue_redraw()


func clear_hover() -> void:
	_placement_mode = false
	_hover_tile = Vector2i(-1, -1)
	queue_redraw()


func _is_valid_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < GRID_COLS and tile.y >= 0 and tile.y < GRID_ROWS


## Return the jittered world position for a grid intersection point (col, row).
## col is in [0..GRID_COLS], row is in [0..GRID_ROWS].
func _jitter_pt(col: int, row: int) -> Vector2:
	var base := Vector2(
		GRID_OFFSET.x + col * TILE_SIZE,
		GRID_OFFSET.y + row * TILE_SIZE
	)
	if _jitter.is_empty():
		return base
	return base + _jitter[col][row]


## Draw the visual grid with a hand-drawn aesthetic.
func _draw() -> void:
	# ── 1. Fill cell backgrounds ────────────────────────────────────────────
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var rx: float = GRID_OFFSET.x + col * TILE_SIZE
			var ry: float = GRID_OFFSET.y + row * TILE_SIZE
			var rect := Rect2(rx, ry, TILE_SIZE, TILE_SIZE)
			var cell_type: CellType = _grid[col][row]
			var color: Color
			match cell_type:
				CellType.PATH:     color = COLOR_PATH
				CellType.OCCUPIED: color = COLOR_OCCUPIED
				_:                 color = COLOR_BUILDABLE
			draw_rect(rect, color)

			# ── 1a. Subtle paper-card depth shading ─────────────────────
			# Top edge — brighter highlight (light comes from top-left)
			var top_highlight := Color(color.r + 0.05, color.g + 0.05, color.b + 0.05, 0.12)
			draw_line(Vector2(rx, ry), Vector2(rx + TILE_SIZE, ry), top_highlight, 1.0)
			# Left edge — brighter highlight
			draw_line(Vector2(rx, ry), Vector2(rx, ry + TILE_SIZE), top_highlight, 1.0)
			# Bottom edge — darker shadow
			var bot_shadow := Color(color.r - 0.05, color.g - 0.05, color.b - 0.05, 0.10)
			draw_line(
				Vector2(rx, ry + TILE_SIZE),
				Vector2(rx + TILE_SIZE, ry + TILE_SIZE),
				bot_shadow, 1.0
			)
			# Right edge — darker shadow
			draw_line(
				Vector2(rx + TILE_SIZE, ry),
				Vector2(rx + TILE_SIZE, ry + TILE_SIZE),
				bot_shadow, 1.0
			)

			# ── 1b. Path cell gravel texture (tiny dots) ─────────────────
			if cell_type == CellType.PATH:
				# Five fixed sub-cell positions (relative to cell top-left),
				# chosen to look like scattered gravel without being random per frame.
				const GRAVEL_OFFSETS: Array = [
					Vector2(14.0, 18.0),
					Vector2(44.0, 12.0),
					Vector2(28.0, 38.0),
					Vector2(52.0, 46.0),
					Vector2( 8.0, 52.0),
				]
				const GRAVEL_RADII: Array = [2.0, 1.5, 1.8, 1.5, 2.0]
				for dot_i in range(5):
					var dot_pos: Vector2 = Vector2(rx, ry) + (GRAVEL_OFFSETS[dot_i] as Vector2)
					draw_circle(dot_pos, GRAVEL_RADII[dot_i] as float, COLOR_GRAVEL)

	# ── 2. Hover highlight ───────────────────────────────────────────────────
	if _placement_mode and _is_valid_tile(_hover_tile):
		var rect := Rect2(
			GRID_OFFSET.x + _hover_tile.x * TILE_SIZE,
			GRID_OFFSET.y + _hover_tile.y * TILE_SIZE,
			TILE_SIZE, TILE_SIZE
		)
		var hover_color := COLOR_HOVER if can_build(_hover_tile) else COLOR_INVALID
		draw_rect(rect, hover_color)

	# ── 3. Hand-drawn wobbly grid lines ─────────────────────────────────────
	# Each line is split into individual cell-length segments.
	# Endpoints use precomputed jitter offsets to create a hand-drawn wobble.
	#
	# Vertical lines: for each column divider, draw GRID_ROWS segments.
	for col in range(GRID_COLS + 1):
		for row in range(GRID_ROWS):
			var pt_top := _jitter_pt(col, row)
			var pt_bot := _jitter_pt(col, row + 1)
			draw_line(pt_top, pt_bot, COLOR_GRID_LINE, 1.0)

	# Horizontal lines: for each row divider, draw GRID_COLS segments.
	for row in range(GRID_ROWS + 1):
		for col in range(GRID_COLS):
			var pt_left  := _jitter_pt(col,     row)
			var pt_right := _jitter_pt(col + 1, row)
			draw_line(pt_left, pt_right, COLOR_GRID_LINE, 1.0)
