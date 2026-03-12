## IceTower — fires ice projectiles that slow enemies in an area.
class_name IceTower
extends BaseTower

const ICE_SCENE := preload("res://scenes/projectiles/IceProjectile.tscn")

func _on_attack(target: Node2D) -> void:
    if not is_instance_valid(target) or projectile_container == null:
        return
    var shard: Node2D = ICE_SCENE.instantiate()
    projectile_container.add_child(shard)
    shard.global_position = global_position
    if shard.has_method("launch_slow"):
        shard.launch_slow(
            target,
            current_damage,
            tower_data.projectile_speed,
            tower_data.splash_radius,
            tower_data.slow_factor,
            tower_data.slow_duration
        )
