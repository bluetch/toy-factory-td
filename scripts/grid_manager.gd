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
const COLOR_BUILDABLE := Color(0.2, 0.5, 0.2, 0.5)
const COLOR_PATH      := Color(0.6, 0.5, 0.3, 0.8)
const COLOR_OCCUPIED  := Color(0.2, 0.2, 0.6, 0.5)
const COLOR_HOVER     := Color(1.0, 1.0, 0.3, 0.4)
const COLOR_INVALID   := Color(0.8, 0.1, 0.1, 0.4)
const COLOR_GRID_LINE := Color(0.0, 0.0, 0.0, 0.2)

const TILE_SIZE: int = 64
const GRID_COLS: int = 18
const GRID_ROWS: int = 10
const GRID_OFFSET: Vector2 = Vector2(64.0, 40.0)

## 2D array [col][row] -> CellType
var _grid: Array = []
## Tile currently being hovered for placement preview
var _hover_tile: Vector2i = Vector2i(-1, -1)
## Whether placement mode is active (shows hover highlight)
var _placement_mode: bool = false

func _ready() -> void:
	_init_grid()

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

## Draw the visual grid
func _draw() -> void:
	var grid_width  := GRID_COLS * TILE_SIZE
	var grid_height := GRID_ROWS * TILE_SIZE

	# Fill cell backgrounds
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var rect := Rect2(
				GRID_OFFSET.x + col * TILE_SIZE,
				GRID_OFFSET.y + row * TILE_SIZE,
				TILE_SIZE, TILE_SIZE
			)
			var cell_type: CellType = _grid[col][row]
			var color: Color
			match cell_type:
				CellType.PATH:     color = COLOR_PATH
				CellType.OCCUPIED: color = COLOR_OCCUPIED
				_:                 color = COLOR_BUILDABLE
			draw_rect(rect, color)

	# Hover highlight
	if _placement_mode and _is_valid_tile(_hover_tile):
		var rect := Rect2(
			GRID_OFFSET.x + _hover_tile.x * TILE_SIZE,
			GRID_OFFSET.y + _hover_tile.y * TILE_SIZE,
			TILE_SIZE, TILE_SIZE
		)
		var hover_color := COLOR_HOVER if can_build(_hover_tile) else COLOR_INVALID
		draw_rect(rect, hover_color)

	# Grid lines
	for col in range(GRID_COLS + 1):
		var x := GRID_OFFSET.x + col * TILE_SIZE
		draw_line(Vector2(x, GRID_OFFSET.y), Vector2(x, GRID_OFFSET.y + grid_height), COLOR_GRID_LINE)
	for row in range(GRID_ROWS + 1):
		var y := GRID_OFFSET.y + row * TILE_SIZE
		draw_line(Vector2(GRID_OFFSET.x, y), Vector2(GRID_OFFSET.x + grid_width, y), COLOR_GRID_LINE)
