## BaseTower — shared logic for all tower types.
## Subclasses override _on_attack(target) to fire projectiles.
class_name BaseTower
extends Node2D

## Set by each subclass in _ready(). AudioManager.play_sfx() ignores null safely.
var shoot_sfx: AudioStream = null

## Accent colour for the ground-glow effect. Set by each subclass in _ready().
## Leave as Color.TRANSPARENT to disable the glow entirely.
var glow_color: Color = Color.TRANSPARENT

## Accumulates elapsed time for glow pulsing animation.
var _glow_time: float = 0.0

## Upgrade burst ring: counts down from 1.0 → 0 after each upgrade
var _upgrade_burst: float = 0.0

## Rest position of the Turret node (set from scene; tween back here after recoil kick)
var _turret_rest_pos: Vector2 = Vector2.ZERO

## Procedural weapon drawing node — child of _turret so it rotates with the turret
## and renders ABOVE the Body sprite. Subclasses draw into it via _draw_weapon().
var _weapon_node: Node2D = null

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
    attack_timer.start(attack_timer.wait_time)

    if _turret != null:
        _turret_rest_pos = _turret.position
        ## Weapon sprite hidden — we draw procedurally instead.
        var ws := _turret.get_node_or_null("Weapon")
        if ws:
            ws.visible = false
        ## WeaponDraw is a child of Turret: it inherits Turret's rotation, so
        ## +X always points toward the current target. draw_* calls from
        ## _draw_weapon() render ABOVE the Body sprite (child nodes paint over parents).
        _weapon_node = Node2D.new()
        _weapon_node.name = "WeaponDraw"
        _turret.add_child(_weapon_node)
        _weapon_node.draw.connect(func() -> void: _draw_weapon(_weapon_node))

    # _process() drives turret rotation and glow pulse animation.
    set_process(_turret != null or glow_color.a > 0.0)
    # Pass accent colour to range circle (subclass _ready sets glow_color before initialize)
    if range_circle.has_method("set_color") and glow_color.a > 0.0:
        range_circle.set_color(glow_color)

    # Spawn-in animation: pop from small to full size
    scale = Vector2(0.3, 0.3)
    var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2.ONE, 0.22)

func _apply_stats() -> void:
    if tower_data == null:
        return
    var tid := tower_data.scene_path.get_file().get_basename()
    current_damage       = tower_data.get_damage(current_level)       * SkillManager.get_damage_mult(tid)
    current_range        = tower_data.get_range(current_level)        * SkillManager.get_range_mult(tid)
    current_attack_speed = tower_data.get_attack_speed(current_level) * SkillManager.get_speed_mult(tid)

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

## Brief scale-pulse + ring burst to confirm upgrade was applied
func _play_upgrade_animation() -> void:
    var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1)
    tween.tween_property(self, "scale", Vector2.ONE, 0.2)
    ## Trigger the burst ring drawn in _draw()
    _upgrade_burst = 1.0
    set_process(true)   ## ensure _process runs for the burst countdown

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

## Smoothly rotate turret toward current target each frame; also drives glow pulse.
func _process(delta: float) -> void:
    _glow_time += delta
    if _upgrade_burst > 0.0:
        _upgrade_burst = maxf(0.0, _upgrade_burst - delta * 2.2)
        queue_redraw()
    ## Turn off process once all animations finish (for towers with no turret/glow)
    if _upgrade_burst <= 0.0 and _turret == null and glow_color.a <= 0.0:
        set_process(false)
    if glow_color.a > 0.0 or _turret != null:
        queue_redraw()
    if _weapon_node != null:
        _weapon_node.queue_redraw()
    if _turret == null:
        return
    if is_instance_valid(_current_target):
        ## Compute angle from the TURRET's world position (not the tower root).
        var desired_angle := (_current_target.global_position - _turret.global_position).angle()
        var max_step := TURRET_ROT_SPEED * delta
        ## Use global_rotation so parent transforms don't cause drift.
        var diff := wrapf(desired_angle - _turret.global_rotation, -PI, PI)
        _turret.rotation += clampf(diff, -max_step, max_step)


