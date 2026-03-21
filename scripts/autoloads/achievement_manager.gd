## AchievementManager — tracks gameplay stats and unlocks achievements.
## Operates as an autoload so achievements fire in any scene.
## Shows a toast notification via its own CanvasLayer whenever an achievement is unlocked.
extends Node

## Packed scene used for toast pop-ups (loaded lazily).
const TOAST_SCENE_PATH := "res://scenes/ui/AchievementToast.tscn"

## ── Achievement definitions ─────────────────────────────────
const ACHIEVEMENTS: Dictionary = {
	"first_win":    {"name": "首次勝利",   "desc": "完成第一個關卡",             "icon": "🏆"},
	"iron_defense": {"name": "鋼鐵防線",   "desc": "全命通關（不損失任何生命）", "icon": "🛡"},
	"enemy_100":    {"name": "百戰老兵",   "desc": "累計擊殺 100 個敵人",        "icon": "⚔"},
	"enemy_500":    {"name": "千敵斬",     "desc": "累計擊殺 500 個敵人",        "icon": "💀"},
	"builder":      {"name": "建築師",     "desc": "累計建造 20 座防禦塔",       "icon": "🔧"},
	"completionist":{"name": "全通關",     "desc": "完成全部八個關卡",           "icon": "🌟"},
	"speedrunner":  {"name": "速攻者",     "desc": "以 2 倍速完成任意關卡",     "icon": "⚡"},
	"minimalist":   {"name": "極簡主義",   "desc": "使用 5 座以下防禦塔通關",   "icon": "✨"},
	"flawless_5":   {"name": "無懈可擊",   "desc": "全命通過最終關卡",           "icon": "👑"},
	"veteran":      {"name": "老兵",       "desc": "贏得 10 場戰鬥",             "icon": "🎖"},
	"hard_victor":  {"name": "鋼鐵意志",   "desc": "在困難難度下完成任意關卡",  "icon": "🔥"},
	"skill_master": {"name": "技能大師",   "desc": "單局累積 8 個技能疊層",     "icon": "✨"},
	"rich_victory": {"name": "金庫大王",   "desc": "關卡結束時持有 500 金以上", "icon": "💎"},
	"enemy_1000":   {"name": "萬敵剋星",   "desc": "累計擊殺 1000 個敵人",      "icon": "💀"},
}

## ── Per-level session state ──────────────────────────────────
var _session_towers: int = 0
var _session_enemies: int = 0
var _session_max_lives: int = 0
## Counts lives lost this session — immune to restart exploits
var _session_lives_lost: int = 0

## ── Internal CanvasLayer for toast display ───────────────────
var _toast_canvas: CanvasLayer = null
var _toast_scene: PackedScene = null
var _toast_queue: Array[Array] = []   # Array of [id, name]
var _toast_active: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	# Build a top-layer canvas so toasts appear over every scene.
	_toast_canvas = CanvasLayer.new()
	_toast_canvas.layer = 110
	add_child(_toast_canvas)

	_toast_scene = load(TOAST_SCENE_PATH)

	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.tower_placed.connect(_on_tower_placed)
	EventBus.victory_triggered.connect(_on_victory)
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)

## Call from GameWorld._ready() to reset per-level counters.
func start_level(_level_id: int, initial_lives: int) -> void:
	_session_towers = 0
	_session_enemies = 0
	_session_max_lives = initial_lives
	_session_lives_lost = 0

## Return enemies killed this session (for end-screen display).
func get_session_enemies() -> int:
	return _session_enemies

## Return towers placed this session (for end-screen display).
func get_session_towers() -> int:
	return _session_towers

# ── EventBus listeners ───────────────────────────────────────

func _on_enemy_reached_end() -> void:
	_session_lives_lost += 1

func _on_enemy_died(_gold: int, _score: int) -> void:
	_session_enemies += 1
	_increment_stat("enemies_killed", 1)
	var total := get_stat("enemies_killed")
	if total >= 100:
		_try_unlock("enemy_100")
	if total >= 500:
		_try_unlock("enemy_500")
	if total >= 1000:
		_try_unlock("enemy_1000")

func _on_tower_placed(_tower: Node, _tile: Vector2i) -> void:
	_session_towers += 1
	_increment_stat("towers_placed", 1)
	if get_stat("towers_placed") >= 20:
		_try_unlock("builder")

func _on_victory() -> void:
	_increment_stat("games_won", 1)
	var wins := get_stat("games_won")

	_try_unlock("first_win")

	if wins >= 10:
		_try_unlock("veteran")

	# All levels cleared when the player finishes the final level.
	if SaveManager.is_level_unlocked(SaveManager.MAX_LEVEL - 1) \
			and GameManager.current_level_id == SaveManager.MAX_LEVEL:
		_try_unlock("completionist")

	# iron_defense: zero lives lost this session (restart-exploit-proof)
	if _session_lives_lost == 0:
		_try_unlock("iron_defense")
		if GameManager.current_level_id == SaveManager.MAX_LEVEL:
			_try_unlock("flawless_5")

	if GameManager.game_speed >= 2.0:
		_try_unlock("speedrunner")

	if _session_towers <= 5:
		_try_unlock("minimalist")

	if GameManager.current_difficulty == GameManager.Difficulty.HARD:
		_try_unlock("hard_victor")

	# skill_master: 8+ total skill stacks in one run
	var total_stacks := 0
	for s: SkillData in SkillManager._pool:
		total_stacks += SkillManager.get_skill_stack(s.skill_id)
	if total_stacks >= 8:
		_try_unlock("skill_master")

	# rich_victory: end a level with 500+ gold
	if GameManager.gold >= 500:
		_try_unlock("rich_victory")

# ── Public helpers ───────────────────────────────────────────

func is_unlocked(achievement_id: String) -> bool:
	return SaveManager.is_achievement_unlocked(achievement_id)

func get_stat(key: String) -> int:
	return SaveManager.get_stat_int(key)

# ── Internal helpers ─────────────────────────────────────────

func _increment_stat(key: String, amount: int) -> void:
	SaveManager.set_stat_int(key, get_stat(key) + amount)

func _try_unlock(achievement_id: String) -> void:
	if is_unlocked(achievement_id):
		return
	SaveManager.unlock_achievement(achievement_id)
	var ach: Dictionary = ACHIEVEMENTS.get(achievement_id, {})
	var display_name: String = ach.get("icon", "🏅") + " " + ach.get("name", achievement_id)
	EventBus.achievement_unlocked.emit(achievement_id, display_name)
	_queue_toast(achievement_id, display_name)

func _queue_toast(ach_id: String, ach_name: String) -> void:
	_toast_queue.append([ach_id, ach_name])
	if not _toast_active:
		_show_next_toast()

func _show_next_toast() -> void:
	if _toast_queue.is_empty() or _toast_scene == null:
		_toast_active = false
		return
	_toast_active = true
	var entry: Array = _toast_queue.pop_front()
	var toast: Node = _toast_scene.instantiate()
	_toast_canvas.add_child(toast)
	if toast.has_method("show_achievement"):
		toast.show_achievement(entry[1])
	# Wait for toast to finish (3.5 s) — ignore time_scale and tree pause
	get_tree().create_timer(3.5, true, false, true).timeout.connect(_show_next_toast)
