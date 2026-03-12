## IceProjectile — AoE slow effect on impact.
class_name IceProjectile
extends BaseProjectile

var _splash_radius: float = 40.0
var _slow_factor:   float = 0.5
var _slow_duration: float = 2.0

func launch_slow(target: Node2D, damage: float, speed: float, splash: float, slow: float, slow_dur: float) -> void:
    _target        = target
    _damage        = damage
    _speed         = speed
    _splash_radius  = splash
    _slow_factor   = slow
    _slow_duration = slow_dur

func _on_hit() -> void:
    var space_state := get_world_2d().direct_space_state
    var query := PhysicsShapeQueryParameters2D.new()
    var shape  := CircleShape2D.new()
    shape.radius = _splash_radius
    query.shape = shape
    query.transform = Transform2D(0.0, global_position)
    query.collision_mask = 2
    var results := space_state.intersect_shape(query)
    for result in results:
        var body := result["collider"] as Node2D
        if body != null and body.is_in_group("enemies"):
            _damage_enemy(body)
            if body.has_method("apply_slow"):
                body.apply_slow(_slow_factor, _slow_duration)
    queue_free()
