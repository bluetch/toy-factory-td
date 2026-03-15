## WorldBackground — draws a tiled terrain background using Kenney Tower Defense Kit sprites.
## Detects path direction per tile and uses appropriate sprite + rotation.
## Must be the first child of GameWorld (rendered beneath GridManager).
## Call setup(waypoints) from GameWorld after loading level data.
class_name WorldBackground
extends Node2D

const TILE_SIZE: int = 64
const HALF:      int = TILE_SIZE / 2
const GRID_COLS: int = 23
const GRID_ROWS: int = 13
const GRID_OFFSET: Vector2 = Vector2(48.0, 64.0)

const BASE := "res://assets/kenney_tower-defense-kit/Previews/"

## Tile-type enum stored per cell
enum TileType {
	GRASS, GRASS_BUMP, GRASS_TREE, GRASS_ROCK,
	PATH_H, PATH_V,
	CORNER_SE, CORNER_SW, CORNER_NE, CORNER_NW,
	SPAWN, GOAL
}

## Background fill colours (drawn first to fill transparent sprite edges)
const BG_GRASS := Color(0.17, 0.30, 0.13, 1.0)
const BG_PATH  := Color(0.35, 0.26, 0.16, 1.0)

## Texture cache (loaded in setup)
var _tex: Dictionary = {}

## [col][row] → {type: TileType, rot: float}  (rot in radians)
var _tiles: Array[Array] = []


# ── Public API ───────────────────────────────────────────────

func setup(waypoints: Array[Vector2i]) -> void:
	_load_textures()
	_build_tiles(waypoints)
	queue_redraw()


# ── Setup helpers ────────────────────────────────────────────

func _load_textures() -> void:
	var names := {
		TileType.GRASS:      "tile.png",
		TileType.GRASS_BUMP: "tile-bump.png",
		TileType.GRASS_TREE: "tile-tree.png",
		TileType.GRASS_ROCK: "tile-rock.png",
		TileType.PATH_H:     "tile-straight.png",
		TileType.PATH_V:     "tile-straight.png",   ## same sprite, rotated 90°
		TileType.CORNER_SE:  "tile-corner-round.png",
		TileType.CORNER_SW:  "tile-corner-round.png",
		TileType.CORNER_NE:  "tile-corner-round.png",
		TileType.CORNER_NW:  "tile-corner-round.png",
		TileType.SPAWN:      "tile-spawn.png",
		TileType.GOAL:       "tile-end.png",
	}
	for k in names:
		var path: String = BASE + names[k]
		if ResourceLoader.exists(path):
			_tex[k] = load(path)


func _build_tiles(waypoints: Array[Vector2i]) -> void:
	if waypoints.is_empty():
		return

	# ── 1. Collect path info per tile ──────────────────────
	# path_dirs[tile] = set of directions that have a path neighbour
	var path_dirs: Dictionary = {}  ## Vector2i → Dictionary{dir: true}

	for i in range(waypoints.size() - 1):
		var a := waypoints[i]
		var b := waypoints[i + 1]
		if a.y == b.y:          ## horizontal segment
			for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
				var t := Vector2i(x, a.y)
				if not path_dirs.has(t): path_dirs[t] = {}
				if x > mini(a.x, b.x): path_dirs[t][Vector2i(-1, 0)] = true
				if x < maxi(a.x, b.x): path_dirs[t][Vector2i( 1, 0)] = true
		else:                   ## vertical segment
			for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
				var t := Vector2i(a.x, y)
				if not path_dirs.has(t): path_dirs[t] = {}
				if y > mini(a.y, b.y): path_dirs[t][Vector2i(0, -1)] = true
				if y < maxi(a.y, b.y): path_dirs[t][Vector2i(0,  1)] = true

	# ── 2. Mark spawn / goal ───────────────────────────────
	var spawn_tile := waypoints[0]
	var goal_tile  := waypoints[waypoints.size() - 1]

	# ── 3. Build tile grid ─────────────────────────────────
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777

	_tiles = []
	for col in range(GRID_COLS):
		var column: Array = []
		for row in range(GRID_ROWS):
			var tv := Vector2i(col, row)
			if path_dirs.has(tv):
				column.append(_classify_path(tv, path_dirs[tv], spawn_tile, goal_tile))
			else:
				column.append(_random_grass(rng))
		_tiles.append(column)


func _classify_path(tv: Vector2i, dirs: Dictionary,
		spawn: Vector2i, goal: Vector2i) -> Dictionary:
	if tv == spawn:
		return {type = TileType.SPAWN, rot = 0.0}
	if tv == goal:
		return {type = TileType.GOAL, rot = 0.0}

	var has_e := dirs.has(Vector2i( 1,  0))
	var has_w := dirs.has(Vector2i(-1,  0))
	var has_s := dirs.has(Vector2i( 0,  1))
	var has_n := dirs.has(Vector2i( 0, -1))

	# Straight
	if (has_e or has_w) and not (has_n or has_s):
		return {type = TileType.PATH_H, rot = 0.0}
	if (has_n or has_s) and not (has_e or has_w):
		return {type = TileType.PATH_V, rot = PI * 0.5}

	# Corners  (tile-corner-round.png default = SE corner: enters from W, exits to S)
	if has_e and has_s:  return {type = TileType.CORNER_SE, rot = 0.0}
	if has_s and has_w:  return {type = TileType.CORNER_SW, rot = PI * 0.5}
	if has_w and has_n:  return {type = TileType.CORNER_NW, rot = PI}
	if has_n and has_e:  return {type = TileType.CORNER_NE, rot = PI * 1.5}

	# Fallback: treat as horizontal
	return {type = TileType.PATH_H, rot = 0.0}


func _random_grass(rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randf()
	var t: TileType
	if r < 0.65:  t = TileType.GRASS
	elif r < 0.80: t = TileType.GRASS_BUMP
	elif r < 0.90: t = TileType.GRASS_ROCK
	else:          t = TileType.GRASS_TREE
	return {type = t, rot = 0.0}


# ── Drawing ──────────────────────────────────────────────────

func _draw() -> void:
	if _tiles.is_empty():
		return
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var cell: Dictionary = _tiles[col][row]
			var cell_type: TileType = cell.type
			var ox: float = GRID_OFFSET.x + col * TILE_SIZE
			var oy: float = GRID_OFFSET.y + row * TILE_SIZE

			# Background fill (covers transparent sprite edges)
			var is_path := cell_type not in [
				TileType.GRASS, TileType.GRASS_BUMP,
				TileType.GRASS_TREE, TileType.GRASS_ROCK
			]
			var bg := BG_PATH if is_path else BG_GRASS
			draw_rect(Rect2(ox, oy, TILE_SIZE, TILE_SIZE), bg)

			# Sprite
			if not _tex.has(cell_type):
				continue
			var tex: Texture2D = _tex[cell_type]
			var rot: float = cell.rot
			if rot == 0.0:
				draw_texture(tex, Vector2(ox, oy))
			else:
				var center := Vector2(ox + HALF, oy + HALF)
				draw_set_transform(center, rot, Vector2.ONE)
				draw_texture(tex, Vector2(-HALF, -HALF))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
