## TankEnemy — slow, heavily armored. Use cannon towers.
class_name TankEnemy
extends BaseEnemy

const BODY_COLOR := Color(0.3, 0.3, 0.8)

func _ready() -> void:
    var body := get_node_or_null("Body")
    if body is ColorRect or body is Sprite2D:
        body.modulate = BODY_COLOR
