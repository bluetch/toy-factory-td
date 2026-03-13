## ArrowTower — fires fast single-target arrows.
class_name ArrowTower
extends BaseTower

const ARROW_SCENE := preload("res://scenes/projectiles/ArrowProjectile.tscn")

func _ready() -> void:
	shoot_sfx = load("res://assets/audio/shoot_arrow.wav")
	if shoot_sfx == null:
		push_warning("ArrowTower: shoot_arrow.wav not found")

func _on_attack(target: Node2D) -> void:
	if not is_instance_valid(target) or projectile_container == null:
		return
	var arrow: Node2D = ARROW_SCENE.instantiate()
	projectile_container.add_child(arrow)
	arrow.global_position = global_position
	if arrow.has_method("launch"):
		arrow.launch(target, current_damage, tower_data.projectile_speed)
