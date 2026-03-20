## FactoryBase — the player's factory castle, drawn entirely procedurally.
## Two-tile wide, ~2.5 tiles tall. Flashes red-orange when hit.
## All geometry rendered in _draw(); no Sprite2D nodes needed.
class_name FactoryBase
extends Node2D

const FLASH_DURATION := 0.40

## ── Palette ──────────────────────────────────────────────────────────────────
const C_STONE    := Color(0.50, 0.46, 0.40)   ## warm grey stone
const C_STONE_DK := Color(0.32, 0.29, 0.24)   ## shadow / mortar
const C_STONE_LT := Color(0.68, 0.63, 0.55)   ## lit face highlight
const C_GATE     := Color(0.10, 0.08, 0.06)   ## gate interior / dark arch
const C_WIN_GLOW := Color(0.97, 0.82, 0.38)   ## warm lantern window
const C_GOLD     := Color(0.88, 0.68, 0.20)   ## brass / gear accent
const C_SMOKE    := Color(0.72, 0.72, 0.72)   ## chimney smoke
const C_SHADOW   := Color(0.0,  0.0,  0.0, 0.22)  ## ground shadow

var _flash_timer: float = 0.0
var _smoke_phase: float = 0.0
var _pulse: float = 0.0   ## slow glow pulse for windows

func _ready() -> void:
	EventBus.enemy_reached_end.connect(_on_enemy_hit)

func _process(delta: float) -> void:
	_smoke_phase = fmod(_smoke_phase + delta * 0.75, 63.0)
	_pulse = fmod(_pulse + delta * 1.4, TAU)
	if _flash_timer > 0.0:
		_flash_timer -= delta
	queue_redraw()

func _on_enemy_hit() -> void:
	_flash_timer = FLASH_DURATION

func _draw() -> void:
	var flash_t: float = clampf(_flash_timer / FLASH_DURATION, 0.0, 1.0)
	_draw_ground_shadow()
	_draw_structure(flash_t)
	_draw_windows(flash_t)
	_draw_emblem()
	_draw_smokestacks()
	if flash_t > 0.0:
		_draw_hit_burst(flash_t)
	else:
		_draw_smoke()

## ── Ground shadow ─────────────────────────────────────────────────────────────
func _draw_ground_shadow() -> void:
	for i in range(3):
		var r: float = 52.0 - float(i) * 8.0
		draw_ellipse_approx(Vector2(0, 8), r, 8.0,
				Color(0.0, 0.0, 0.0, C_SHADOW.a * (1.0 - float(i) / 3.0)))

func draw_ellipse_approx(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts: PackedVector2Array = []
	for i in range(21):
		var a := TAU * i / 20.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)

## ── Main structure ────────────────────────────────────────────────────────────
func _draw_structure(flash_t: float) -> void:
	var tint := _flash_tint(flash_t)

	## Left + right flanking turrets (drawn first so main body overlaps seam)
	_draw_turret(Vector2(-54, -80), 20.0, 80.0, tint)
	_draw_turret(Vector2( 54, -80), 20.0, 80.0, tint)

	## Main castle body
	draw_rect(Rect2(-40, -136, 80, 136), C_STONE * tint)
	draw_rect(Rect2(-40, -136,  8, 136), C_STONE_DK * tint)   ## left shadow
	draw_rect(Rect2( 32, -136,  8, 136), C_STONE_LT * tint)   ## right highlight

	## Horizontal mortar lines
	for y: int in [-34, -68, -102]:
		draw_line(Vector2(-40, y), Vector2(40, y), C_STONE_DK * tint, 1.5)

	## Battlements — 5 merlons across the top
	for i in range(5):
		var bx: float = -38.0 + float(i) * 20.0
		draw_rect(Rect2(bx, -152, 13, 18), C_STONE * tint)
		draw_rect(Rect2(bx, -152,  3, 18), C_STONE_DK * tint)

	## Gate arch
	draw_rect(Rect2(-16, -72, 32, 72), C_GATE)
	draw_circle(Vector2(0, -72), 16.0, C_GATE)
	draw_circle(Vector2(0, -72),  6.0, C_STONE_DK * Color(1, 1, 1, 0.4))

	## Gate frame edges
	draw_line(Vector2(-16, 0), Vector2(-16, -72), C_STONE_LT * tint, 2.0)
	draw_line(Vector2( 16, 0), Vector2( 16, -72), C_STONE_DK * tint, 2.0)

