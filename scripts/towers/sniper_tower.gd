## SniperTower — extreme-range tower with armor-piercing rounds.
## Targets the lowest-HP enemy in range (finisher role).
## Fires slowly but deals high damage that ignores all armor.
class_name SniperTower
extends BaseTower

const FLASH_LIFETIME := 0.10

const BARREL_LEN := 22.0

func _ready() -> void:
	glow_color = Color(0.72, 0.44, 1.00, 1.0)
	var sfx_path := "res://assets/kenney_interface-sounds/Audio/tick_001.ogg"
	if ResourceLoader.exists(sfx_path):
		shoot_sfx = load(sfx_path)
	else:
		push_warning("SniperTower: SFX not found at '%s'" % sfx_path)

## Sniper rifle — drawn in Turret-local space, +X = toward target.
func _draw_weapon(node: Node2D) -> void:
	var barrel_col := Color(0.50, 0.28, 0.78, 1.0)
	var scope_col  := Color(0.30, 0.16, 0.52, 1.0)
	var tip_col    := Color(0.82, 0.58, 1.00, 1.0)
	## Long slender barrel
	node.draw_line(Vector2(-3, 0), Vector2(22, 0), barrel_col, 3.5, true)
	## Suppressor near muzzle (last 4px, thicker)
	node.draw_line(Vector2(18, 0), Vector2(22, 0), Color(0.38, 0.22, 0.58, 1.0), 5.5, true)
	## Scope body (perpendicular strut at x=8)
	node.draw_line(Vector2(8, -4), Vector2(8, 4), scope_col, 6.0, true)
	## Scope lens highlight
	node.draw_line(Vector2(8, -2.5), Vector2(8, 2.5), Color(0.7, 0.5, 1.0, 0.35), 2.0, true)
	## Muzzle glow dot
	node.draw_circle(Vector2(22, 0), 2.5, tip_col)


## Override targeting: pick the lowest-HP enemy (finisher style).
## Uses in-place backward purge (no allocation) consistent with BaseTower.
func _get_best_target() -> Node2D:
	var i := _enemies_in_range.size() - 1
	while i >= 0:
		if not is_instance_valid(_enemies_in_range[i]):
			_enemies_in_range.remove_at(i)
		i -= 1
	var best: Node2D = null
	var lowest_hp: float = INF
	for enemy: Node2D in _enemies_in_range:
		# Skip enemies already in death sequence (_is_dead set by BaseEnemy._die())
		if enemy.get("_is_dead") == true:
			continue
		var hp: Variant = enemy.get("current_health")
		var hp_f: float = float(hp) if hp != null else INF
		if hp_f < lowest_hp:
			lowest_hp = hp_f
			best = enemy
	return best

## Override: armor-piercing attack — bypass enemy armor entirely, instant hit
func _on_attack(target: Node2D) -> void:
	if not is_instance_valid(target) or projectile_container == null:
		return
	var dmg := current_damage
	# Roguelike crit: doubles damage at the configured probability
	var is_crit := SkillManager.get_crit_chance() > 0.0 and randf() < SkillManager.get_crit_chance()
	if is_crit:
		dmg *= 2.0
		_spawn_crit_text(target.global_position)
	## Tracer + flash on every shot, starting from barrel tip
	var muzzle := _turret.global_position + Vector2(BARREL_LEN, 0.0).rotated(_turret.global_rotation)
	_spawn_tracer(muzzle, target.global_position)
	_spawn_muzzle_flash(muzzle)
	if target.has_method("take_damage_piercing"):
		target.take_damage_piercing(dmg)
	elif target.has_method("take_damage"):
		target.take_damage(dmg)



## "CRIT!" floating text using the styled FloatingText variant.
static var _float_scene: PackedScene = null
func _spawn_crit_text(pos: Vector2) -> void:
	if projectile_container == null:
		return
	if _float_scene == null:
		_float_scene = load("res://scenes/ui/FloatingText.tscn")
	if _float_scene == null:
		return
	var ft: FloatingText = _float_scene.instantiate() as FloatingText
	projectile_container.add_child(ft)
	ft.global_position = pos + Vector2(0.0, -14.0)
	ft.setup_crit("CRIT!")

## Sharp white/yellow flash at barrel tip on fire.
func _spawn_muzzle_flash(world_pos: Vector2) -> void:
	if projectile_container == null:
		return
	var flash := Node2D.new()
	flash.global_position = world_pos
	projectile_container.add_child(flash)
	flash.draw.connect(func() -> void:
		if flash.has_meta("_a"):
			var a: float = flash.get_meta("_a")
			flash.draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.95, 0.70, a * 0.65))
			flash.draw_circle(Vector2.ZERO,  6.0, Color(1.0, 1.0,  1.0,  a * 0.90))
	)
	flash.set_meta("_a", 1.0)
	var tween := flash.create_tween()
	tween.tween_method(func(v: float) -> void:
		flash.set_meta("_a", v)
		flash.queue_redraw()
	, 1.0, 0.0, FLASH_LIFETIME)
	tween.tween_callback(flash.queue_free)

func _spawn_tracer(from_pos: Vector2, target_pos: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = Color(1.0, 0.95, 0.7, 1.0)
	line.add_point(from_pos)
	line.add_point(target_pos)
	projectile_container.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)
