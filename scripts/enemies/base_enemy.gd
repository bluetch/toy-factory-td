## BaseEnemy — shared logic for all enemy types.
## Moves along a predefined set of world-space waypoints.
## Subclasses can override _on_death() for special effects.
class_name BaseEnemy
extends CharacterBody2D

## Set by WaveManager via setup()
var enemy_data: EnemyData = null
var _waypoints: Array[Vector2] = []

## Runtime state
var current_health: float = 0.0
var _current_waypoint_index: int = 0
## Accumulated linear distance travelled (used for targeting priority)
var _path_progress: float = 0.0

## Slow effect state
var _speed_multiplier: float = 1.0
var _slow_timer: float = 0.0

@onready var health_bar_bg: ColorRect  = $HealthBar/Background
@onready var health_bar_fill: ColorRect = $HealthBar/Fill

const HEALTH_BAR_WIDTH := 40.0

func setup(data: EnemyData, waypoints: Array[Vector2]) -> void:
    enemy_data = data
    _waypoints = waypoints
    current_health = data.max_health
    global_position = waypoints[0] if not waypoints.is_empty() else Vector2.ZERO
    _current_waypoint_index = 1
    _update_health_bar()
    add_to_group("enemies")

func _physics_process(delta: float) -> void:
    if enemy_data == null or _waypoints.is_empty():
        return
    if _current_waypoint_index >= _waypoints.size():
        _reach_end()
        return

    # Update slow timer
    if _slow_timer > 0.0:
        _slow_timer -= delta
        if _slow_timer <= 0.0:
            _speed_multiplier = 1.0

    # Move toward current waypoint
    var target_pos := _waypoints[_current_waypoint_index]
    var direction   := (target_pos - global_position).normalized()
    var effective_speed := enemy_data.move_speed * _speed_multiplier
    var move_amount := effective_speed * delta

    if global_position.distance_to(target_pos) <= move_amount:
        global_position = target_pos
        _path_progress += global_position.distance_to(
            _waypoints[_current_waypoint_index - 1] if _current_waypoint_index > 0 else global_position
        )
        _current_waypoint_index += 1
    else:
        velocity = direction * effective_speed
        _path_progress += move_amount
        move_and_slide()

## Apply a slow effect
func apply_slow(factor: float, duration: float) -> void:
    _speed_multiplier = minf(_speed_multiplier, factor)
    _slow_timer = maxf(_slow_timer, duration)

## Returns total path progress for targeting priority
func get_path_progress() -> float:
    return _path_progress

## Apply damage (armor reduces incoming damage)
func take_damage(damage: float) -> void:
    if enemy_data == null:
        return
    var effective_damage := damage * (1.0 - enemy_data.armor)
    current_health -= effective_damage
    _update_health_bar()
    if current_health <= 0.0:
        _die()

func _die() -> void:
    EventBus.enemy_died.emit(enemy_data.gold_reward, enemy_data.score_reward)
    GameManager.add_gold(enemy_data.gold_reward)
    GameManager.add_score(enemy_data.score_reward)
    _on_death()
    queue_free()

func _reach_end() -> void:
    EventBus.enemy_reached_end.emit()
    queue_free()

## Override for death effects (particles, sounds, etc.)
func _on_death() -> void:
    pass

func _update_health_bar() -> void:
    if enemy_data == null or health_bar_fill == null:
        return
    var ratio := clampf(current_health / enemy_data.max_health, 0.0, 1.0)
    health_bar_fill.size.x = HEALTH_BAR_WIDTH * ratio
    health_bar_fill.modulate = Color(1.0 - ratio, ratio, 0.0)  ## red -> green