func _draw_turret(center: Vector2, hw: float, h: float, tint: Color) -> void:
	var x: float = center.x - hw
	var y: float = center.y
	draw_rect(Rect2(x, y, hw * 2.0, h), C_STONE * tint)
	draw_rect(Rect2(x,                   y, 5.0, h), C_STONE_DK * tint)
	draw_rect(Rect2(x + hw * 2.0 - 5.0, y, 5.0, h), C_STONE_LT * tint)
	draw_line(Vector2(x, y + h * 0.5), Vector2(x + hw * 2.0, y + h * 0.5),
			C_STONE_DK * tint, 1.0)
	## 3 merlons on turret top
	var step: float = (hw * 2.0) / 3.0
	for i in range(3):
		draw_rect(Rect2(x + float(i) * step + 1.0, y - 14.0, step - 3.0, 14.0),
				C_STONE * tint)

func _flash_tint(t: float) -> Color:
	if t <= 0.0:
		return Color.WHITE
	return Color(1.0 + t * 0.7, 1.0 - t * 0.65, 1.0 - t * 0.65)

## ── Windows ───────────────────────────────────────────────────────────────────
func _draw_windows(flash_t: float) -> void:
	var pulse_a: float = 0.75 + 0.25 * sin(_pulse)
	var glow_alpha: float = pulse_a if flash_t == 0.0 else 0.15

	for p: Vector2 in [Vector2(-22, -104), Vector2(0, -104), Vector2(22, -104)]:
		draw_circle(p + Vector2(0, -4), 10.0,
				Color(C_WIN_GLOW.r, C_WIN_GLOW.g, C_WIN_GLOW.b, 0.20 * glow_alpha))
		draw_rect(Rect2(p.x - 5, p.y - 10, 10, 14), C_GATE)
		draw_circle(p + Vector2(0, -10), 5.0, C_GATE)
		draw_circle(p + Vector2(0, -4),  4.5,
				Color(C_WIN_GLOW.r, C_WIN_GLOW.g, C_WIN_GLOW.b, 0.90 * glow_alpha))

	## Arrow slits on turrets
	for tx: float in [-54.0, 54.0]:
		draw_rect(Rect2(tx - 2, -52, 4, 14), C_GATE)

## ── Central emblem (gear cog) ─────────────────────────────────────────────────
func _draw_emblem() -> void:
	var c := Vector2(0, -82)
	draw_circle(c, 13.0, C_GOLD)
	draw_circle(c,  9.0, C_STONE_DK)
	draw_circle(c,  4.0, C_GOLD)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		draw_circle(c + Vector2(cos(a) * 13.0, sin(a) * 13.0), 3.5, C_GOLD)

## ── Smokestacks ───────────────────────────────────────────────────────────────
func _draw_smokestacks() -> void:
	for sx: float in [-22.0, 22.0]:
		draw_rect(Rect2(sx - 4, -164, 8, 30), C_STONE_DK)
		draw_rect(Rect2(sx - 5, -166, 10,  4), Color(0.45, 0.42, 0.38))

## ── Smoke ─────────────────────────────────────────────────────────────────────
func _draw_smoke() -> void:
	_draw_smoke_column(Vector2(-22, -168), _smoke_phase)
	_draw_smoke_column(Vector2( 22, -168), _smoke_phase + 1.5)

func _draw_smoke_column(origin: Vector2, phase: float) -> void:
	for k in range(4):
		var t: float      = fmod(phase + float(k) * 0.65, 2.6) / 2.6
		var rise: float   = t * 36.0
		var radius: float = 3.5 + t * 8.0
		var alpha: float  = 0.55 * (1.0 - t)
		draw_circle(origin + Vector2(sin(t * 4.0) * 5.0, -rise),
				radius, Color(C_SMOKE.r, C_SMOKE.g, C_SMOKE.b, alpha))

## ── Hit burst ─────────────────────────────────────────────────────────────────
func _draw_hit_burst(t: float) -> void:
	var ring_r: float = 20.0 + (1.0 - t) * 70.0
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32,
			Color(1.0, 0.45, 0.1, t * 0.7), 4.0)
	for p: Vector2 in [Vector2(-22, -168), Vector2(22, -168)]:
		draw_circle(p, 10.0 * t, Color(1.0, 0.35, 0.0, 0.75 * t))
		draw_circle(p,  5.0 * t, Color(1.0, 0.85, 0.2, 0.90 * t))
