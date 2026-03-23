## WaveManager — controls enemy wave spawning and inter-wave countdown.
## Attach as a child Node of GameWorld.
## GameWorld calls setup() after connecting all signals.
##
## ── State machine ─────────────────────────────────────────────
##
##   setup()
##     └─► _start_countdown(PREP_TIME)   _counting_down=true
##           │  (timer fires or player presses button)
##           ▼
##       start_next_wave()               _wave_in_progress=true
##           │  (all enemies die/exit)
##           ▼
##       _check_wave_complete()
##           ├─► [more waves] _start_countdown(BETWEEN_TIME)  ← loop
##           └─► [last wave]  all_waves_done.emit()
##
##   _on_game_ended() resets all flags and clears the countdown.
##
class_name WaveManager
extends Node

# ── Tunables ─────────────────────────────────────────────────
## Preparation time before Wave 1, indexed by Difficulty (EASY/NORMAL/HARD).
const PREP_TIMES: Array[float] = [25.0, 20.0, 15.0]
## Inter-wave countdown when auto_start_delay == -1, indexed by Difficulty.
const BETWEEN_WAVE_TIMES: Array[float] = [20.0, 15.0, 10.0]
## Spawn-interval multiplier per difficulty: EASY enemies spawn slower, HARD faster.
const SPAWN_INTERVAL_MULT: Array[float] = [1.25, 1.0, 0.75]
## HP multiplier per difficulty: EASY enemies are weaker, HARD enemies are tougher.
const DIFFICULTY_HP_MULT: Array[float] = [0.80, 1.0, 1.30]

# ── External references (set by GameWorld) ───────────────────
var enemy_container: Node2D
var _waypoints: Array[Vector2] = []

# ── Runtime state ─────────────────────────────────────────────
## Pre-loaded PackedScene cache: scene_path → PackedScene.
## Populated in setup() so individual spawns never call load().
var _scene_cache: Dictionary = {}

var _waves: Array[WaveData] = []
var _current_wave_index: int = -1
var _enemies_alive: int = 0
var _wave_total_enemies: int = 0  ## total enemies spawned this wave (for HUD counter)
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

## Gold awarded to the player on completing each non-final wave.
const WAVE_BONUS_GOLD := 25

## Short icon strings used to build wave preview text (fallback).
## Matches actual enemy_name fields in .tres files.
const ENEMY_ICONS: Dictionary = {
	"basic_enemy": "小兵",
	"fast_enemy":  "斥候",
	"tank_enemy":  "重甲",
	"boss_enemy":  "渴望",
}

## Actual in-game sprite paths, matching the Kenney UFO sprites used by each enemy scene.
const ENEMY_SPRITES: Dictionary = {
	"basic_enemy": "res://assets/kenney_tower-defense-kit/Previews/enemy-ufo-a.png",
	"fast_enemy":  "res://assets/kenney_tower-defense-kit/Previews/enemy-ufo-b.png",
	"tank_enemy":  "res://assets/kenney_tower-defense-kit/Previews/enemy-ufo-c.png",
	"boss_enemy":  "res://assets/kenney_tower-defense-kit/Previews/enemy-ufo-d.png",
}

## Enemy modulate colours — must match the actual in-game sprite modulates.
## BasicEnemy: no modulate override (natural sprite).
## FastEnemy.BODY_COLOR  = Color(0.9, 0.7, 0.1)  — golden yellow.
## TankEnemy.BODY_COLOR  = Color(0.3, 0.3, 0.8)  — dark blue.
## BossEnemy: no modulate override (natural ufo-d sprite, scale 1.2×).
const ENEMY_COLORS: Dictionary = {
	"basic_enemy": Color(1.00, 1.00, 1.00),
	"fast_enemy":  Color(0.90, 0.70, 0.10),
	"tank_enemy":  Color(0.30, 0.30, 0.80),
	"boss_enemy":  Color(1.00, 1.00, 1.00),
}

## Set to true when game ends so pending spawn timers do nothing.
var _game_ended: bool = false

## Kill-streak combo: rapid kills within STREAK_WINDOW seconds reward bonus gold.
const STREAK_WINDOW  := 2.8   ## seconds between kills to maintain streak
const STREAK_THRESH  := 5     ## kills needed to trigger a combo bonus
const STREAK_GOLD    := 8     ## bonus gold per combo trigger
var _streak_count: int   = 0
var _streak_timer: float = 0.0

func _ready() -> void:
	add_to_group("wave_manager")
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)
	EventBus.game_over_triggered.connect(_on_game_ended)
	EventBus.victory_triggered.connect(_on_game_ended)

# ── Setup ─────────────────────────────────────────────────────

## Called by GameWorld after all signals are connected.
func setup(waves: Array[WaveData], spawn_pos: Vector2) -> void:
	_waves            = waves
	_current_wave_index = -1
	_enemies_alive    = 0
	_wave_in_progress = false
	if not _waypoints.is_empty():
		spawn_pos = _waypoints[0]

	# Pre-load all enemy scenes once so spawning never blocks the main thread.
	_scene_cache.clear()
	for wave in _waves:
		for entry in wave.entries:
			var path: String = entry.enemy_data.scene_path
			if not _scene_cache.has(path) and ResourceLoader.exists(path):
				_scene_cache[path] = load(path)

	# Start preparation countdown → auto-starts wave 1 when it expires.
	_start_countdown(PREP_TIMES[int(GameManager.current_difficulty)])
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
	# ── Kill-streak timer decay ────────────────────────────────
	if _streak_timer > 0.0:
		_streak_timer -= delta
		if _streak_timer <= 0.0:
			_streak_count = 0

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
	_wave_total_enemies = 0
	var interval_mult := SPAWN_INTERVAL_MULT[int(GameManager.current_difficulty)]
	for entry in wave_data.entries:
		_wave_total_enemies += entry.count
		_enemies_alive += entry.count
		for i in range(entry.count):
			var delay := entry.group_delay + i * entry.spawn_interval * interval_mult
			# create_timer respects Engine.time_scale automatically — no manual division needed.
			get_tree().create_timer(delay).timeout.connect(
				func() -> void: _spawn_enemy(entry.enemy_data)
			)
	EventBus.enemy_count_changed.emit(_enemies_alive, _wave_total_enemies)

