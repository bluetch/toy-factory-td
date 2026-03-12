## ============================================================
## SaveManager — 存档管理器 (Save / Load Manager)
## ============================================================
## Purpose: Persist and retrieve player progress using a JSON
## file stored in the user data directory.
##
## Save file location: user://save_data.json
##
## Data structure:
## {
##   "unlocked_levels": [1],
##   "high_scores":     {"1": 0, "2": 0, "3": 0},
##   "settings":        {"music_volume": 1.0, "sfx_volume": 1.0}
## }
##
## Call order: load_data() is called automatically in _ready().
## Other autoloads (e.g. AudioManager) should read settings
## after the scene tree is fully initialised.
## ============================================================

extends Node


# ── 常量 (Constants) ──────────────────────────────────────────

## Path to the JSON save file in the user data directory.
const SAVE_PATH: String = "user://save_data.json"

## The set of level IDs that the game supports.
const LEVEL_IDS: Array[int] = [1, 2, 3]


# ── 内部数据 (Internal Data) ──────────────────────────────────

## In-memory copy of the full save document.
## Always access through the public methods below.
var _data: Dictionary = {}


# ── 生命周期 (Lifecycle) ──────────────────────────────────────

func _ready() -> void:
	load_data()


# ── 默认数据 (Default Data) ───────────────────────────────────

## Return a fresh save document with all values at their defaults.
## Called when no save file exists or when the file is corrupted.
func _default_data() -> Dictionary:
	return {
		"unlocked_levels": [1],
		"high_scores": {
			"1": 0,
			"2": 0,
			"3": 0
		},
		"settings": {
			"music_volume": 1.0,
			"sfx_volume":   1.0
		}
	}


# ── 文件 I/O (File I/O) ───────────────────────────────────────

## Write the current in-memory data to disk as formatted JSON.
## Silently fails and logs an error if the file cannot be opened.
func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Cannot open '%s' for writing (error %d)."
				% [SAVE_PATH, FileAccess.get_open_error()])
		return

	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


## Read the save file from disk into _data.
## Creates a default save if the file does not exist or is invalid.
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = _default_data()
		save()  # Write defaults so the file is present next run.
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Cannot open '%s' for reading (error %d). Using defaults."
				% [SAVE_PATH, FileAccess.get_open_error()])
		_data = _default_data()
		return

	var raw_text := file.get_as_text()
	file.close()

	var parsed := JSON.parse_string(raw_text)
	if parsed == null or not parsed is Dictionary:
		push_error("SaveManager: Save file at '%s' is malformed. Resetting to defaults." % SAVE_PATH)
		_data = _default_data()
		save()
		return

	_data = parsed

	# Ensure all expected keys exist (handles save files from older
	# versions of the game that may be missing new fields).
	_migrate_data()


## Fill in any keys that are present in the default document but
## absent from the loaded data. This forward-migrates old saves.
func _migrate_data() -> void:
	var defaults := _default_data()

	for key in defaults:
		if not _data.has(key):
			_data[key] = defaults[key]

	# Ensure every known level has a high-score entry.
	for id in LEVEL_IDS:
		var str_id := str(id)
		if not _data["high_scores"].has(str_id):
			_data["high_scores"][str_id] = 0

	# Ensure every known settings key exists.
	for setting_key in defaults["settings"]:
		if not _data["settings"].has(setting_key):
			_data["settings"][setting_key] = defaults["settings"][setting_key]


# ── 高分操作 (High Score Operations) ─────────────────────────

## Return the stored high score for [param level_id].
## Returns 0 if the level ID is unknown.
func get_high_score(level_id: int) -> int:
	var str_id := str(level_id)
	if _data["high_scores"].has(str_id):
		return int(_data["high_scores"][str_id])
	return 0


## Update the high score for [param level_id] only when
## [param score] exceeds the currently stored value.
## Automatically writes to disk if the record is beaten.
func set_high_score(level_id: int, score: int) -> void:
	var str_id := str(level_id)
	var current: int = get_high_score(level_id)
	if score > current:
		_data["high_scores"][str_id] = score
		save()


# ── 关卡解锁 (Level Unlocking) ────────────────────────────────

## Return [code]true[/code] if the given level has been unlocked.
func is_level_unlocked(level_id: int) -> bool:
	var unlocked: Array = _data.get("unlocked_levels", [1])
	return level_id in unlocked


## Mark [param level_id] as unlocked and persist to disk.
## Has no effect if already unlocked.
func unlock_level(level_id: int) -> void:
	var unlocked: Array = _data.get("unlocked_levels", [1])
	if level_id not in unlocked:
		unlocked.append(level_id)
		_data["unlocked_levels"] = unlocked
		save()


# ── 设置操作 (Settings Operations) ───────────────────────────

## Return the stored float value for [param key].
## Returns 1.0 as a safe default if the key does not exist.
func get_setting(key: String) -> float:
	var settings: Dictionary = _data.get("settings", {})
	if settings.has(key):
		return float(settings[key])
	return 1.0


## Store [param value] for the settings key [param key] and
## persist to disk.
func set_setting(key: String, value: float) -> void:
	if not _data.has("settings"):
		_data["settings"] = {}
	_data["settings"][key] = value
	save()
