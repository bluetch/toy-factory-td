## FactoryBase — the player's factory/castle that must be defended.
## Placed at the last path waypoint. Flashes red when an enemy reaches it.
## Sprite layers from Kenney Tower Defense Kit; smoke drawn procedurally.
class_name FactoryBase
extends Node2D

const FLASH_DURATION := 0.35

var _flash_timer: float = 0.0
var _smoke_phase: float = 0.0

@onready var _bottom: Sprite2D = $Bottom
@onready var _middle: Sprite2D = $Middle
@onready var _top: Sprite2D    = $Top


func _ready() -> void:
	EventBus.enemy_reached_end.connect(_on_enemy_hit)


func _process(delta: float) -> void:
	_smoke_phase += delta * 0.8
	if _flash_timer > 0.0:
		_flash_timer -= delta
		var t := clampf(_flash_timer / FLASH_DURATION, 0.0, 1.0)
		var hit_color := Color(1.0 + t * 0.6, 1.0 - t * 0.7, 1.0 - t * 0.7)
		if _bottom: _bottom.modulate = hit_color
		if _middle: _middle.modulate = hit_color
		if _top:    _top.modulate    = hit_color
	else:
		if _bottom: _bottom.modulate = Color.WHITE
		if _middle: _middle.modulate = Color.WHITE
		if _top:    _top.modulate    = Color.WHITE
	queue_redraw()


func _on_enemy_hit() -> void:
	_flash_timer = FLASH_DURATION


func _draw() -> void:
	var hit := _flash_timer > 0.0
	# Smoke rises above the Top sprite (centered at y=-128, top edge at y=-160)
	if not hit:
		_draw_smoke(Vector2(-16, -168), _smoke_phase)
		_draw_smoke(Vector2(14,  -162), _smoke_phase + 1.2)
	else:
		# Fire bursts when taking a hit
		var t := clampf(_flash_timer / FLASH_DURATION, 0.0, 1.0)
		draw_circle(Vector2(-16, -170), 12.0 * t, Color(1.0, 0.45, 0.0, 0.8 * t))
		draw_circle(Vector2( 14, -164),  9.0 * t, Color(1.0, 0.20, 0.0, 0.7 * t))


## Three layered smoke rings rising above the factory chimneys.
func _draw_smoke(origin: Vector2, phase: float) -> void:
	for k in range(3):
		var t: float  = fmod(phase + k * 0.7, 2.1) / 2.1
		var rise: float  = t * 28.0
		var radius: float = 4.0 + t * 6.0
		var alpha: float  = 0.50 * (1.0 - t)
		draw_circle(origin + Vector2(sin(t * 3.1) * 3.0, -rise), radius,
				Color(0.72, 0.72, 0.72, alpha))
