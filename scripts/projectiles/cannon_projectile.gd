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
        var body := result["collider"] as Node2D
        if body != null and body.is_in_group("enemies"):
            _damage_enemy(body)
    queue_free()
