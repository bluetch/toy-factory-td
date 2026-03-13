## ============================================================
## GameManager — 游戏状态管理器 (Game State Manager)
## ============================================================
## Purpose: Single source of truth for all runtime game state.
## Owns lives, gold, score, speed, and the current GameState.
## Every mutation goes through a method here so that the
## corresponding EventBus signal is always fired consistently.
##
## Depends on: EventBus (autoload), LevelData resource
## ============================================================

extends Node


# ── 枚举 (Enumerations) ──────────────────────────────────────

## All possible high-level states the game can be in.
enum GameState {
	MAIN_MENU,    ## Showing the main menu, no level loaded.
	LEVEL_SELECT, ## Player is choosing which level to play.
	PLAYING,      ## A level is active and running.
	PAUSED,       ## Level is loaded but time is frozen.
	GAME_OVER,    ## Player ran out of lives.
	VICTORY       ## Player survived all waves.
}

## Difficulty levels selectable on the Level Select screen.
enum Difficulty { EASY, NORMAL, HARD }


# ── 常量 (Constants) ──────────────────────────────────────────

## Available time-scale multipliers cycled by toggle_speed().
const GAME_SPEEDS: Array[float] = [1.0, 2.0]

## Upper bound for the player's life counter.
const MAX_LIVES: int = 20

## Gold multiplier per difficulty (EASY / NORMAL / HARD).
const DIFFICULTY_GOLD_MULT: Array[float] = [1.5, 1.0, 0.7]
## Bonus lives added to starting_lives per difficulty (can be negative).
const DIFFICULTY_LIVES_BONUS: Array[int] = [5, 0, -5]


# ── 运行时属性 (Runtime Properties) ──────────────────────────

## Current state of the game. Read-only externally — use the
## provided methods to transition between states.
var state: GameState = GameState.MAIN_MENU

## Remaining player lives. Triggers game_over() when it hits 0.
var lives: int = MAX_LIVES

## Current spendable gold amount.
var gold: int = 0

## Accumulated score for the current level run.
var score: int = 0

## The level ID (1–3) that is currently loaded / being played.
var current_level_id: int = 1

## Currently selected difficulty. Set from LevelSelect before starting a level.
var current_difficulty: Difficulty = Difficulty.NORMAL

## Current game-speed multiplier. Applied to Engine.time_scale.
var game_speed: float = 1.0

## Internal index into GAME_SPEEDS used by toggle_speed().
var _speed_index: int = 0


# ── 生命周期 (Lifecycle) ──────────────────────────────────────

func _ready() -> void:
	# Nothing to initialise — state begins at MAIN_MENU and all
	# per-level values are set by start_level().
	pass


# ── 关卡管理 (Level Management) ──────────────────────────────

## Load a level by ID, reset all per-run state, and set GameState
## to PLAYING.  Starting values (lives, gold) are read from the
## corresponding LevelData resource at
##   res://data/levels/level_{level_id}.tres
##
## [param level_id] Integer in the range 1–3.
func start_level(level_id: int) -> void:
	current_level_id = level_id

	# ── Load level data resource ──────────────────────────────
	var resource_path := "res://data/levels/level_%d.tres" % level_id
	var level_data: Resource = load(resource_path)

	if level_data == null:
		push_error("GameManager: Could not load LevelData at '%s'. Using defaults." % resource_path)
		lives = MAX_LIVES
		gold  = 150
	else:
		# LevelData is expected to expose `starting_lives: int`
		# and `starting_gold: int` as exported properties.
		var base_lives: int = int(level_data.get("starting_lives") if level_data.get("starting_lives") != null else MAX_LIVES)
		var base_gold: int  = int(level_data.get("starting_gold")  if level_data.get("starting_gold")  != null else 150)
		# Apply difficulty modifiers.
		var diff: int = int(current_difficulty)
		lives = clampi(base_lives + DIFFICULTY_LIVES_BONUS[diff], 1, MAX_LIVES)
		gold  = int(base_gold * DIFFICULTY_GOLD_MULT[diff])

	# ── Reset per-run counters ────────────────────────────────
	score       = 0
	_speed_index = 0
	game_speed  = GAME_SPEEDS[0]

	# Restore normal time scale in case the player restarts from
	# a fast-forwarded or paused session.
	Engine.time_scale = game_speed

	# ── Transition to PLAYING ─────────────────────────────────
	state = GameState.PLAYING

	# Broadcast initial values so all HUD elements can sync.
	EventBus.lives_changed.emit(lives)
	EventBus.gold_changed.emit(gold)
	EventBus.score_changed.emit(score)
	EventBus.game_speed_changed.emit(game_speed)


