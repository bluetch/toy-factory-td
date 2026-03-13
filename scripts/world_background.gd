## WorldBackground — draws a tiled terrain background using world_tileset.png.
## Must be the first child of GameWorld (rendered beneath GridManager).
## Call setup(waypoints) from GameWorld after loading level data.
class_name WorldBackground
extends Node2D

const TILE_SIZE: int   = 64
const GRID_COLS: int   = 23
const GRID_ROWS: int   = 13
const GRID_OFFSET: Vector2 = Vector2(48.0, 64.0)

## Tile column index in world_tileset.png (each tile is 64×64):
## 0 = bright grass  1 = dark grass  2 = dirt path  3 = dark dirt
const TILE_GRASS      := 0
const TILE_DARK_GRASS := 1
const TILE_DIRT       := 2
const TILE_DARK_DIRT  := 3

var _tileset: Texture2D = null
## [col][row] → tile index
var _tiles: Array[Array] = []


func setup(waypoints: Array[Vector2i]) -> void:
	_tileset = load("res://assets/sprites/world/world_tileset.png")
	_build_tiles(waypoints)
	queue_redraw()


func _build_tiles(waypoints: Array[Vector2i]) -> void:
	# Mark path cells
	var path_set: Dictionary = {}
	for i in range(waypoints.size() - 1):
		var a := waypoints[i]
		var b := waypoints[i + 1]
		if a.y == b.y:
			for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
				path_set[Vector2i(x, a.y)] = true
		else:
			for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
				path_set[Vector2i(a.x, y)] = true

	var rng := RandomNumberGenerator.new()
	rng.seed = 7777

	_tiles = []
	for col in range(GRID_COLS):
		var column: Array = []
		for row in range(GRID_ROWS):
			var tile: int
			if path_set.has(Vector2i(col, row)):
				# ~70% bright dirt, ~30% dark dirt
				tile = TILE_DIRT if rng.randf() < 0.70 else TILE_DARK_DIRT
			else:
				# ~65% bright grass, ~35% dark grass
				tile = TILE_GRASS if rng.randf() < 0.65 else TILE_DARK_GRASS
			column.append(tile)
		_tiles.append(column)


func _draw() -> void:
	if _tileset == null or _tiles.is_empty():
		return
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var tile_idx: int = _tiles[col][row]
			var dest := Rect2(
				GRID_OFFSET.x + col * TILE_SIZE,
				GRID_OFFSET.y + row * TILE_SIZE,
				TILE_SIZE, TILE_SIZE
			)
			var src := Rect2(tile_idx * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
			draw_texture_rect_region(_tileset, dest, src)
