## LightningTower — fires chain lightning that jumps to up to 3 enemies.
## Damage decreases by 40% per jump. No projectile — instant hit with Line2D effect.
class_name LightningTower
extends BaseTower

const CHAIN_FALLOFF := 0.6     ## Damage multiplier per jump
const ARC_LIFETIME  := 0.18    ## Seconds the lightning arc is visible

const BARREL_LEN := 14.0

func _ready() -> void:
	glow_color = Color(1.00, 0.92, 0.18, 1.0)
	var sfx_path := "res://assets/kenney_interface-sounds/Audio/glitch_001.ogg"
	if ResourceLoader.exists(sfx_path):
		shoot_sfx = load(sfx_path)
	else:
		push_warning("LightningTower: SFX not found at '%s'" % sfx_path)

## Lightning emitter — drawn in Turret-local space, +X = toward target.
func _draw_weapon(node: Node2D) -> void:
	var base_col  := Color(0.88, 0.80, 0.14, 1.0)
	var prong_col := Color(1.00, 0.97, 0.42, 1.0)
	var glow_c    := Color(1.0, 0.95, 0.18, 0.20)
	## Glow halo at pivot
	node.draw_circle(Vector2.ZERO, 6.0, glow_c)
	## Base barrel
	node.draw_line(Vector2(-1.5, 0), Vector2(10, 0), base_col, 5.5, true)
	## Barrel highlight
	node.draw_line(Vector2(0, 0), Vector2(9, 0), Color(1.0, 1.0, 0.7, 0.30), 2.0, true)
	## Fork prongs (fork_base=(9,0), tips=(17,±5))
	node.draw_line(Vector2(9, 0), Vector2(17,  5), prong_col, 2.5, true)
	node.draw_line(Vector2(9, 0), Vector2(17, -5), prong_col, 2.5, true)
	## Spark dots at prong tips
	node.draw_circle(Vector2(17,  5), 2.0, prong_col)
	node.draw_circle(Vector2(17, -5), 2.0, prong_col)


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

	var chain_count: int = (tower_data.get_chain_count(current_level) if tower_data != null else 3) \
			+ SkillManager.get_chain_bonus()
	var last_hit: Node2D = target
	while hit_chain.size() < chain_count and not remaining_candidates.is_empty():
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

	# Apply damage and spawn arc visuals (arc starts from barrel tip)
	var damage := current_damage
	var muzzle := _turret.global_position + Vector2(BARREL_LEN, 0.0).rotated(_turret.global_rotation)
	var positions: Array[Vector2] = [muzzle]
	for hit_node in hit_chain:
		if is_instance_valid(hit_node) and hit_node.has_method("take_damage"):
			hit_node.take_damage(damage)
		positions.append(hit_node.global_position)
		damage *= CHAIN_FALLOFF

	_spawn_arc(positions)
	_spawn_muzzle_flash(muzzle)

## Brief glow burst at barrel tip when firing.
func _spawn_muzzle_flash(world_pos: Vector2) -> void:
	if projectile_container == null:
		return
	var flash := Node2D.new()
	flash.global_position = world_pos
	projectile_container.add_child(flash)
	flash.draw.connect(func() -> void:
		if flash.has_meta("_a"):
			var a: float = flash.get_meta("_a")
			flash.draw_circle(Vector2.ZERO, 18.0, Color(0.55, 0.90, 1.0, a * 0.70))
			flash.draw_circle(Vector2.ZERO,  9.0, Color(1.0,  1.0,  1.0, a * 0.90))
	)
	flash.set_meta("_a", 1.0)
	var tween := flash.create_tween()
	tween.tween_method(func(v: float) -> void:
		flash.set_meta("_a", v)
		flash.queue_redraw()
	, 1.0, 0.0, ARC_LIFETIME)
	tween.tween_callback(flash.queue_free)

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
