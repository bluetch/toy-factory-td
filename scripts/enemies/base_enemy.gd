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
var _is_slowed: bool = false

@onready var health_bar_bg: ColorRect  = $HealthBar/Background
@onready var health_bar_fill: ColorRect = $HealthBar/Fill
## Visual sub-node that rotates to face movement direction
@onready var _visual: Node2D = get_node_or_null("Visual")
## AnimatedSprite2D — present on sprite-based enemies, nil on ColorRect enemies
@onready var _anim: AnimatedSprite2D = get_node_or_null("Visual/AnimatedSprite2D")

const HEALTH_BAR_WIDTH := 40.0

func setup(data: EnemyData, waypoints: Array[Vector2]) -> void:
    enemy_data = data
    _waypoints = waypoints
    current_health = data.max_health
    global_position = waypoints[0] if not waypoints.is_empty() else Vector2.ZERO
    _current_waypoint_index = 1
    _update_health_bar()
    add_to_group("enemies")
    _play_anim("walk")

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
            _is_slowed = false
            if _visual != null:
                _visual.modulate = Color(1, 1, 1)

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

    # Rotate visual to face movement direction (health bar stays upright as it's a sibling)
    if _visual != null and direction.length() > 0.01:
        _visual.rotation = direction.angle()

## Apply a slow effect
func apply_slow(factor: float, duration: float) -> void:
    _speed_multiplier = minf(_speed_multiplier, factor)
    _slow_timer = maxf(_slow_timer, duration)
    if not _is_slowed:
        _is_slowed = true
        if _visual != null:
            _visual.modulate = Color(0.25, 0.65, 1.0)

## Returns total path progress for targeting priority
func get_path_progress() -> float:
    return _path_progress

## Apply damage that bypasses all armor (used by armor-piercing towers).
func take_damage_piercing(damage: float) -> void:
    if enemy_data == null:
        return
    current_health -= damage
    _update_health_bar()
    _flash_hit()
    if int(damage) > 0:
        _spawn_damage_text(int(damage))
    if current_health <= 0.0:
        _die()

## Apply damage (armor reduces incoming damage)
func take_damage(damage: float) -> void:
    if enemy_data == null:
        return
    var effective_damage := damage * (1.0 - enemy_data.armor)
    current_health -= effective_damage
    _update_health_bar()
    _flash_hit()
    if int(effective_damage) > 0:
        _spawn_damage_text(int(effective_damage))
    if current_health <= 0.0:
        _die()

## Brief white flash to signal a hit.
func _flash_hit() -> void:
    AudioManager.play_enemy_hit()
    if _visual == null:
        return
    var base_color := Color(0.25, 0.65, 1.0) if _is_slowed else Color(1, 1, 1)
    var tween := create_tween()
    tween.tween_property(_visual, "modulate", Color(2.5, 2.5, 2.5), 0.05)
    tween.tween_property(_visual, "modulate", base_color, 0.12)

func _die() -> void:
    # Remove from group immediately so towers stop targeting this enemy
    remove_from_group("enemies")
    set_physics_process(false)
    AudioManager.play_enemy_die()
    EventBus.enemy_died.emit(enemy_data.gold_reward, enemy_data.score_reward)
    GameManager.add_gold(enemy_data.gold_reward)
    GameManager.add_score(enemy_data.score_reward)
    _spawn_float_text("+%d 💰" % enemy_data.gold_reward, Color(1.0, 0.88, 0.25))
    _on_death()
    # Play death animation and wait for it to finish before removing
    if _anim != null and _anim.sprite_frames != null \
            and _anim.sprite_frames.has_animation("death"):
        _play_anim("death")
        await _anim.animation_finished
    elif _visual != null:
        # Sprite2D enemies: scale-up + fade out
        var tween := create_tween()
        tween.set_parallel(true)
        tween.tween_property(_visual, "scale", _visual.scale * 1.6, 0.25)
        tween.tween_property(_visual, "modulate:a", 0.0, 0.25)
        await tween.finished
    queue_free()

## Spawn a red damage number slightly to the side of the enemy.
func _spawn_damage_text(amount: int) -> void:
    var packed: PackedScene = load("res://scenes/ui/FloatingText.tscn")
    if packed == null or get_parent() == null:
        return
    var ft: FloatingText = packed.instantiate() as FloatingText
    get_parent().add_child(ft)
    var x_offset := randf_range(-16.0, 16.0)
    ft.global_position = global_position + Vector2(x_offset, -18)
    ft.setup("-%d" % amount, Color(1.0, 0.35, 0.35))

## Spawn a floating gold label above the enemy's death position.
func _spawn_float_text(text: String, color: Color) -> void:
    var packed: PackedScene = load("res://scenes/ui/FloatingText.tscn")
    if packed == null or get_parent() == null:
        return
    var ft: FloatingText = packed.instantiate() as FloatingText
    get_parent().add_child(ft)
    ft.global_position = global_position + Vector2(0, -24)
    ft.setup(text, color)

## Play a named animation if AnimatedSprite2D is present (safe no-op otherwise)
func _play_anim(anim_name: StringName) -> void:
    if _anim != null:
        _anim.play(anim_name)

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
