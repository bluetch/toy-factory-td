## SniperTower — extreme-range tower with armor-piercing rounds.
## Targets the lowest-HP enemy in range (finisher role).
## Fires slowly but deals high damage that ignores all armor.
class_name SniperTower
extends BaseTower

func _ready() -> void:
	shoot_sfx = load("res://assets/audio/shoot_arrow.wav")

## Override targeting: pick the lowest-HP enemy (finisher style)
func _get_best_target() -> Node2D:
	_enemies_in_range = _enemies_in_range.filter(
		func(e: Node2D) -> bool: return is_instance_valid(e)
	)
	var best: Node2D = null
	var lowest_hp: float = INF
	for enemy in _enemies_in_range:
		if enemy.has_method("get_path_progress"):
			var hp: float = enemy.get("current_health") if enemy.get("current_health") != null else INF
			if hp < lowest_hp:
				lowest_hp = hp
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
