## RangeCircle — shows exactly which grid cells a tower can target.
##
## Draws:
##   • Filled tinted highlight on every in-range cell (crisp grid-cell squares)
##   • Solid circle outline at the true range boundary
##   • Animated expanding pulse ring
##
## The grid-cell approach eliminates the "is this cell in range?" ambiguity.
extends Node2D

const TILE_SIZE   : float   = 64.0
const GRID_COLS   : int     = 23
const GRID_ROWS   : int     = 13
const GRID_OFFSET : Vector2 = Vector2(48.0, 64.0)

var _radius : float = 150.0
var _color  : Color = Color(1.0, 1.0, 1.0, 1.0)
var _time   : float = 0.0

## Pre-computed cell rects (local space) that fall within _radius.
var _cell_rects : Array[Rect2] = []


func set_radius(r: float) -> void:
	_radius = r
	_rebuild_cells()
	queue_redraw()


func set_color(c: Color) -> void:
	_color = c
	queue_redraw()


## Recompute which grid cells are within range (cell center must be inside circle).
func _rebuild_cells() -> void:
	_cell_rects.clear()
	if get_parent() == null:
		return

	## Tower world position → grid cell of this tower
	var tower_world: Vector2 = (get_parent() as Node2D).global_position
	var tower_col := int((tower_world.x - GRID_OFFSET.x) / TILE_SIZE)
	var tower_row := int((tower_world.y - GRID_OFFSET.y) / TILE_SIZE)

	var reach := int(ceil(_radius / TILE_SIZE)) + 1
	for dc in range(-reach, reach + 1):
		for dr in range(-reach, reach + 1):
			var col := tower_col + dc
			var row := tower_row + dr
			if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
				continue
			## Cell center in local (tower) space
			var cx := dc * TILE_SIZE
			var cy := dr * TILE_SIZE
			if Vector2(cx, cy).length() <= _radius:
				_cell_rects.append(Rect2(
					cx - TILE_SIZE * 0.5, cy - TILE_SIZE * 0.5,
					TILE_SIZE, TILE_SIZE))


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	if not visible:
		return

	var fill_col    := Color(_color.r, _color.g, _color.b, 0.13)
	var border_col  := Color(_color.r, _color.g, _color.b, 0.30)
	var outline_col := Color(_color.r, _color.g, _color.b, 0.90)

	## ── Cell highlights ──────────────────────────────────────────────────
	for rect: Rect2 in _cell_rects:
		## Filled tint
		draw_rect(rect, fill_col)
		## Per-cell inner border (1px inset so borders don't double up)
		var inset := 1.0
		var ir := Rect2(rect.position + Vector2(inset, inset),
			rect.size - Vector2(inset * 2.0, inset * 2.0))
		draw_rect(ir, border_col, false, 1.0)

	## ── Circle outline at true radius boundary ───────────────────────────
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 72, outline_col, 2.0, true)

	## ── Animated expanding pulse ring ────────────────────────────────────
	var phase := fmod(_time * 1.2, 1.0)
	var pr    := _radius * (0.60 + phase * 0.40)
	var pa    := outline_col.a * (1.0 - phase) * 0.45
	draw_arc(Vector2.ZERO, pr, 0.0, TAU, 56,
		Color(_color.r, _color.g, _color.b, pa), 1.5, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		var tower := get_parent()
		if "current_range" in tower:
			set_radius(tower.current_range)
		if "glow_color" in tower:
			var gc: Color = tower.glow_color
			if gc.a > 0.0:
				set_color(gc)
		_rebuild_cells()
		queue_redraw()
