## LightningTower — fires chain lightning that jumps to up to 3 enemies.
## Damage decreases by 40% per jump. No projectile — instant hit with Line2D effect.
class_name LightningTower
extends BaseTower

const CHAIN_COUNT   := 3       ## Maximum enemies hit per strike
const CHAIN_FALLOFF := 0.6     ## Damage multiplier per jump
const ARC_LIFETIME  := 0.18    ## Seconds the lightning arc is visible

func _ready() -> void:
	shoot_sfx = load("res://assets/audio/shoot_arrow.wav")   ## reuse until dedicated sfx added

## Override: chain lightning hits multiple enemies instantly
func _on_attack(target: Node2D) -> void:
	if not is_instance_valid(target) or projectile_container == null:
		return

	# Build the hit chain starting from primary target
	var hit_chain: Array[Node2D] = [target]
	var remaining_candidates: Array[Node2D] = []
	for e in _enemies_in_range:
		if is_instance_valid(e) and e != target:
			remaining_candidates.append(e)

	var last_hit: Node2D = target
	while hit_chain.size() < CHAIN_COUNT and not remaining_candidates.is_empty():
		# Jump to the enemy closest to the last hit position
		var closest: Node2D = null
		var closest_dist := INF
		for candidate in remaining_candidates:
			if not is_instance_valid(candidate):
				continue
			var d := last_hit.global_position.distance_to(candidate.global_position)
			if d < closest_dist:
				closest_dist = d
				closest = candidate
		if closest == null:
			break
		hit_chain.append(closest)
		remaining_candidates.erase(closest)
		last_hit = closest

	# Apply damage and spawn arc visuals
	var damage := current_damage
	var positions: Array[Vector2] = [global_position]
	for hit_node in hit_chain:
		if hit_node.has_method("take_damage"):
			hit_node.take_damage(damage)
		positions.append(hit_node.global_position)
		damage *= CHAIN_FALLOFF

	_spawn_arc(positions)

## Draw a multi-segment lightning arc that fades and disappears.
func _spawn_arc(positions: Array[Vector2]) -> void:
	if positions.size() < 2:
		return

	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.55, 0.85, 1.0, 1.0)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode   = Line2D.LINE_CAP_ROUND

	# Add slight random jitter to each segment for a jagged look
	for i in positions.size():
		var pt := positions[i]
		if i != 0 and i != positions.size() - 1:
			pt += Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		line.add_point(pt)

	projectile_container.add_child(line)

	# Fade out and remove
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, ARC_LIFETIME)
	tween.tween_callback(line.queue_free)
