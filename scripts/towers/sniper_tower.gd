## SniperTower — extreme-range tower with armor-piercing rounds.
## Targets the lowest-HP enemy in range (finisher role).
## Fires slowly but deals high damage that ignores all armor.
class_name SniperTower
extends BaseTower

const FLASH_LIFETIME := 0.10

func _ready() -> void:
	var sfx_path := "res://assets/kenney_interface-sounds/Audio/tick_001.ogg"
	if ResourceLoader.exists(sfx_path):
		shoot_sfx = load(sfx_path)
	else:
		push_warning("SniperTower: SFX not found at '%s'" % sfx_path)

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
	if target.has_method("take_damage_piercing"):
		target.take_damage_piercing(current_damage)
	elif target.has_method("take_damage"):
		target.take_damage(current_damage)
	_spawn_tracer(target.global_position)
	_spawn_muzzle_flash()

## Sharp white/yellow flash at turret barrel on fire.
func _spawn_muzzle_flash() -> void:
	if projectile_container == null:
		return
	var flash := Node2D.new()
	flash.global_position = global_position
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

func _spawn_tracer(target_pos: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(1.0, 0.95, 0.7, 1.0)
	line.add_point(global_position)
	line.add_point(target_pos)
	projectile_container.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)
