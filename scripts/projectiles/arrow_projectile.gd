## ArrowProjectile — flies straight, leaves a glowing trail, flashes on impact.
class_name ArrowProjectile
extends BaseProjectile

const TRAIL_MAX := 6

var _trail: Array[Vector2] = []

func launch(tgt: Node2D, damage: float, speed: float) -> void:
	_target    = tgt
	_damage    = damage
	_speed     = speed
	## Lock direction at launch so the arrow flies in a straight line.
	_fixed_dir = (tgt.global_position - global_position).normalized()
	rotation   = _fixed_dir.angle()

func _physics_process(delta: float) -> void:
	_trail.append(global_position)
	if _trail.size() > TRAIL_MAX:
		_trail.remove_at(0)
	queue_redraw()
	super(delta)

## Draw a fading golden trail behind the arrow.
## Uses to_local() so the trail renders correctly when the Area2D is rotated.
func _draw() -> void:
	var n := _trail.size()
	if n < 2:
		return
	for i in range(1, n):
		var t   := float(i) / float(n)
		var p0  := to_local(_trail[i - 1])
		var p1  := to_local(_trail[i])
		var col := Color(1.0, 0.88, 0.28, t * 0.75)
		draw_line(p0, p1, col, lerp(3.5, 0.8, 1.0 - t), true)

func _on_hit() -> void:
	if is_instance_valid(_target):
		_damage_enemy(_target)
	_spawn_impact()
	queue_free()

## Small golden burst on impact.
func _spawn_impact() -> void:
	if get_parent() == null:
		return
	var fx := Node2D.new()
	fx.global_position = global_position
	get_parent().add_child(fx)
	var tween := fx.create_tween()
	tween.tween_method(func(v: float) -> void:
		fx.queue_redraw()
		fx.set_meta("_v", v)
	, 1.0, 0.0, 0.16)
	fx.draw.connect(func() -> void:
		if not fx.has_meta("_v"):
			return
		var v: float = fx.get_meta("_v")
		fx.draw_circle(Vector2.ZERO, v * 7.0, Color(1.0, 0.88, 0.30, v * 0.85))
	)
	tween.tween_callback(fx.queue_free).set_delay(0.18)
