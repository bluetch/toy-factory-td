## BasicEnemy (Grunt) — standard enemy with no special abilities.
class_name BasicEnemy
extends BaseEnemy

## Visual color override for placeholder graphics
const BODY_COLOR := Color(0.8, 0.2, 0.2)

func _ready() -> void:
    # Tint the body sprite/rect for placeholder visuals
    var body := get_node_or_null("Body")
    if body is ColorRect or body is Sprite2D:
        body.modulate = BODY_COLOR
