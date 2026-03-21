## ArrowTower — fires fast straight-line arrows.
class_name ArrowTower
extends BaseTower

const ARROW_SCENE := preload("res://scenes/projectiles/ArrowProjectile.tscn")

## Barrel length from pivot to muzzle tip (px, local space).
const BARREL_LEN := 16.0

func _ready() -> void:
	glow_color = Color(0.30, 0.90, 0.42, 1.0)
	shoot_sfx  = load("res://assets/audio/shoot_arrow.wav")

func _on_attack(tgt: Node2D) -> void:
	if not is_instance_valid(tgt) or projectile_container == null:
		return
	var arrow: Node2D = ARROW_SCENE.instantiate()
	projectile_container.add_child(arrow)
	## Spawn from barrel tip using turret's actual world transform.
	var muzzle := _turret.global_position + Vector2(BARREL_LEN, 0.0).rotated(_turret.global_rotation)
	arrow.global_position = muzzle
	if arrow.has_method("launch"):
		arrow.launch(tgt, current_damage, tower_data.projectile_speed)
	_spawn_muzzle_flash(muzzle)


## Ballista crossbow — drawn in Turret-local space, +X = toward target.
func _draw_weapon(node: Node2D) -> void:
	var arm_col  := Color(0.55, 0.88, 0.38, 1.0)
	var bolt_col := Color(1.00, 0.95, 0.40, 1.0)
	var body_col := Color(0.35, 0.60, 0.25, 1.0)
	## Crossbow body / barrel
	node.draw_line(Vector2(-4, 0), Vector2(16, 0), body_col, 5.0, true)
	node.draw_line(Vector2(-3, 0), Vector2(15, 0),
		Color(body_col.r + 0.18, body_col.g + 0.12, body_col.b + 0.08, 0.55), 1.5, true)
	## Bow arms (arm_root at x=1.5, spanning ±11 on Y axis)
	node.draw_line(Vector2(1.5, -11), Vector2(1.5, 11), arm_col, 3.0, true)
	## Bowstring (V from arm tips to string mid at x=4.5)
	node.draw_line(Vector2(1.5, -11), Vector2(4.5, 0), arm_col, 1.2, true)
	node.draw_line(Vector2(1.5,  11), Vector2(4.5, 0), arm_col, 1.2, true)
	## Nocked bolt
	node.draw_line(Vector2(4.5, 0), Vector2(16, 0), bolt_col, 2.0, true)
	## Arrowhead
	node.draw_line(Vector2(16, 0), Vector2(19,  2.5), bolt_col, 1.2, true)
	node.draw_line(Vector2(16, 0), Vector2(19, -2.5), bolt_col, 1.2, true)
	node.draw_circle(Vector2(16, 0), 2.2, bolt_col)


## Bright green flash at the muzzle when firing.
func _spawn_muzzle_flash(world_pos: Vector2) -> void:
	if projectile_container == null:
		return
	var fx := Node2D.new()
	fx.global_position = world_pos
	projectile_container.add_child(fx)
	var tween := fx.create_tween()
	tween.tween_method(func(v: float) -> void:
		fx.queue_redraw()
		fx.set_meta("_v", v)
	, 1.0, 0.0, 0.10)
	fx.draw.connect(func() -> void:
		if not fx.has_meta("_v"):
			return
		var v: float = fx.get_meta("_v")
		fx.draw_circle(Vector2.ZERO, v * 9.0, Color(0.70, 1.00, 0.45, v * 0.80))
	)
	tween.tween_callback(fx.queue_free).set_delay(0.12)
