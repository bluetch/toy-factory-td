## IceTower — fires ice projectiles that slow enemies in an area.
class_name IceTower
extends BaseTower

const ICE_SCENE := preload("res://scenes/projectiles/IceProjectile.tscn")

const BARREL_LEN := 14.0

func _ready() -> void:
	glow_color = Color(0.28, 0.82, 1.00, 1.0)
	shoot_sfx = load("res://assets/audio/shoot_ice.wav")
	if shoot_sfx == null:
		push_warning("IceTower: shoot_ice.wav not found")


## Ice lance — drawn in Turret-local space, +X = toward target.
func _draw_weapon(node: Node2D) -> void:
	var shaft_col := Color(0.40, 0.70, 0.95, 1.0)
	var tip_col   := Color(0.85, 0.97, 1.00, 1.0)
	var glow_c    := Color(0.28, 0.82, 1.00, 0.35)
	## Soft glow halo at pivot
	node.draw_circle(Vector2.ZERO, 6.5, glow_c)
	## Shaft (tapers: wide at base, thin near tip)
	node.draw_line(Vector2(-2, 0), Vector2(9, 0), shaft_col, 5.0, true)
	node.draw_line(Vector2(9, 0), Vector2(14, 0), shaft_col, 2.5, true)
	## Diamond crystal tip: tip=(14,0), wing=(9,±4.5), back=(6,0)
	node.draw_line(Vector2(14, 0), Vector2(9,  4.5), tip_col, 1.5, true)
	node.draw_line(Vector2(14, 0), Vector2(9, -4.5), tip_col, 1.5, true)
	node.draw_line(Vector2(9,  4.5), Vector2(6, 0),  tip_col, 1.0, true)
	node.draw_line(Vector2(9, -4.5), Vector2(6, 0),  tip_col, 1.0, true)
	node.draw_circle(Vector2(14, 0), 2.5, tip_col)


func _on_attack(target: Node2D) -> void:
	if not is_instance_valid(target) or projectile_container == null:
		return
	var shard: Node2D = ICE_SCENE.instantiate()
	projectile_container.add_child(shard)
	## Spawn from barrel tip
	var muzzle := _turret.global_position + Vector2(BARREL_LEN, 0.0).rotated(_turret.global_rotation)
	shard.global_position = muzzle
	if shard.has_method("launch_slow"):
		var slow_f := clampf(tower_data.get_slow_factor(current_level) - SkillManager.get_slow_bonus(), 0.05, 1.0)
		var slow_d := tower_data.get_slow_duration(current_level) + SkillManager.get_slow_duration_bonus()
		shard.launch_slow(
			target,
			current_damage,
			tower_data.projectile_speed,
			tower_data.get_splash_radius(current_level),
			slow_f,
			slow_d
		)
	_spawn_muzzle_flash(muzzle)


## Ice-blue burst at barrel tip when firing.
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
	, 1.0, 0.0, 0.12)
	fx.draw.connect(func() -> void:
		if not fx.has_meta("_v"):
			return
		var v: float = fx.get_meta("_v")
		fx.draw_circle(Vector2.ZERO, v * 11.0, Color(0.50, 0.88, 1.0, v * 0.70))
		fx.draw_circle(Vector2.ZERO, v *  4.5, Color(1.0,  1.0,  1.0, v))
	)
	tween.tween_callback(fx.queue_free).set_delay(0.14)
