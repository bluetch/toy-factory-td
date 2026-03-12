## ArrowProjectile — single-target fast projectile.
class_name ArrowProjectile
extends BaseProjectile

func launch(target: Node2D, damage: float, speed: float) -> void:
    _target = target
    _damage = damage
    _speed  = speed

func _on_hit() -> void:
    if is_instance_valid(_target):
        _damage_enemy(_target)
    queue_free()
