## RangeCircle — draws a semi-transparent circle showing a tower's attack range.
## Attach this Node2D as a child of any tower scene named "RangeCircle".
## The parent tower calls show_range(bool) which shows/hides this node.
## The radius is synced from the parent BaseTower.current_range on visibility change.
## The outline is drawn as a wobbly hand-sketched ring using layered sine waves.
extends Node2D

var _radius: float = 150.0
const OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.7)
const FILL_COLOR    := Color(1.0, 1.0, 1.0, 0.06)

## Number of points used to approximate the wobbly circle outline
const OUTLINE_POINTS: int = 64


func set_radius(radius: float) -> void:
    _radius = radius
    queue_redraw()


## Draw a wobbly hand-drawn circle outline using a single draw_polyline call
## (1 draw call vs. 64 draw_line calls — ~64× fewer GPU state changes).
## Each point's radius is perturbed by two sine waves with incommensurate frequencies
## so the outline never looks perfectly round.
func _draw_wobbly_outline(center: Vector2, base_radius: float, color: Color, width: float) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    points.resize(OUTLINE_POINTS + 1)  # +1 to close the loop
    for i in range(OUTLINE_POINTS):
        var angle: float = (float(i) / float(OUTLINE_POINTS)) * TAU
        var r: float = base_radius \
            + sin(angle * 7.3)  * 2.5 \
            + sin(angle * 11.7) * 1.2
        points[i] = center + Vector2(cos(angle) * r, sin(angle) * r)
    points[OUTLINE_POINTS] = points[0]  # Close the loop
    draw_polyline(points, color, width, true)


func _draw() -> void:
    if not visible:
        return
    # Filled semi-transparent circle (perfect fill is fine underneath the wobbly outline)
    draw_circle(Vector2.ZERO, _radius, FILL_COLOR)
    # Primary wobbly outline pass
    _draw_wobbly_outline(Vector2.ZERO, _radius, OUTLINE_COLOR, 2.0)
    # Secondary sketch-doubling pass at half opacity for a pencil-sketch feel
    var sketch_color := Color(OUTLINE_COLOR.r, OUTLINE_COLOR.g, OUTLINE_COLOR.b, OUTLINE_COLOR.a * 0.5)
    _draw_wobbly_outline(Vector2.ZERO, _radius, sketch_color, 0.5)


func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED:
        # When shown, sync radius from parent tower
        if visible:
            var tower := get_parent()
            if "current_range" in tower:
                set_radius(tower.current_range)
        queue_redraw()
