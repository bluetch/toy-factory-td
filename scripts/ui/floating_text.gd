## FloatingText — world-space label that rises, drifts, and fades.
## Call setup() for standard use, or setup_crit() / setup_gold() for variants.
class_name FloatingText
extends Node2D

const BASE_DURATION  := 1.1
const BASE_RISE      := 58.0
const BASE_FONT_SIZE := 18

var _text:     String = ""
var _color:    Color  = Color.WHITE
var _timer:    float  = 0.0
var _duration: float  = BASE_DURATION
var _rise:     float  = BASE_RISE
var _font_size: int   = BASE_FONT_SIZE
var _drift_x:       float = 0.0
var _scale_t:       float = 0.0    ## for bounce-in
var _outline:       bool  = false  ## draw multi-dir shadow (crits)
var _outline_color: Color = Color(0.0, 0.0, 0.0, 1.0)  ## shadow tint


## Standard damage number.
func setup(text: String, color: Color) -> void:
	_text      = text
	_color     = color
	_drift_x   = randf_range(-10.0, 10.0)
	_start_bounce(0.9)


## Large crit variant — bigger, longer drift, star-burst shadow.
func setup_crit(text: String) -> void:
	_text          = text
	_color         = Color(1.0, 0.92, 0.15)
	_font_size     = 26
	_duration      = 1.5
	_rise          = 72.0
	_drift_x       = randf_range(-28.0, 28.0)
	_outline       = true
	_outline_color = Color(0.55, 0.18, 0.0, 1.0)  ## warm dark orange shadow
	_start_bounce(1.2)


## Gold-reward float — golden, slower rise, subtle outline for legibility.
func setup_gold(text: String) -> void:
	_text          = text
	_color         = Color(1.0, 0.88, 0.28)
	_font_size     = 16
	_duration      = 1.4
	_rise          = 44.0
	_outline       = true
	_outline_color = Color(0.30, 0.18, 0.0, 1.0)  ## dark brown shadow reads on any bg
	_start_bounce(1.0)


## Status icon (❄ slow, ⚡ chain, etc.) — small, quick fade.
func setup_status(text: String, color: Color) -> void:
	_text      = text
	_color     = color
	_font_size = 20
	_duration  = 0.85
	_rise      = 36.0
	_start_bounce(1.0)


func _start_bounce(target_scale: float) -> void:
	## Start collapsed; _process() will spring it out.
	scale = Vector2.ZERO
	set_meta("_target_scale", target_scale)


func _process(delta: float) -> void:
	_timer   += delta
	_scale_t  = minf(_scale_t + delta * 14.0, 1.0)

	## Elastic spring-in then settle
	var ts: float = get_meta("_target_scale") if has_meta("_target_scale") else 1.0
	var spring := ts * (1.0 + sin(_scale_t * PI) * 0.28 * (1.0 - _scale_t))
	scale = Vector2(spring, spring)

	## Rise + horizontal drift (slows as it ages)
	var age_frac := _timer / _duration
	position.y -= _rise   * delta
	position.x += _drift_x * delta * (1.0 - age_frac)

	## Ease-out fade: stays opaque for first 40%, then fades
	modulate.a = maxf(0.0, 1.0 - maxf(0.0, age_frac - 0.4) / 0.6)

	queue_redraw()
	if _timer >= _duration:
		queue_free()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var a := modulate.a

	if _outline:
		## Multi-direction shadow using per-variant outline color
		var shadow := Color(_outline_color.r, _outline_color.g, _outline_color.b, a * 0.85)
		for ox: float in [-1.5, 0.0, 1.5]:
			for oy: float in [-1.5, 1.5]:
				draw_string(font, Vector2(ox, oy), _text,
					HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size, shadow)
	else:
		draw_string(font, Vector2(1.2, 1.2), _text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size, Color(0.0, 0.0, 0.0, a * 0.72))

	draw_string(font, Vector2.ZERO, _text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size, Color(_color.r, _color.g, _color.b, a))
