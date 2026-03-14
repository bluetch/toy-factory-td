## AchievementToast — slides in from the right, displays for 3 s, then slides out.
extends Control

const SLIDE_DURATION := 0.35
const DISPLAY_DURATION := 2.8

@onready var panel: PanelContainer = $Panel
@onready var name_label: Label = $Panel/VBox/NameLabel

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

## Call immediately after instantiation to set content and start animation.
func show_achievement(achievement_name: String) -> void:
	name_label.text = achievement_name

	# Use known panel width (offset-based layout, always 340px)
	const PANEL_WIDTH := 340.0
	position.x = 1728.0
	position.y = 60.0

	# Slide in
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", 1728.0 - PANEL_WIDTH - 16.0, SLIDE_DURATION)
	await tween.finished

	await get_tree().create_timer(DISPLAY_DURATION).timeout

	# Slide out
	var out_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	out_tween.tween_property(self, "position:x", 1728.0, SLIDE_DURATION)
	await out_tween.finished

	queue_free()
