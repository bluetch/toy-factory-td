## FastEnemy (Scout) — fast but fragile. Prioritize with arrow towers.
class_name FastEnemy
extends BaseEnemy

const BODY_COLOR := Color(0.9, 0.7, 0.1)

func _ready() -> void:
    var body := get_node_or_null("Body")
    if body is ColorRect or body is Sprite2D:
        body.modulate = BODY_COLOR
