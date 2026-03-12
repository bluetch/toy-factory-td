## WaveManager — controls enemy wave spawning.
## Receives waves from LevelData and spawns enemies into EnemyContainer.
class_name WaveManager
extends Node

## Reference set by GameWorld
var enemy_container: Node2D
var spawn_world_pos: Vector2   ## World position of the first waypoint

var _waves: Array[WaveData] = []
var _current_wave_index: int = -1
var _enemies_alive: int = 0
var _wave_in_progress: bool = false
var _all_spawned: bool = false  ## All waves have been sent

## Whether the player can manually start the next wave
var can_start_next_wave: bool = false

## Emitted when a wave is ready to start (for UI button)
signal next_wave_ready(wave_number: int, total_waves: int)
signal all_waves_done

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)

## Called by GameWorld to initialize waves
func setup(waves: Array[WaveData], spawn_pos: Vector2) -> void:
	_waves = waves
	spawn_world_pos = spawn_pos
	_current_wave_index = -1
	_enemies_alive = 0
	can_start_next_wave = true
	next_wave_ready.emit(1, _waves.size())

## Start the next wave (called by player button or auto-start)
func start_next_wave() -> void:
	if not can_start_next_wave:
		return
	_current_wave_index += 1
	if _current_wave_index >= _waves.size():
		return
	can_start_next_wave = false
	_wave_in_progress = true
	var wave_data: WaveData = _waves[_current_wave_index]
	EventBus.wave_started.emit(_current_wave_index + 1, _waves.size())
	_spawn_wave(wave_data)

## Spawns all enemy groups for a wave using timers
func _spawn_wave(wave_data: WaveData) -> void:
	for entry in wave_data.entries:
		_enemies_alive += entry.count
		var group_delay := entry.group_delay
		var spawn_interval := entry.spawn_interval
		for i in range(entry.count):
			var total_delay := group_delay + i * spawn_interval
			get_tree().create_timer(total_delay * (1.0 / GameManager.game_speed)).timeout.connect(
				func() -> void: _spawn_enemy(entry.enemy_data)
			)

func _spawn_enemy(enemy_data: EnemyData) -> void:
	if enemy_data == null or enemy_data.scene_path.is_empty():
		push_warning("WaveManager: Invalid enemy_data or missing scene_path.")
		_enemies_alive -= 1
		_check_wave_complete()
		return
	var packed: PackedScene = load(enemy_data.scene_path)
	if packed == null:
		push_error("WaveManager: Could not load scene: " + enemy_data.scene_path)
		_enemies_alive -= 1
		_check_wave_complete()
		return
	var enemy: Node = packed.instantiate()
	enemy_container.add_child(enemy)
	# BaseEnemy expects setup(enemy_data, waypoints) — GameWorld sets waypoints on WaveManager
	if enemy.has_method("setup"):
		enemy.setup(enemy_data, _waypoints)

var _waypoints: Array[Vector2] = []  ## World-space waypoints, set by GameWorld

func set_waypoints(waypoints: Array[Vector2]) -> void:
	_waypoints = waypoints
	if not waypoints.is_empty():
		spawn_world_pos = waypoints[0]

func _on_enemy_died(_gold: int, _score: int) -> void:
	_enemies_alive -= 1
	_check_wave_complete()

func _on_enemy_reached_end() -> void:
	_enemies_alive -= 1
	_check_wave_complete()

func _check_wave_complete() -> void:
	if _enemies_alive <= 0 and _wave_in_progress:
		_wave_in_progress = false
		EventBus.wave_completed.emit(_current_wave_index + 1)
		if _current_wave_index + 1 >= _waves.size():
			EventBus.all_waves_completed.emit()
			all_waves_done.emit()
		else:
			# Check if next wave auto-starts
			var next_wave: WaveData = _waves[_current_wave_index + 1]
			if next_wave.auto_start_delay >= 0.0:
				get_tree().create_timer(next_wave.auto_start_delay).timeout.connect(start_next_wave)
			else:
				can_start_next_wave = true
				next_wave_ready.emit(_current_wave_index + 2, _waves.size())
