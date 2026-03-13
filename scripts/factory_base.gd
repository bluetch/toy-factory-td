## FactoryBase — the player's factory/castle that must be defended.
## Placed at the last path waypoint. Flashes red when an enemy reaches it.
## Pure visual — actual life loss is handled by GameManager via EventBus.
class_name FactoryBase
extends Node2D

const FLASH_DURATION := 0.35

var _flash_timer: float  = 0.0
var _smoke_phase: float  = 0.0   ## slowly animates smoke puffs


func _ready() -> void:
	EventBus.enemy_reached_end.connect(_on_enemy_hit)
	set_process(true)


func _process(delta: float) -> void:
	_smoke_phase += delta * 0.8
	if _flash_timer > 0.0:
		_flash_timer -= delta
	queue_redraw()


func _on_enemy_hit() -> void:
	_flash_timer = FLASH_DURATION


func _draw() -> void:
	var hit := _flash_timer > 0.0

	# ── Ground shadow ────────────────────────────────────────────────────────
	_draw_filled_ellipse(Vector2(0, 28), Vector2(52, 10), Color(0, 0, 0, 0.22))

	# ── Outer walls ──────────────────────────────────────────────────────────
	var wall := Color(0.40, 0.32, 0.24) if not hit else Color(0.65, 0.18, 0.10)
	# Main building body
	draw_rect(Rect2(-44, -34, 88, 62), wall)

	# Corner battlements (crenellations)
	var battlement := Color(wall.r * 0.85, wall.g * 0.85, wall.b * 0.85)
	for bx in [-44, -22, 0, 22]:
		draw_rect(Rect2(bx, -46, 18, 14), battlement)

	# ── Roof / parapet cap ───────────────────────────────────────────────────
	var roof := Color(0.30, 0.22, 0.16) if not hit else Color(0.50, 0.12, 0.08)
	draw_rect(Rect2(-46, -38, 92, 6), roof)

	# ── Windows ──────────────────────────────────────────────────────────────
	var win_glow := Color(0.95, 0.82, 0.30, 0.90) if not hit else Color(1.0, 0.28, 0.10, 0.95)
	draw_rect(Rect2(-34, -22, 16, 14), win_glow)
	draw_rect(Rect2(18, -22, 16, 14), win_glow)
	# Window frames
	var frame := Color(0.20, 0.14, 0.10)
	draw_rect(Rect2(-34, -22, 16, 14), frame, false, 1.5)
	draw_rect(Rect2(18, -22, 16, 14), frame, false, 1.5)

	# ── Central gate ─────────────────────────────────────────────────────────
	var gate_dark := Color(0.12, 0.08, 0.06)
	draw_rect(Rect2(-14, -2, 28, 30), gate_dark)
	# Gate arch (approximate with a rect + circle top)
	draw_circle(Vector2(0, -2), 14, gate_dark)

	# ── Chimneys / smokestacks ────────────────────────────────────────────────
	var chimney := Color(0.25, 0.18, 0.13) if not hit else Color(0.40, 0.12, 0.08)
	draw_rect(Rect2(-30, -62, 12, 28), chimney)
	draw_rect(Rect2(18,  -58, 12, 24), chimney)
	# Chimney rims
	draw_rect(Rect2(-32, -64, 16, 4), Color(chimney.r * 0.8, chimney.g * 0.8, chimney.b * 0.8))
	draw_rect(Rect2( 16, -60, 16, 4), Color(chimney.r * 0.8, chimney.g * 0.8, chimney.b * 0.8))

	# ── Animated smoke ────────────────────────────────────────────────────────
	if not hit:
		_draw_smoke(Vector2(-24, -66), _smoke_phase)
		_draw_smoke(Vector2( 24, -62), _smoke_phase + 1.2)
	else:
		# Fire/sparks when hit
		draw_circle(Vector2(-24, -68), 9, Color(1.0, 0.4, 0.0, 0.7))
		draw_circle(Vector2( 24, -64), 7, Color(1.0, 0.2, 0.0, 0.6))

	# ── Factory sign ─────────────────────────────────────────────────────────
	draw_rect(Rect2(-20, -14, 40, 10), Color(0.85, 0.75, 0.15, 0.85))


## Draw three layered smoke rings rising upward (animated by phase).
func _draw_smoke(origin: Vector2, phase: float) -> void:
	for k in range(3):
		var t: float   = fmod(phase + k * 0.7, 2.1) / 2.1
		var rise: float = t * 24
		var radius: float = 4.0 + t * 5
		var alpha: float  = 0.45 * (1.0 - t)
		draw_circle(origin + Vector2(sin(t * 3.1) * 3, -rise), radius,
					Color(0.70, 0.70, 0.70, alpha))


## Helper: filled ellipse approximated as a polygon.
func _draw_filled_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 32
	for i in range(steps):
		var angle := TAU * float(i) / float(steps)
		pts.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(pts, color)
