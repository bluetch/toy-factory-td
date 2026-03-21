## CannonTower — fires slow AoE cannon balls.
class_name CannonTower
extends BaseTower

const CANNON_SCENE := preload("res://scenes/projectiles/CannonProjectile.tscn")

const BARREL_LEN := 18.0

func _ready() -> void:
	glow_color = Color(1.00, 0.52, 0.18, 1.0)
	shoot_sfx  = load("res://assets/audio/shoot_cannon.wav")

func _on_attack(tgt: Node2D) -> void:
	if not is_instance_valid(tgt) or projectile_container == null:
		return
	var ball: Node2D = CANNON_SCENE.instantiate()
	projectile_container.add_child(ball)
	var muzzle := _turret.global_position + Vector2(BARREL_LEN, 0.0).rotated(_turret.global_rotation)
	ball.global_position = muzzle
	if ball.has_method("launch_aoe"):
		var splash := tower_data.get_splash_radius(current_level) + SkillManager.get_splash_bonus()
		ball.launch_aoe(tgt, current_damage, tower_data.projectile_speed, splash)
	_spawn_muzzle_flash(muzzle)


## Cannon — drawn in Turret-local space, +X = toward target.
func _draw_weapon(node: Node2D) -> void:
	var mount_col  := Color(0.52, 0.38, 0.16, 1.0)
	var barrel_col := Color(0.68, 0.52, 0.22, 1.0)
	var muzzle_col := Color(0.38, 0.28, 0.10, 1.0)
	## Circular turret mount with rim highlight
	node.draw_circle(Vector2.ZERO, 8.0, mount_col)
	node.draw_circle(Vector2.ZERO, 8.0,
		Color(barrel_col.r, barrel_col.g, barrel_col.b, 0.5), false, 1.5)
	## Main barrel
	node.draw_line(Vector2(0, 0), Vector2(18, 0), barrel_col, 9.0, true)
	## Muzzle reinforcement band
	node.draw_line(Vector2(13, 0), Vector2(18, 0), muzzle_col, 11.0, true)
	## Barrel highlight stripe
	node.draw_line(Vector2(1.5, 0), Vector2(16.5, 0),
		Color(1.0, 0.90, 0.65, 0.35), 2.0, true)
	## Muzzle rim
	node.draw_circle(Vector2(18, 0), 5.5, muzzle_col)


## Orange fire burst at muzzle when firing.
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
	, 1.0, 0.0, 0.14)
	fx.draw.connect(func() -> void:
		if not fx.has_meta("_v"):
			return
		var v: float = fx.get_meta("_v")
		fx.draw_circle(Vector2.ZERO, v * 12.0, Color(1.0, 0.60, 0.10, v * 0.85))
		fx.draw_circle(Vector2.ZERO, v * 5.0,  Color(1.0, 0.95, 0.60, v))
	)
	tween.tween_callback(fx.queue_free).set_delay(0.16)
