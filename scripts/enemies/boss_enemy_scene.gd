## BossEnemy — scene script for the boss-tier enemy.
## Larger and visually distinct; periodically charges (speed burst) and
## on death triggers camera shake + gold float text.
class_name BossEnemyScene
extends BaseEnemy

## Charge ability settings
const CHARGE_INTERVAL:  float = 8.0   ## seconds between charges
const CHARGE_DURATION:  float = 1.5   ## how long the speed burst lasts
const CHARGE_MULTIPLIER: float = 2.8  ## speed × this during charge

var _charge_timer: float = CHARGE_INTERVAL
var _is_charging: bool = false
## Speed multiplier saved just before a charge, restored after (preserves slow effects).
var _pre_charge_speed: float = 1.0

## Override setup() so we can emit boss_spawned after health is initialized.
func setup(data: EnemyData, waypoints: Array[Vector2], health_mult: float = 1.0) -> void:
	super.setup(data, waypoints, health_mult)
	EventBus.boss_spawned.emit(self)

## Emit boss_health_changed after each damage hit so the HUD bar updates.
func take_damage(damage: float) -> void:
	super.take_damage(damage)
	if is_instance_valid(self) and _max_health > 0.0:
		EventBus.boss_health_changed.emit(maxf(current_health, 0.0), _max_health)

func take_damage_piercing(damage: float) -> void:
	super.take_damage_piercing(damage)
	if is_instance_valid(self) and _max_health > 0.0:
		EventBus.boss_health_changed.emit(maxf(current_health, 0.0), _max_health)

func _ready() -> void:
	# Pulsing scale on the sprite for a "breathing" boss effect
	var visual: Node2D = $Visual
	if visual:
		var tween := create_tween().set_loops()
		tween.tween_property(visual, "scale", Vector2(1.08, 1.08), 0.9)
		tween.tween_property(visual, "scale", Vector2(1.0,  1.0),  0.9)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_charge_timer -= delta
	if _charge_timer <= 0.0 and not _is_charging:
		_start_charge()

func _start_charge() -> void:
	_is_charging = true
	_pre_charge_speed = _speed_multiplier
	_speed_multiplier = CHARGE_MULTIPLIER
	_spawn_float_text("⚡ 衝刺！", Color(1.0, 0.8, 0.1))
	# Flash red to warn player
	var visual: Node2D = $Visual
	if visual:
		var tween := create_tween()
		tween.tween_property(visual, "modulate", Color(2.0, 0.5, 0.5), 0.1)
		tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.2)
	# End charge after duration
	await get_tree().create_timer(CHARGE_DURATION).timeout
	if is_instance_valid(self):
		_speed_multiplier = _pre_charge_speed  # restore slow effect if active
		_is_charging = false
		_charge_timer = CHARGE_INTERVAL

func _on_death() -> void:
	# Boss death: trigger extra-strong camera shake via GameWorld
	var gw: Node = get_tree().get_first_node_in_group("game_world")
	if gw and gw.has_method("trigger_shake"):
		gw.trigger_shake(0.7, 20.0)
	# Spawn a big "+Gold" text
	_spawn_float_text("💀 BOSS倒下！", Color(1.0, 0.4, 0.4))
