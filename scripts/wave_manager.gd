## WaveManager — controls enemy wave spawning and inter-wave countdown.
## Attach as a child Node of GameWorld.
## GameWorld calls setup() after connecting all signals.
class_name WaveManager
extends Node

# ── Tunables ─────────────────────────────────────────────────
## Preparation time (seconds) before Wave 1 auto-starts.
const PREP_TIME: float = 20.0
## Countdown between waves when auto_start_delay == -1 (manual start).
const BETWEEN_WAVE_TIME: float = 15.0

# ── External references (set by GameWorld) ───────────────────
var enemy_container: Node2D
var _waypoints: Array[Vector2] = []

# ── Runtime state ─────────────────────────────────────────────
var _waves: Array[WaveData] = []
var _current_wave_index: int = -1
var _enemies_alive: int = 0
var _wave_in_progress: bool = false

## Remaining seconds in the current countdown (-1 = not counting)
var _countdown: float = -1.0
## True while a countdown is ticking
var _counting_down: bool = false

# ── Signals ───────────────────────────────────────────────────
## Emitted when it's time to show/refresh the "Start Wave N" button.
signal next_wave_ready(wave_number: int, total_waves: int)
## Emitted every frame while a countdown is running.
## [param seconds] remaining seconds (float, already rounded for display).
signal next_wave_countdown(seconds: float)
## Emitted after the last wave's enemies are all gone.
signal all_waves_done

func _ready() -> void:
	add_to_group("wave_manager")
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)

# ── Setup ─────────────────────────────────────────────────────

## Called by GameWorld after all signals are connected.
func setup(waves: Array[WaveData], spawn_pos: Vector2) -> void:
	_waves            = waves
	_current_wave_index = -1
	_enemies_alive    = 0
	_wave_in_progress = false
	if not _waypoints.is_empty():
		spawn_pos = _waypoints[0]

	# Start preparation countdown → auto-starts wave 1 when it expires.
	_start_countdown(PREP_TIME)
	next_wave_ready.emit(1, _waves.size())

func set_waypoints(waypoints: Array[Vector2]) -> void:
	_waypoints = waypoints

# ── Countdown ─────────────────────────────────────────────────

func _start_countdown(seconds: float) -> void:
	_countdown      = seconds
	_counting_down  = true

func _stop_countdown() -> void:
	_countdown     = -1.0
	_counting_down = false

func _process(delta: float) -> void:
	if not _counting_down:
		return
	# 暫停時不倒數（Engine.time_scale=0 所以 delta=0，但明確檢查更安全）
	if GameManager.state == GameManager.GameState.PAUSED:
		return
	_countdown -= delta
	next_wave_countdown.emit(_countdown)
	if _countdown <= 0.0:
		_stop_countdown()
		start_next_wave()

# ── Wave control ──────────────────────────────────────────────

## Start the next wave immediately (skips any running countdown).
func start_next_wave() -> void:
	_stop_countdown()
	_current_wave_index += 1
	if _current_wave_index >= _waves.size():
		return
	_wave_in_progress = true
	var wave_data: WaveData = _waves[_current_wave_index]
	EventBus.wave_started.emit(_current_wave_index + 1, _waves.size())
	_spawn_wave(wave_data)

# ── Spawning ──────────────────────────────────────────────────

func _spawn_wave(wave_data: WaveData) -> void:
	for entry in wave_data.entries:
		_enemies_alive += entry.count
		for i in range(entry.count):
			var delay := entry.group_delay + i * entry.spawn_interval
			# Scale delay with game speed so fast-forward works correctly.
			get_tree().create_timer(delay / GameManager.game_speed).timeout.connect(
				func() -> void: _spawn_enemy(entry.enemy_data)
			)

func _spawn_enemy(enemy_data: EnemyData) -> void:
	if enemy_data == null or enemy_data.scene_path.is_empty():
		push_warning("WaveManager: Invalid enemy_data.")
		_enemies_alive -= 1
		_check_wave_complete()
		return
	var packed: PackedScene = load(enemy_data.scene_path)
	if packed == null:
		push_error("WaveManager: Cannot load scene: " + enemy_data.scene_path)
		_enemies_alive -= 1
		_check_wave_complete()
		return
	var enemy: Node = packed.instantiate()
	enemy_container.add_child(enemy)
	if enemy.has_method("setup"):
		enemy.setup(enemy_data, _waypoints)

# ── Wave completion ───────────────────────────────────────────

func _on_enemy_died(_gold: int, _score: int) -> void:
	_enemies_alive -= 1
	_check_wave_complete()

func _on_enemy_reached_end() -> void:
	_enemies_alive -= 1
	_check_wave_complete()

func _check_wave_complete() -> void:
	if _enemies_alive > 0 or not _wave_in_progress:
		return
	_wave_in_progress = false
	EventBus.wave_completed.emit(_current_wave_index + 1)

	if _current_wave_index + 1 >= _waves.size():
		# All waves cleared
		EventBus.all_waves_completed.emit()
		all_waves_done.emit()
	else:
		# Start countdown to next wave
		var next_wave: WaveData = _waves[_current_wave_index + 1]
		var wait_time := next_wave.auto_start_delay if next_wave.auto_start_delay >= 0.0 \
						else BETWEEN_WAVE_TIME
		_start_countdown(wait_time)
		next_wave_ready.emit(_current_wave_index + 2, _waves.size())
