## BossEnemy — scene script for the boss-tier enemy.
## Larger and visually distinct; on death emits an extra shake signal.
class_name BossEnemyScene
extends BaseEnemy

@onready var _body_rect: ColorRect = $Visual/Body
@onready var _core_rect: ColorRect = $Visual/Core

func _ready() -> void:
	# Pulsing glow on the core
	var tween := create_tween().set_loops()
	tween.tween_property(_core_rect, "modulate:a", 0.4, 0.9)
	tween.tween_property(_core_rect, "modulate:a", 1.0, 0.9)

func _on_death() -> void:
	# Boss death: trigger extra-strong camera shake via GameWorld
	var gw: Node = get_tree().get_first_node_in_group("game_world")
	if gw and gw.has_method("trigger_shake"):
		gw.trigger_shake(0.7, 20.0)
	# Spawn a big "+Gold" text
	_spawn_float_text("💀 BOSS倒下！", Color(1.0, 0.4, 0.4))