# ── 金币操作 (Gold Operations) ────────────────────────────────

## Add [param amount] gold to the player's pool and emit the
## gold_changed signal.
func add_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold)


## Returns [code]true[/code] if the player currently has enough gold
## to afford [param amount] without actually spending it.
func can_afford(amount: int) -> bool:
	return gold >= amount


## Attempt to deduct [param amount] gold from the player's pool.
## Returns [code]true[/code] on success, [code]false[/code] if
## there is not enough gold (balance is left unchanged).
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold)
	return true


# ── 分数操作 (Score Operations) ──────────────────────────────

## Add [param amount] to the score and emit score_changed.
func add_score(amount: int) -> void:
	score += amount
	EventBus.score_changed.emit(score)


# ── 生命操作 (Lives Operations) ──────────────────────────────

## Decrement lives by one (minimum 0) and emit lives_changed.
## Triggers game_over() when lives reach zero.
func lose_life() -> void:
	lives = max(0, lives - 1)
	EventBus.lives_changed.emit(lives)

	if lives <= 0:
		game_over()


# ── 游戏结束 / 胜利 (End States) ─────────────────────────────

## Transition to GAME_OVER state. Restores normal time scale so
## the game-over screen is not stuck in fast-forward.
func game_over() -> void:
	if state == GameState.GAME_OVER:
		return  # Guard against double-call.

	state = GameState.GAME_OVER
	get_tree().paused = false
	Engine.time_scale = 1.0

	# Give SaveManager a chance to record if this run somehow
	# scored higher than the previous best (edge case, but safe).
	SaveManager.set_high_score(current_level_id, score)
	SaveManager.save()
	EventBus.game_over_triggered.emit()


## Transition to VICTORY state. Records the high score and
## unlocks the next level if applicable.
func victory() -> void:
	if state == GameState.VICTORY:
		return  # Guard against double-call.

	state = GameState.VICTORY
	get_tree().paused = false
	Engine.time_scale = 1.0

	# Persist progress.
	SaveManager.set_high_score(current_level_id, score)

	var next_level_id := current_level_id + 1
	if next_level_id <= SaveManager.MAX_LEVEL:
		SaveManager.unlock_level(next_level_id)

	SaveManager.save()
	EventBus.victory_triggered.emit()


# ── 速度控制 (Speed Control) ──────────────────────────────────

## Cycle to the next entry in GAME_SPEEDS and apply it to
## Engine.time_scale. Only works while the game is PLAYING.
func toggle_speed() -> void:
	if state != GameState.PLAYING:
		return

	_speed_index = (_speed_index + 1) % GAME_SPEEDS.size()
	game_speed   = GAME_SPEEDS[_speed_index]
	Engine.time_scale = game_speed
	EventBus.game_speed_changed.emit(game_speed)


# ── 暂停控制 (Pause Control) ──────────────────────────────────

## Pause the game: freeze time and emit game_paused.
## Only transitions from PLAYING state.
func pause_game() -> void:
	if state != GameState.PLAYING:
		return

	state = GameState.PAUSED
	Engine.time_scale = 0.0
	get_tree().paused = true
	EventBus.game_paused.emit()


## Resume the game: restore the current game_speed and emit
## game_resumed. Only transitions from PAUSED state.
func resume_game() -> void:
	if state != GameState.PAUSED:
		return

	state = GameState.PLAYING
	get_tree().paused = false
	Engine.time_scale = game_speed
	EventBus.game_resumed.emit()
