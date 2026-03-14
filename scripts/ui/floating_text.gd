## FloatingText — a world-space label that rises and fades out.
## Spawn as a child of any Node2D container and call setup().
class_name FloatingText
extends Node2D

const DURATION    := 1.1
const RISE_SPEED  := 55.0
const FONT_SIZE   := 18

var _text:  String = ""
var _color: Color  = Color.WHITE
var _timer: float  = 0.0


func setup(text: String, color: Color) -> void:
	_text  = text
	_color = color


func _process(delta: float) -> void:
	_timer        += delta
	position.y    -= RISE_SPEED * delta
	modulate.a     = maxf(0.0, 1.0 - _timer / DURATION)
	queue_redraw()
	if _timer >= DURATION:
		queue_free()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	# Drop-shadow for readability against any background
	draw_string(font, Vector2(1, 1), _text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE, Color(0, 0, 0, modulate.a * 0.7))
	draw_string(font, Vector2.ZERO, _text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE, _color)
