## BaseProjectile — moves toward a target and calls _on_hit() when it arrives.
## Subclasses can set _fixed_dir at launch to fly in a straight line instead of homing.
class_name BaseProjectile
extends Area2D

var _target:    Node2D  = null
var _damage:    float   = 0.0
var _speed:     float   = 300.0
## If non-zero: fly straight in this direction (no per-frame re-targeting).
var _fixed_dir: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return

	var direction: Vector2
	if _fixed_dir.length_squared() > 0.5:
		direction = _fixed_dir          ## straight line — direction locked at launch
	else:
		direction = (_target.global_position - global_position).normalized()  ## homing

	var move := direction * _speed * delta
	if global_position.distance_to(_target.global_position) <= move.length() + 10.0:
		global_position = _target.global_position
		_on_hit()
	else:
		global_position += move
		rotation = direction.angle()

## Override in subclasses to implement hit behavior.
func _on_hit() -> void:
	queue_free()

## Helper: deal damage to a single enemy.
func _damage_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(_damage)
