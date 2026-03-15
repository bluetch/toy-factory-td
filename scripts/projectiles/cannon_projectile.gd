## CannonProjectile — AoE explosion on impact.
class_name CannonProjectile
extends BaseProjectile

var _splash_radius: float = 60.0

func launch_aoe(target: Node2D, damage: float, speed: float, splash: float) -> void:
    _target       = target
    _damage       = damage
    _speed        = speed
    _splash_radius = splash

func _on_hit() -> void:
    # Damage all enemies within splash radius
    var space_state := get_world_2d().direct_space_state
    var query := PhysicsShapeQueryParameters2D.new()
    var shape  := CircleShape2D.new()
    shape.radius = _splash_radius
    query.shape = shape
    query.transform = Transform2D(0.0, global_position)
    query.collision_mask = 2  ## enemies are on layer 2
    var results := space_state.intersect_shape(query)
    for result in results:
        var body: Node2D = result["collider"] as Node2D
        if body != null and body.is_in_group("enemies"):
            _damage_enemy(body)
    _spawn_explosion_ring()
    queue_free()

func _spawn_explosion_ring() -> void:
    if get_parent() == null:
        return
    var ring := Node2D.new()
    ring.global_position = global_position
    get_parent().add_child(ring)
    var tween := ring.create_tween()
    tween.set_parallel(true)
    tween.tween_method(func(r: float) -> void:
        ring.queue_redraw()
        ring.set_meta("_r", r)
        ring.set_meta("_a", 1.0 - r / _splash_radius)
    , 4.0, _splash_radius, 0.3)
    ring.draw.connect(func() -> void:
        if ring.has_meta("_r"):
            ring.draw_arc(Vector2.ZERO, ring.get_meta("_r"), 0.0, TAU,
                32, Color(1.0, 0.55, 0.1, ring.get_meta("_a")), 3.0)
    )
    tween.tween_callback(ring.queue_free).set_delay(0.32)
