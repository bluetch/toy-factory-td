## RangeCircle — draws a semi-transparent circle showing a tower's attack range.
## Attach this Node2D as a child of any tower scene named "RangeCircle".
## The parent tower calls show_range(bool) which shows/hides this node.
## The radius is synced from the parent BaseTower.current_range on visibility change.
extends Node2D

var _radius: float = 150.0
const OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const FILL_COLOR    := Color(1.0, 1.0, 1.0, 0.08)

func set_radius(radius: float) -> void:
    _radius = radius
    queue_redraw()

func _draw() -> void:
    if not visible:
        return
    # Filled semi-transparent circle
    draw_circle(Vector2.ZERO, _radius, FILL_COLOR)
    # Outline ring (drawn as arc segments)
    draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, OUTLINE_COLOR, 1.5)

func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED:
        # When shown, sync radius from parent tower
        if visible:
            var tower := get_parent()
            if "current_range" in tower:
                set_radius(tower.current_range)
        queue_redraw()
