## CannonTower — fires slow AoE cannon balls.
class_name CannonTower
extends BaseTower

const CANNON_SCENE := preload("res://scenes/projectiles/CannonProjectile.tscn")

func _on_attack(target: Node2D) -> void:
    if not is_instance_valid(target) or projectile_container == null:
        return
    var ball: Node2D = CANNON_SCENE.instantiate()
    projectile_container.add_child(ball)
    ball.global_position = global_position
    if ball.has_method("launch_aoe"):
        ball.launch_aoe(target, current_damage, tower_data.projectile_speed, tower_data.splash_radius)
