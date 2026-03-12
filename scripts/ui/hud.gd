## HUD — in-game heads-up display.
## Shows lives, gold, score, current wave, speed toggle, pause button.
## Also hosts the TowerPanel and UpgradePanel overlays.
class_name HUD
extends Control

@onready var lives_label:    Label   = $TopBar/LivesLabel
@onready var gold_label:     Label   = $TopBar/GoldLabel
@onready var score_label:    Label   = $TopBar/ScoreLabel
@onready var wave_label:     Label   = $TopBar/WaveLabel
@onready var speed_button:   Button  = $TopBar/SpeedButton
@onready var pause_button:   Button  = $TopBar/PauseButton
@onready var next_wave_btn:  Button  = $TopBar/NextWaveButton
@onready var message_label:  Label   = $MessageLabel
@onready var tower_panel:    Control = $TowerPanel
@onready var upgrade_panel:  Control = $UpgradePanel

## Reference to GameWorld (set externally or found via get_parent chain)
var game_world: Node = null

var _message_timer: float = 0.0
const MESSAGE_DURATION := 2.0

func _ready() -> void:
	# Connect EventBus signals
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.game_speed_changed.connect(_on_speed_changed)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)

	speed_button.pressed.connect(GameManager.toggle_speed)
	pause_button.pressed.connect(_on_pause_pressed)
	next_wave_btn.pressed.connect(_on_next_wave_pressed)
	next_wave_btn.hide()
	message_label.hide()
	upgrade_panel.hide()

	# Initial values
	_on_lives_changed(GameManager.lives)
	_on_gold_changed(GameManager.gold)
	_on_score_changed(GameManager.score)
	_on_speed_changed(GameManager.game_speed)

## Called by GameWorld
func set_game_world(gw: Node) -> void:
	game_world = gw

func _process(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			message_label.hide()

## Show a brief floating message (e.g. "Not enough gold!")
func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	_message_timer = MESSAGE_DURATION

## Called by WaveManager signal
func on_next_wave_ready(wave_number: int, total_waves: int) -> void:
	wave_label.text = "Wave: %d / %d" % [wave_number - 1, total_waves] if wave_number > 1 else "Wave: 0 / %d" % total_waves
	next_wave_btn.text = "Start Wave %d" % wave_number
	next_wave_btn.show()

func on_all_waves_done() -> void:
	next_wave_btn.hide()
	wave_label.text = "All waves complete!"

## Show upgrade panel for the selected tower
func show_upgrade_panel(tower: Node) -> void:
	upgrade_panel.show()
	if upgrade_panel.has_method("populate"):
		upgrade_panel.populate(tower)

func hide_upgrade_panel() -> void:
	upgrade_panel.hide()

# ---- EventBus callbacks ----

func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "❤ %d" % new_lives

func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "💰 %d" % new_gold

func _on_score_changed(new_score: int) -> void:
	score_label.text = "⭐ %d" % new_score

func _on_speed_changed(new_speed: float) -> void:
	speed_button.text = "%.0fx" % new_speed

func _on_game_paused() -> void:
	pause_button.text = "▶ Resume"

func _on_game_resumed() -> void:
	pause_button.text = "⏸ Pause"

func _on_pause_pressed() -> void:
	if GameManager.game_state == GameManager.GameState.PAUSED:
		GameManager.resume_game()
	else:
		GameManager.pause_game()

func _on_next_wave_pressed() -> void:
	next_wave_btn.hide()
	# GameWorld owns WaveManager, look it up
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm and wm.has_method("start_next_wave"):
		wm.start_next_wave()