## Returns a compact enemy-composition string for the given wave (0-based index).
func get_wave_preview_string(wave_index: int) -> String:
	if wave_index < 0 or wave_index >= _waves.size():
		return ""
	var wave: WaveData = _waves[wave_index]
	var counts: Dictionary = {}
	var order: Array[String] = []
	for entry in wave.entries:
		var eid: String = str(entry.enemy_data.enemy_id)
		if not counts.has(eid):
			counts[eid] = 0
			order.append(eid)
		counts[eid] += entry.count
	var parts: PackedStringArray = PackedStringArray()
	for eid in order:
		parts.append("%s×%d" % [ENEMY_ICONS.get(eid, "?"), counts[eid]])
	return "  ".join(parts)

## Returns structured preview entries for the given wave (0-based index).
## Each entry: { "enemy_id": String, "count": int, "sprite_path": String, "color": Color, "name": String }
func get_wave_preview_entries(wave_index: int) -> Array:
	if wave_index < 0 or wave_index >= _waves.size():
		return []
	var wave: WaveData = _waves[wave_index]
	var counts: Dictionary = {}
	var enemy_refs: Dictionary = {}   ## eid → EnemyData reference
	var order: Array[String] = []
	for entry in wave.entries:
		var eid: String = str(entry.enemy_data.enemy_id)
		if not counts.has(eid):
			counts[eid] = 0
			enemy_refs[eid] = entry.enemy_data
			order.append(eid)
		counts[eid] += entry.count
	var result: Array = []
	for eid in order:
		var edata: EnemyData = enemy_refs.get(eid) as EnemyData
		result.append({
			"enemy_id":    eid,
			"count":       counts[eid],
			"sprite_path": ENEMY_SPRITES.get(eid, ""),
			"color":       ENEMY_COLORS.get(eid, Color(1.0, 1.0, 1.0)),
			"name":        edata.enemy_name if edata != null else ENEMY_ICONS.get(eid, "?"),
		})
	return result

## Stop all wave activity when the game ends (prevents late timer callbacks).
func _on_game_ended() -> void:
	_game_ended = true
	_wave_in_progress = false
	_counting_down = false
	_countdown = -1.0

func _spawn_enemy(enemy_data: EnemyData) -> void:
	if _game_ended:
		return
	if enemy_data == null or enemy_data.scene_path.is_empty():
		push_warning("WaveManager: Invalid enemy_data.")
		_enemies_alive -= 1
		_check_wave_complete()
		return
	var packed: PackedScene = _scene_cache.get(enemy_data.scene_path, null) as PackedScene
	if packed == null:
		push_error("WaveManager: Cannot load scene: " + enemy_data.scene_path)
		_enemies_alive -= 1
		_check_wave_complete()
		return
	var enemy: Node = packed.instantiate()
	enemy_container.add_child(enemy)
	if enemy.has_method("setup"):
		var hp_mult: float = DIFFICULTY_HP_MULT[int(GameManager.current_difficulty)]
		enemy.setup(enemy_data, _waypoints, hp_mult)

# ── Wave completion ───────────────────────────────────────────

func _on_enemy_died(_gold: int, _score: int) -> void:
	_enemies_alive = maxi(_enemies_alive - 1, 0)
	if _wave_in_progress:
		EventBus.enemy_count_changed.emit(_enemies_alive, _wave_total_enemies)
	_check_wave_complete()
	## Kill-streak combo tracking
	if _wave_in_progress:
		_streak_timer = STREAK_WINDOW
		_streak_count += 1
		if _streak_count >= STREAK_THRESH and _streak_count % STREAK_THRESH == 0:
			GameManager.add_gold(STREAK_GOLD)
			EventBus.kill_combo_awarded.emit(STREAK_GOLD)

func _on_enemy_reached_end() -> void:
	_enemies_alive = maxi(_enemies_alive - 1, 0)
	if _wave_in_progress:
		EventBus.enemy_count_changed.emit(_enemies_alive, _wave_total_enemies)
	_check_wave_complete()
	## A leak breaks the streak
	_streak_count = 0
	_streak_timer = 0.0

func _check_wave_complete() -> void:
	if _game_ended or _enemies_alive > 0 or not _wave_in_progress:
		return
	_wave_in_progress = false
	EventBus.wave_completed.emit(_current_wave_index + 1)

	if _current_wave_index + 1 >= _waves.size():
		# All waves cleared
		EventBus.all_waves_completed.emit()
		all_waves_done.emit()
	else:
		# Award wave-completion gold bonus (base + skill bonus) and notify HUD
		var total_wave_gold := WAVE_BONUS_GOLD + SkillManager.get_wave_gold_bonus()
		GameManager.add_gold(total_wave_gold)
		EventBus.wave_bonus_awarded.emit(total_wave_gold)
		# Start countdown to next wave
		var next_wave: WaveData = _waves[_current_wave_index + 1]
		var between_time: float = BETWEEN_WAVE_TIMES[int(GameManager.current_difficulty)]
		var wait_time := next_wave.auto_start_delay if next_wave.auto_start_delay >= 0.0 \
						else between_time
		_start_countdown(wait_time)
		# Show "Start Wave N" button so player can skip the countdown
		next_wave_ready.emit(_current_wave_index + 2, _waves.size())
