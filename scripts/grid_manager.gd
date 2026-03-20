## GridManager — manages tile state and renders the grid overlay.
## Attach to a Node2D in GameWorld.
## Call setup(level_data) once after the scene loads.
## Uses Kenney selection-a/b.png sprites for hover and occupied indicators;
## the WorldBackground tile sprites show through for all other cells.
class_name GridManager
extends Node2D

enum CellType {
	BUILDABLE,       ## Player can place a tower here
	PATH,            ## Enemy path — cannot build
	OCCUPIED,        ## Tower is placed here
}

const BASE := "res://assets/kenney_tower-defense-kit/Previews/"

## Very faint grid lines — just enough to show tile boundaries
const COLOR_GRID_LINE := Color(0.0, 0.0, 0.0, 0.08)
## Blue tint drawn under the occupied sprite
const COLOR_OCCUPIED  := Color(0.18, 0.28, 0.70, 0.38)

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
## Whether the hover tile is a valid build location
var _hover_valid: bool = false
## Precomputed jitter offsets for each grid intersection
var _jitter: Array[Array] = []

## Kenney selection sprites loaded at startup
var _tex_sel_a: Texture2D = null  ## selection-a.png — placement hover ring
var _tex_sel_b: Texture2D = null  ## selection-b.png — occupied / built marker


func _ready() -> void:
	_load_textures()
	_init_jitter()
	_init_grid()


func _load_textures() -> void:
	var path_a := BASE + "selection-a.png"
	var path_b := BASE + "selection-b.png"
	if ResourceLoader.exists(path_a):
		_tex_sel_a = load(path_a)
	if ResourceLoader.exists(path_b):
		_tex_sel_b = load(path_b)


## Precompute a stable set of small random offsets for every grid intersection.
func _init_jitter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	_jitter = []
	for col in range(GRID_COLS + 1):
		var col_arr: Array = []
		for row in range(GRID_ROWS + 1):
			col_arr.append(Vector2(
				rng.randf_range(-JITTER_AMT, JITTER_AMT),
				rng.randf_range(-JITTER_AMT, JITTER_AMT)
			))
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
		if from.y == to.y:
			for x in range(mini(from.x, to.x), maxi(from.x, to.x) + 1):
				_set_cell(x, from.y, CellType.PATH)
		else:
			for y in range(mini(from.y, to.y), maxi(from.y, to.y) + 1):
				_set_cell(from.x, y, CellType.PATH)


func _set_cell(col: int, row: int, type: CellType) -> void:
	if col >= 0 and col < GRID_COLS and row >= 0 and row < GRID_ROWS:
		_grid[col][row] = type


## Returns cell type at tile coordinates
func get_cell(tile: Vector2i) -> CellType:
	if not _is_valid_tile(tile):
		return CellType.PATH
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
	return Vector2i(int(local_pos.x) / TILE_SIZE, int(local_pos.y) / TILE_SIZE)


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
	_hover_valid = valid
	queue_redraw()


func clear_hover() -> void:
	_placement_mode = false
	_hover_tile = Vector2i(-1, -1)
	queue_redraw()


func _is_valid_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < GRID_COLS and tile.y >= 0 and tile.y < GRID_ROWS


func _jitter_pt(col: int, row: int) -> Vector2:
	var base := Vector2(
		GRID_OFFSET.x + col * TILE_SIZE,
		GRID_OFFSET.y + row * TILE_SIZE
	)
	if _jitter.is_empty():
		return base
	return base + _jitter[col][row]


func _draw() -> void:
	var rect := Rect2(0.0, 0.0, float(TILE_SIZE), float(TILE_SIZE))

	# ── 1. Occupied cell markers (selection-b.png with blue tint) ───────────
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			if _grid[col][row] != CellType.OCCUPIED:
				continue
			var ox := GRID_OFFSET.x + col * TILE_SIZE
			var oy := GRID_OFFSET.y + row * TILE_SIZE
			rect.position = Vector2(ox, oy)
			if _tex_sel_b:
				draw_texture_rect(_tex_sel_b, rect, false,
					Color(0.45, 0.60, 1.0, 0.72))
			else:
				draw_rect(rect, COLOR_OCCUPIED)

	# ── 2. Hover / placement highlight ──────────────────────────────────────
	if _placement_mode and _is_valid_tile(_hover_tile):
		var ox := GRID_OFFSET.x + _hover_tile.x * TILE_SIZE
		var oy := GRID_OFFSET.y + _hover_tile.y * TILE_SIZE
		rect.position = Vector2(ox, oy)
		var is_path_cell: bool = _grid[_hover_tile.x][_hover_tile.y] == CellType.PATH
		if _tex_sel_a:
			var tint: Color
			if _hover_valid:
				tint = Color(0.40, 1.0, 0.40, 0.90)
			elif is_path_cell:
				tint = Color(1.0, 0.55, 0.05, 0.85)  # amber = "this is a path"
			else:
				tint = Color(1.0, 0.30, 0.30, 0.90)   # red = "occupied"
			draw_texture_rect(_tex_sel_a, rect, false, tint)
		else:
			var fb: Color
			if _hover_valid:
				fb = Color(0.35, 0.95, 0.35, 0.45)
			elif is_path_cell:
				fb = Color(1.0, 0.55, 0.05, 0.50)
			else:
				fb = Color(0.88, 0.10, 0.10, 0.50)
			draw_rect(rect, fb)
		# Draw X on invalid cells so the reason is unmistakable
		if not _hover_valid:
			var cx := ox + TILE_SIZE * 0.5
			var cy := oy + TILE_SIZE * 0.5
			var half := TILE_SIZE * 0.28
			var x_col := Color(1.0, 1.0, 1.0, 0.75)
			draw_line(Vector2(cx - half, cy - half), Vector2(cx + half, cy + half), x_col, 3.0)
			draw_line(Vector2(cx + half, cy - half), Vector2(cx - half, cy + half), x_col, 3.0)

	# ── 3. Grid lines — only shown in placement mode so terrain looks continuous ──
	if not _placement_mode:
		return
	for col in range(GRID_COLS + 1):
		for row in range(GRID_ROWS):
			var cell_type: CellType = _grid[mini(col, GRID_COLS - 1)][row]
			if cell_type == CellType.PATH:
				continue
			draw_line(_jitter_pt(col, row), _jitter_pt(col, row + 1),
				COLOR_GRID_LINE, 1.0)

	for row in range(GRID_ROWS + 1):
		for col in range(GRID_COLS):
			var cell_type: CellType = _grid[col][mini(row, GRID_ROWS - 1)]
			if cell_type == CellType.PATH:
				continue
			draw_line(_jitter_pt(col, row), _jitter_pt(col + 1, row),
				COLOR_GRID_LINE, 1.0)
