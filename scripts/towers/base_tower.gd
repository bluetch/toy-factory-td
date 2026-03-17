## BaseTower — shared logic for all tower types.
## Subclasses override _on_attack(target) to fire projectiles.
class_name BaseTower
extends Node2D

## Set by each subclass in _ready(). AudioManager.play_sfx() ignores null safely.
var shoot_sfx: AudioStream = null

## Set by GameWorld.initialize()
var tower_data: TowerData = null
var projectile_container: Node2D = null

## Runtime upgrade level (0 = base, 1 = first upgrade, 2 = max)
var current_level: int = 0

## Computed from tower_data + current_level
var current_damage: float = 0.0
var current_range: float  = 0.0
var current_attack_speed: float = 0.0

## Internal
var _attack_cooldown: float = 0.0
var _current_target: Node2D = null
## List of enemies currently in range (maintained by Area2D)
var _enemies_in_range: Array[Node2D] = []

@onready var detection_area: Area2D = $DetectionArea
@onready var range_circle: Node2D = $RangeCircle   ## visual indicator
@onready var attack_timer: Timer = $AttackTimer
## Turret node that rotates to face target (optional — only if scene has a Turret child)
@onready var _turret: Node2D = get_node_or_null("Turret")

## Called by GameWorld after instantiation
func initialize(data: TowerData, proj_container: Node2D) -> void:
    tower_data = data
    projectile_container = proj_container
    _apply_stats()
    _update_detection_area()
    range_circle.hide()   ## only show on selection

    detection_area.body_entered.connect(_on_body_entered)
    detection_area.body_exited.connect(_on_body_exited)
    attack_timer.timeout.connect(_on_attack_timer)
    attack_timer.wait_time = 1.0 / current_attack_speed
    attack_timer.start()

    # Spawn-in animation: pop from small to full size
    scale = Vector2(0.3, 0.3)
    var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2.ONE, 0.22)

func _apply_stats() -> void:
    if tower_data == null:
        return
    current_damage      = tower_data.get_damage(current_level)
    current_range       = tower_data.get_range(current_level)
    current_attack_speed= tower_data.get_attack_speed(current_level)

func _update_detection_area() -> void:
    var shape := CircleShape2D.new()
    shape.radius = current_range
    var collision := detection_area.get_child(0) as CollisionShape2D
    if collision:
        collision.shape = shape

## Upgrade to next level
func upgrade() -> void:
    if tower_data == null or current_level >= tower_data.upgrades.size():
        return
    current_level += 1
    _apply_stats()
    _update_detection_area()
    attack_timer.wait_time = 1.0 / current_attack_speed
    range_circle.queue_redraw()
    _play_upgrade_animation()

## Brief scale-pulse to confirm upgrade was applied
func _play_upgrade_animation() -> void:
    var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1)
    tween.tween_property(self, "scale", Vector2.ONE, 0.2)

## Returns upgrade cost for the NEXT level (0 if max)
func get_upgrade_cost() -> int:
    if tower_data == null or current_level >= tower_data.upgrades.size():
        return 0
    return tower_data.upgrades[current_level].upgrade_cost

## Returns whether this tower can be upgraded further
func can_upgrade() -> bool:
    return tower_data != null and current_level < tower_data.upgrades.size()

## Returns current sell value
func get_sell_value() -> int:
    if tower_data == null:
        return 0
    return tower_data.get_sell_value(current_level)

## Show or hide the range circle (called by HUD on selection)
func show_range(visible_flag: bool) -> void:
    range_circle.visible = visible_flag
    range_circle.queue_redraw()

## Radians per second the turret rotates toward its target (frame-rate independent)
const TURRET_ROT_SPEED: float = 8.0

## Smoothly rotate turret toward current target each frame
func _process(delta: float) -> void:
    if _turret == null:
        return
    if is_instance_valid(_current_target):
        var desired_angle := (_current_target.global_position - global_position).angle()
        var max_step := TURRET_ROT_SPEED * delta
        var diff := wrapf(desired_angle - _turret.rotation, -PI, PI)
        _turret.rotation += clampf(diff, -max_step, max_step)

func _on_attack_timer() -> void:
    _current_target = _get_best_target()
    if _current_target != null:
        AudioManager.play_sfx(shoot_sfx)
        _on_attack(_current_target)

## Override in subclasses to fire projectile
func _on_attack(_target: Node2D) -> void:
    pass

## Targeting: pick the enemy furthest along the path (highest waypoint index + progress)
func _get_best_target() -> Node2D:
    # Purge stale references (enemies that died without triggering body_exited)
    _enemies_in_range = _enemies_in_range.filter(
        func(e: Node2D) -> bool: return is_instance_valid(e)
    )
    var best: Node2D = null
    var best_progress: float = -1.0
    for enemy in _enemies_in_range:
        if enemy.has_method("get_path_progress"):
            var progress: float = enemy.get_path_progress()
            if progress > best_progress:
                best_progress = progress
                best = enemy
    return best

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("enemies"):
        _enemies_in_range.append(body)

func _on_body_exited(body: Node2D) -> void:
    _enemies_in_range.erase(body)
    if _current_target == body:
        _current_target = null