## Pulsing ground-glow drawn beneath all child sprites, plus procedural weapon barrel.
func _draw() -> void:
    ## Upgrade burst ring: expands outward and fades
    if _upgrade_burst > 0.0:
        var t := 1.0 - _upgrade_burst   ## 0=start, 1=end
        var ring_r := 20.0 + t * 68.0
        var ring_a := _upgrade_burst * 0.90
        var burst_col := glow_color if glow_color.a > 0.0 else Color(1.0, 0.92, 0.35)
        var ring_col := Color(burst_col.r, burst_col.g, burst_col.b, ring_a)
        _draw_glow_ellipse(Vector2.ZERO, ring_r, ring_r * 0.45, ring_col)
        ## Inner bright ring (thinner, slightly faster)
        var inner_r := 14.0 + t * 42.0
        var inner_col := Color(1.0, 1.0, 1.0, _upgrade_burst * 0.55)
        _draw_glow_ellipse(Vector2.ZERO, inner_r, inner_r * 0.4, inner_col)

    if glow_color.a > 0.0:
        var pulse := 0.78 + sin(_glow_time * 2.1) * 0.22
        var cx := 0.0
        var cy := 4.0   ## slightly below centre — sits at the tower's "base"
        var layers: Array = [
            [58.0, 20.0, 0.030],
            [44.0, 15.0, 0.060],
            [30.0, 10.0, 0.100],
            [18.0,  6.5, 0.145],
            [10.0,  3.5, 0.115],
        ]
        for layer in layers:
            var rx: float = layer[0]
            var ry: float = layer[1]
            var a: float  = layer[2] * pulse
            _draw_glow_ellipse(Vector2(cx, cy), rx, ry,
                Color(glow_color.r, glow_color.g, glow_color.b, a))


## Override in subclasses to draw the weapon barrel.
## Called via _weapon_node.draw signal — node is a child of Turret, so:
##   • origin (0,0) = turret pivot position
##   • Vector2.RIGHT (+X) = forward toward current target (Turret already rotated)
##   • Vector2.DOWN  (+Y) = perpendicular right
## Draw at full size; physical recoil is handled by _turret.position tween.
func _draw_weapon(_node: Node2D) -> void:
    pass


func _draw_glow_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
    const SEG := 24
    var pts := PackedVector2Array()
    pts.resize(SEG)
    for i in range(SEG):
        var a := TAU * i / SEG
        pts[i] = center + Vector2(cos(a) * rx, sin(a) * ry)
    var cols := PackedColorArray()
    cols.resize(SEG)
    cols.fill(col)
    draw_polygon(pts, cols)

func _on_attack_timer() -> void:
    _current_target = _get_best_target()
    if _current_target != null:
        if _turret != null and is_instance_valid(_current_target):
            ## Snap turret to exact firing angle.
            _turret.rotation = (_current_target.global_position - _turret.global_position).angle()
            ## Physical recoil: kick the turret back along its barrel, then spring back.
            var back := -Vector2(cos(_turret.rotation), sin(_turret.rotation)) * 4.0
            _turret.position = _turret_rest_pos + back
            var tw := _turret.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
            tw.tween_property(_turret, "position", _turret_rest_pos, 0.25)
        AudioManager.play_sfx(shoot_sfx)
        _on_attack(_current_target)
        _play_attack_flash()


## Brief bright flash on the tower when it fires — visual feedback for attacks.
func _play_attack_flash() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate", Color(1.55, 1.55, 1.55, 1.0), 0.04)
    tween.tween_property(self, "modulate", Color.WHITE, 0.14)

## Override in subclasses to fire projectile
func _on_attack(_target: Node2D) -> void:
    pass

## Targeting: pick the enemy furthest along the path (highest waypoint index + progress)
func _get_best_target() -> Node2D:
    # Purge stale references in-place (avoids creating a new Array each tick)
    var i := _enemies_in_range.size() - 1
    while i >= 0:
        if not is_instance_valid(_enemies_in_range[i]):
            _enemies_in_range.remove_at(i)
        i -= 1
    var best: Node2D = null
    var best_progress: float = -1.0
    for enemy in _enemies_in_range:
        if enemy.get("_is_dead") == true:
            continue
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
