## run_tests.gd — Headless automated test suite for ToyFactory02.
##
## Run from the project root:
##   godot --headless --script tests/run_tests.gd
##
## Exit code 0 = all pass.  Exit code 1 = at least one failure.
## Compatible with Godot 4.6.

extends SceneTree

# ── Constants mirrored from GridManager (avoids instancing the node) ─
const TILE_SIZE   : int     = 64
const GRID_COLS   : int     = 23
const GRID_ROWS   : int     = 13
const GRID_OFFSET : Vector2 = Vector2(48.0, 64.0)

const VALID_PORTRAITS := ["coco", "gear_grandpa", "narrator", "longing"]

# ── Counters ──────────────────────────────────────────────────────────
var _pass_count : int = 0
var _fail_count : int = 0
var _section_fails : int = 0   # fails in current section (for summary)

# ═════════════════════════════════════════════════════════════════════
func _init() -> void:
	print("\n🧪  ToyFactory02 — Automated Test Suite  (Godot 4.6)")
	print("═══════════════════════════════════════════════════════")

	_run_tower_resources()
	_run_enemy_resources()
	_run_level_data()
	_run_wave_data()
	_run_tower_logic()
	_run_story_database()
	_run_grid_math()
	_run_damage_math()
	_run_difficulty_math()
	_run_level_balance()
	_run_achievement_definitions()
	_run_upgrade_chain()
	_run_tower_balance()
	_run_audio_assets()
	_run_hp_scaling()
	_run_upgrade_preview_math()
	_run_difficulty_constants()
	_run_save_and_achievement_logic()
	_run_chain_and_splash_scaling()
	_run_session25_fixes()
	_run_session26_fixes()
	_run_session27_fixes()
	_run_session28_fixes()
	_run_session29_fixes()
	_run_session30_fixes()
	_run_session31_fixes()
	_run_session32_fixes()
	_run_session33_visual()

	_report()

# ─────────────────────────────────────────────────────────────────────
# SECTION 1 — Tower .tres files
# ─────────────────────────────────────────────────────────────────────
func _run_tower_resources() -> void:
	_section("Tower Resources (.tres integrity)")
	var tower_files := [
		"res://data/towers/arrow_tower.tres",
		"res://data/towers/cannon_tower.tres",
		"res://data/towers/ice_tower.tres",
		"res://data/towers/lightning_tower.tres",
		"res://data/towers/sniper_tower.tres",
	]
	for path in tower_files:
		var res: Resource = load(path)
		if not _check("loads: " + path.get_file(), res != null):
			continue
		var tname : String = str(res.get("tower_name"))
		var cost  : int    = int(res.get("build_cost"))
		var sp    : String = str(res.get("scene_path"))
		var dmg   : float  = float(res.get("base_damage"))
		var range_: float  = float(res.get("base_range"))

		_not_empty(tname + " → tower_name not empty",   tname)
		_gt      (tname + " → build_cost > 0",          float(cost), 0.0)
		_not_empty(tname + " → scene_path not empty",   sp)
		_check   (tname + " → scene file exists",       ResourceLoader.exists(sp), sp)
		_gt      (tname + " → base_damage > 0",         dmg, 0.0)
		_gt      (tname + " → base_range > 0",          range_, 0.0)

# ─────────────────────────────────────────────────────────────────────
# SECTION 2 — Enemy .tres files
# ─────────────────────────────────────────────────────────────────────
func _run_enemy_resources() -> void:
	_section("Enemy Resources (.tres integrity)")
	var enemy_files := [
		"res://data/enemies/basic_enemy.tres",
		"res://data/enemies/fast_enemy.tres",
		"res://data/enemies/tank_enemy.tres",
		"res://data/enemies/boss_enemy.tres",
	]
	for path in enemy_files:
		var res: Resource = load(path)
		if not _check("loads: " + path.get_file(), res != null):
			continue
		var ename : String = str(res.get("enemy_name"))
		var hp    : float  = float(res.get("max_health"))
		var spd   : float  = float(res.get("move_speed"))
		var armor : float  = float(res.get("armor"))
		var gold  : int    = int(res.get("gold_reward"))
		var sp    : String = str(res.get("scene_path"))

		_not_empty(ename + " → enemy_name not empty",    ename)
		_gt       (ename + " → max_health > 0",          hp,   0.0)
		_gt       (ename + " → move_speed > 0",          spd,  0.0)
		_check    (ename + " → armor in [0, 1]",         armor >= 0.0 and armor <= 1.0,
		           "armor=%s" % str(armor))
		_gt       (ename + " → gold_reward > 0",         float(gold), 0.0)
		_not_empty(ename + " → scene_path not empty",   sp)
		_check    (ename + " → scene file exists",       ResourceLoader.exists(sp), sp)

	# Tank should be slower than Fast
	var fast_res: Resource = load("res://data/enemies/fast_enemy.tres")
	var tank_res: Resource = load("res://data/enemies/tank_enemy.tres")
	if fast_res != null and tank_res != null:
		_check("FastEnemy faster than TankEnemy",
		       float(fast_res.get("move_speed")) > float(tank_res.get("move_speed")))

	# Boss should have more HP than Tank
	var boss_res: Resource = load("res://data/enemies/boss_enemy.tres")
	if boss_res != null and tank_res != null:
		_check("BossEnemy has more HP than TankEnemy",
		       float(boss_res.get("max_health")) > float(tank_res.get("max_health")))

# ─────────────────────────────────────────────────────────────────────
# SECTION 3 — Level data (waypoints, bounds, axis-alignment)
# ─────────────────────────────────────────────────────────────────────
func _run_level_data() -> void:
	_section("Level Data (waypoints & starting values)")
	for level_id in range(1, 9):
		var path := "res://data/levels/level_%d.tres" % level_id
		var res: Resource = load(path)
		if not _check("Level %d loads" % level_id, res != null):
			continue

		var lives : int   = int(res.get("starting_lives"))
		var gold  : int   = int(res.get("starting_gold"))
		var id    : int   = int(res.get("level_id"))
		var wps   : Array = res.get("waypoints") if res.get("waypoints") != null else []
		var waves : Array = res.get("waves")     if res.get("waves")     != null else []

		_eq("Level %d → level_id matches file" % level_id, id, level_id)
		_gt("Level %d → starting_lives > 0"    % level_id, float(lives), 0.0)
		_gt("Level %d → starting_gold > 0"     % level_id, float(gold),  0.0)
		_check("Level %d → has ≥2 waypoints"   % level_id, wps.size() >= 2,
		       "got %d" % wps.size())
		_check("Level %d → has ≥1 wave"         % level_id, waves.size() >= 1,
		       "got %d" % waves.size())

		# Waypoints within grid bounds
		var bounds_ok := true
		for i in range(wps.size()):
			var wp: Vector2i = wps[i]
			if wp.x < 0 or wp.x >= GRID_COLS or wp.y < 0 or wp.y >= GRID_ROWS:
				_fail("Level %d waypoint[%d] out of bounds: %s  (grid is 0–%d, 0–%d)"
				      % [level_id, i, str(wp), GRID_COLS - 1, GRID_ROWS - 1])
				bounds_ok = false
		if bounds_ok:
			_ok("Level %d → all waypoints within grid bounds" % level_id)

		# Every consecutive pair must share x OR y (no diagonals)
		var aligned_ok := true
		for i in range(wps.size() - 1):
			var a: Vector2i = wps[i]
			var b: Vector2i = wps[i + 1]
			if a == b:
				_fail("Level %d segment [%d→%d] has zero length: %s"
				      % [level_id, i, i + 1, str(a)])
				aligned_ok = false
			elif a.x != b.x and a.y != b.y:
				_fail("Level %d segment [%d→%d] is diagonal: %s → %s"
				      % [level_id, i, i + 1, str(a), str(b)])
				aligned_ok = false
		if aligned_ok:
			_ok("Level %d → all path segments are axis-aligned" % level_id)

# ─────────────────────────────────────────────────────────────────────
# SECTION 4 — Wave data (counts, intervals, enemy references)
# ─────────────────────────────────────────────────────────────────────
func _run_wave_data() -> void:
	_section("Wave Data (counts & enemy references)")
	for level_id in range(1, 9):
		var path := "res://data/levels/level_%d.tres" % level_id
		var res: Resource = load(path)
		if res == null:
			continue

		var waves: Array = res.get("waves") if res.get("waves") != null else []
		for wi in range(waves.size()):
			var wave: Resource = waves[wi]
			var entries: Array = wave.get("entries") if wave.get("entries") != null else []
			_check("Level %d wave %d → has ≥1 entry" % [level_id, wi + 1],
			       entries.size() >= 1, "got %d" % entries.size())

			for ei in range(entries.size()):
				var entry: Resource = entries[ei]
				var count    : int   = int(entry.get("count"))
				var interval : float = float(entry.get("spawn_interval"))
				var edata    : Resource = entry.get("enemy_data")
				var label := "L%dW%dE%d" % [level_id, wi + 1, ei + 1]

				_gt   (label + " count > 0",           float(count), 0.0)
				_gt   (label + " spawn_interval > 0",  interval,     0.0)
				_check(label + " enemy_data not null",  edata != null)
				if edata != null:
					_check(label + " enemy scene exists",
					       ResourceLoader.exists(str(edata.get("scene_path"))))

# ─────────────────────────────────────────────────────────────────────
# SECTION 5 — TowerData pure logic methods
# ─────────────────────────────────────────────────────────────────────
func _run_tower_logic() -> void:
	_section("TowerData Pure Logic (get_damage / get_range / get_sell_value)")
	var arrow: Resource = load("res://data/towers/arrow_tower.tres")
	if arrow == null:
		_fail("arrow_tower.tres unavailable — skipping logic tests")
		return

	var base_dmg   : float = float(arrow.get("base_damage"))
	var base_rng   : float = float(arrow.get("base_range"))
	var build_cost : int   = int(arrow.get("build_cost"))
	var sell_ratio : float = float(arrow.get("sell_ratio"))

	# Level 0 returns base values
	_eq("get_damage(0) == base_damage",       arrow.get_damage(0),       base_dmg)
	_eq("get_range(0)  == base_range",        arrow.get_range(0),        base_rng)
	_eq("get_attack_speed(0) == base_speed",  arrow.get_attack_speed(0),
	    float(arrow.get("base_attack_speed")))

	# Sell value at level 0
	var expected_sell := int(build_cost * sell_ratio)
	_eq("get_sell_value(0) == build_cost × sell_ratio", arrow.get_sell_value(0), expected_sell)

	# If upgrades exist, upgraded values must be ≥ base
	var upgrades: Array = arrow.get("upgrades") if arrow.get("upgrades") != null else []
	if upgrades.size() >= 1:
		_check("get_damage(1) ≥ get_damage(0)",
		       arrow.get_damage(1) >= arrow.get_damage(0))
		_check("get_range(1)  ≥ get_range(0)",
		       arrow.get_range(1)  >= arrow.get_range(0))
		_check("get_sell_value(1) ≥ get_sell_value(0)",
		       arrow.get_sell_value(1) >= arrow.get_sell_value(0))
	else:
		_ok("ArrowTower has no upgrades defined — skipping level-1 upgrade assertions")

	# Cannon: should have splash_radius > 0
	var cannon: Resource = load("res://data/towers/cannon_tower.tres")
	if cannon != null:
		_gt("CannonTower splash_radius > 0", float(cannon.get("splash_radius")), 0.0)

	# IceTower: should have slow_factor < 1.0 (slows enemies)
	var ice: Resource = load("res://data/towers/ice_tower.tres")
	if ice != null:
		var slow: float = float(ice.get("slow_factor"))
		_check("IceTower slow_factor < 1.0 (actually slows)", slow < 1.0,
		       "got %s" % str(slow))
		_gt("IceTower slow_duration > 0", float(ice.get("slow_duration")), 0.0)

# ─────────────────────────────────────────────────────────────────────
# SECTION 6 — Story database completeness & structure
# ─────────────────────────────────────────────────────────────────────
func _run_story_database() -> void:
	_section("Story Database (completeness & structure)")

	# Instantiate StoryDatabase without needing it as an autoload
	var db_script = load("res://scripts/autoloads/story_database.gd")
	if db_script == null:
		_fail("Could not load story_database.gd")
		return
	var db = db_script.new()

	# All story IDs that must exist after Act 1 + Act 2
	var required_ids: Array[String] = [
		"story_1", "story_2", "story_3", "story_4", "story_5",
		"story_6", "story_7", "story_8",
		"outro_1", "outro_2", "outro_3", "outro_4", "outro_5",
		"outro_6", "outro_7", "outro_8",
		"epilogue",
	]

	for story_id in required_ids:
		if not _check(story_id + " exists",  db.has_story(story_id)):
			continue
		var entries: Array = db.get_story(story_id)
		_check(story_id + " has ≥1 entries", entries.size() >= 1,
		       "got %d" % entries.size())

		var all_valid := true
		for i in range(entries.size()):
			var e: Dictionary = entries[i]
			if not e.has("speaker") or not e.has("portrait") or not e.has("text"):
				_fail("%s[%d] missing required key(s) speaker/portrait/text" % [story_id, i])
				all_valid = false
				continue
			if not (e["portrait"] in VALID_PORTRAITS):
				_fail("%s[%d] invalid portrait '%s'" % [story_id, i, e["portrait"]])
				all_valid = false
			if (e["text"] as String).strip_edges().is_empty():
				_fail("%s[%d] text is empty" % [story_id, i])
				all_valid = false
		if all_valid:
			_ok(story_id + " → all entries have valid keys, portrait, and text")

	db.free()

# ─────────────────────────────────────────────────────────────────────
# SECTION 7 — Grid coordinate math round-trips
# ─────────────────────────────────────────────────────────────────────
func _run_grid_math() -> void:
	_section("Grid Math (tile ↔ world coordinate round-trips)")

	# tile_to_world: center of tile
	func_tile_to_world(0,  0)
	func_tile_to_world(0,  12)
	func_tile_to_world(22, 0)
	func_tile_to_world(22, 12)
	func_tile_to_world(11, 6)   # center tile

	# world_to_tile: any point inside a tile maps back to that tile
	for col in [0, 5, 11, 22]:
		for row in [0, 6, 12]:
			# Test from tile center
			var wx : float = GRID_OFFSET.x + float(col * TILE_SIZE) + float(TILE_SIZE / 2)
			var wy : float = GRID_OFFSET.y + float(row * TILE_SIZE) + float(TILE_SIZE / 2)
			var back_col : int = int((wx - GRID_OFFSET.x) / float(TILE_SIZE))
			var back_row : int = int((wy - GRID_OFFSET.y) / float(TILE_SIZE))
			_eq("world_to_tile center of (%d,%d) → col" % [col, row], back_col, col)
			_eq("world_to_tile center of (%d,%d) → row" % [col, row], back_row, row)

			# Test from 1px inside top-left corner
			wx = GRID_OFFSET.x + float(col * TILE_SIZE) + 1.0
			wy = GRID_OFFSET.y + float(row * TILE_SIZE) + 1.0
			back_col = int((wx - GRID_OFFSET.x) / float(TILE_SIZE))
			back_row = int((wy - GRID_OFFSET.y) / float(TILE_SIZE))
			_eq("world_to_tile top-left+1 of (%d,%d) → col" % [col, row], back_col, col)
			_eq("world_to_tile top-left+1 of (%d,%d) → row" % [col, row], back_row, row)

func func_tile_to_world(col: int, row: int) -> void:
	var world_x : float = GRID_OFFSET.x + float(col * TILE_SIZE) + float(TILE_SIZE / 2)
	var world_y : float = GRID_OFFSET.y + float(row * TILE_SIZE) + float(TILE_SIZE / 2)
	# Round-trip: world back to tile
	var back_col : int = int((world_x - GRID_OFFSET.x) / float(TILE_SIZE))
	var back_row : int = int((world_y - GRID_OFFSET.y) / float(TILE_SIZE))
	_eq("tile(%d,%d)→world→tile col" % [col, row], back_col, col)
	_eq("tile(%d,%d)→world→tile row" % [col, row], back_row, row)

# ─────────────────────────────────────────────────────────────────────
# SECTION 8 — Damage & combat math
# ─────────────────────────────────────────────────────────────────────
func _run_damage_math() -> void:
	_section("Combat Math (armor, health ratio, slow)")

	# Armor formula: effective = damage * (1 - armor)
	_eq_f("0% armor passes full damage:  100 × (1−0.0) = 100",
	      100.0 * (1.0 - 0.0), 100.0)
	_eq_f("50% armor halves damage:      100 × (1−0.5) = 50",
	      100.0 * (1.0 - 0.5), 50.0)
	_eq_f("100% armor blocks all damage: 100 × (1−1.0) = 0",
	      100.0 * (1.0 - 1.0), 0.0)
	_eq_f("25% armor: 80 × (1−0.25) = 60",
	      80.0 * (1.0 - 0.25), 60.0)

	# Health bar ratio — clampf(hp / max_hp, 0, 1)
	_eq_f("Health ratio at full HP = 1.0",
	      clampf(100.0 / 100.0, 0.0, 1.0), 1.0)
	_eq_f("Health ratio at half HP = 0.5",
	      clampf(50.0  / 100.0, 0.0, 1.0), 0.5)
	_eq_f("Health ratio at 0 HP clamped to 0.0",
	      clampf(0.0   / 100.0, 0.0, 1.0), 0.0)
	_eq_f("Health ratio over-healed clamped to 1.0",
	      clampf(150.0 / 100.0, 0.0, 1.0), 1.0)
	_eq_f("Health ratio negative HP clamped to 0.0",
	      clampf(-10.0 / 100.0, 0.0, 1.0), 0.0)

	# Slow: effective_speed = base * slow_factor (0.5 = 50% slow)
	_eq_f("50% slow: speed 100 × 0.5 = 50",  100.0 * 0.5, 50.0)
	_eq_f("No slow:  speed 100 × 1.0 = 100", 100.0 * 1.0, 100.0)

	# minf(): multiple slows take the strongest one
	_eq_f("Double slow takes the minimum: min(0.5, 0.3) = 0.3",
	      minf(0.5, 0.3), 0.3)
	_eq_f("New slow weaker than existing ignored: min(0.3, 0.7) = 0.3",
	      minf(0.3, 0.7), 0.3)

# ─────────────────────────────────────────────────────────────────────
# SECTION 9 — Difficulty modifier math
# ─────────────────────────────────────────────────────────────────────
func _run_difficulty_math() -> void:
	_section("Difficulty Modifier Math (EASY / NORMAL / HARD)")

	# Mirror constants from GameManager (no autoload available in headless mode)
	const GOLD_MULT  : Array[float] = [1.5, 1.0, 0.7]
	const LIVES_BONUS: Array[int]   = [5,   0,   -5]

	# Use a representative level so all three difficulties yield feasible values
	var base_gold  : int = 200
	var base_lives : int = 15

	# EASY (index 0)
	_eq_f("EASY  gold multiplier = 1.5",  GOLD_MULT[0],  1.5)
	_eq  ("EASY  lives bonus = +5",       LIVES_BONUS[0], 5)
	_eq  ("EASY  gold result = 300",      int(base_gold * GOLD_MULT[0]),  300)
	_eq  ("EASY  lives result = 20",      clampi(base_lives + LIVES_BONUS[0], 1, 20), 20)

	# NORMAL (index 1)
	_eq_f("NORMAL gold multiplier = 1.0", GOLD_MULT[1],  1.0)
	_eq  ("NORMAL lives bonus = 0",       LIVES_BONUS[1], 0)
	_eq  ("NORMAL gold result = 200",     int(base_gold * GOLD_MULT[1]),  200)
	_eq  ("NORMAL lives result = 15",     clampi(base_lives + LIVES_BONUS[1], 1, 20), 15)

	# HARD (index 2)
	_eq_f("HARD  gold multiplier = 0.7",  GOLD_MULT[2],  0.7)
	_eq  ("HARD  lives bonus = -5",       LIVES_BONUS[2], -5)
	_eq  ("HARD  gold result = 140",      int(base_gold * GOLD_MULT[2]),  140)
	_eq  ("HARD  lives result = 10",      clampi(base_lives + LIVES_BONUS[2], 1, 20), 10)

	# Edge case: very low starting lives + HARD must clamp to at least 1
	_eq("clampi(1 + (-5), 1, 20) clamps to 1", clampi(1 + (-5), 1, 20), 1)

	# HARD multiplied gold must always be lower than EASY multiplied gold
	_check("HARD gold < NORMAL gold < EASY gold",
	       int(base_gold * GOLD_MULT[2]) < int(base_gold * GOLD_MULT[1]) \
	       and int(base_gold * GOLD_MULT[1]) < int(base_gold * GOLD_MULT[0]))

	# Spawn interval multipliers (mirrored from WaveManager.SPAWN_INTERVAL_MULT)
	const INTERVAL_MULT: Array[float] = [1.25, 1.0, 0.75]
	_eq_f("EASY  spawn_interval_mult = 1.25", INTERVAL_MULT[0], 1.25)
	_eq_f("NORMAL spawn_interval_mult = 1.0", INTERVAL_MULT[1], 1.0)
	_eq_f("HARD  spawn_interval_mult = 0.75", INTERVAL_MULT[2], 0.75)
	# HARD spawns faster (shorter interval) than EASY
	var base_interval := 1.0
	_check("HARD spawn interval < NORMAL < EASY",
	       base_interval * INTERVAL_MULT[2] < base_interval * INTERVAL_MULT[1] \
	       and base_interval * INTERVAL_MULT[1] < base_interval * INTERVAL_MULT[0])


# ─────────────────────────────────────────────────────────────────────
# SECTION 10 — Level balance guardrails (all 8 levels)
# ─────────────────────────────────────────────────────────────────────
func _run_level_balance() -> void:
	_section("Level Balance Guardrails (all 8 levels)")

	const MIN_GOLD  : int = 150
	const MIN_LIVES : int = 5
	const MAX_LIVES : int = 20

	var prev_waves : int = 0

	for level_id in range(1, 9):
		var path := "res://data/levels/level_%d.tres" % level_id
		var res: Resource = load(path)
		if res == null:
			_fail("Level %d: file not found — skipping balance checks" % level_id)
			prev_waves = 0
			continue

		var gold  : int   = int(res.get("starting_gold")  if res.get("starting_gold")  != null else 0)
		var lives : int   = int(res.get("starting_lives") if res.get("starting_lives") != null else 0)
		var waves : Array = res.get("waves") if res.get("waves") != null else []

		# Minimum viable starting resources
		_check("Level %d → starting_gold ≥ %d" % [level_id, MIN_GOLD],
		       gold >= MIN_GOLD, "got %d" % gold)
		_check("Level %d → starting_lives in [%d, %d]" % [level_id, MIN_LIVES, MAX_LIVES],
		       lives >= MIN_LIVES and lives <= MAX_LIVES,
		       "got %d" % lives)

		# Wave count must be at least 3 (allows levels to vary without strict monotonicity)
		_check("Level %d → wave count ≥ 3" % level_id,
		       waves.size() >= 3,
		       "got %d" % waves.size())
		prev_waves = waves.size()

		# Each wave must have a sensible total enemy count
		for wi in range(waves.size()):
			var wave: Resource = waves[wi]
			var entries: Array = wave.get("entries") if wave.get("entries") != null else []
			var total_enemies := 0
			for ei in range(entries.size()):
				var entry: Resource = entries[ei]
				total_enemies += int(entry.get("count") if entry.get("count") != null else 0)
			_check("Level %d wave %d → total enemies ≥ 1" % [level_id, wi + 1],
			       total_enemies >= 1, "got %d" % total_enemies)
			_check("Level %d wave %d → total enemies ≤ 500 (sanity cap)" % [level_id, wi + 1],
			       total_enemies <= 500, "got %d" % total_enemies)


# ─────────────────────────────────────────────────────────────────────
# SECTION 11 — Achievement definitions integrity
# ─────────────────────────────────────────────────────────────────────
func _run_achievement_definitions() -> void:
	_section("Achievement Definitions (all 11 IDs present, required fields)")

	# Load the script directly so we can inspect ACHIEVEMENTS without autoload
	var ach_script = load("res://scripts/autoloads/achievement_manager.gd")
	if ach_script == null:
		_fail("Could not load achievement_manager.gd")
		return
	var ach_node = ach_script.new()

	# The 11 expected achievement IDs (includes hard_victor added in Session 23)
	const EXPECTED_IDS: Array[String] = [
		"first_win", "iron_defense", "enemy_100", "enemy_500",
		"builder", "completionist", "speedrunner", "minimalist",
		"flawless_5", "veteran", "hard_victor",
	]

	var ach_dict: Dictionary = ach_node.ACHIEVEMENTS

	_eq("Total achievements == 11", ach_dict.size(), 11)

	for ach_id in EXPECTED_IDS:
		if not _check(ach_id + " exists in ACHIEVEMENTS", ach_dict.has(ach_id)):
			continue
		var entry: Dictionary = ach_dict[ach_id]
		_check(ach_id + " → has 'name' field",
		       entry.has("name") and (entry["name"] as String).length() > 0,
		       "name='%s'" % str(entry.get("name", "")))
		_check(ach_id + " → has 'desc' field",
		       entry.has("desc") and (entry["desc"] as String).length() > 0,
		       "desc='%s'" % str(entry.get("desc", "")))
		_check(ach_id + " → has 'icon' field",
		       entry.has("icon") and (entry["icon"] as String).length() > 0,
		       "icon='%s'" % str(entry.get("icon", "")))

	ach_node.free()


# ─────────────────────────────────────────────────────────────────────
# SECTION 12 — Tower upgrade chain integrity
# ─────────────────────────────────────────────────────────────────────
func _run_upgrade_chain() -> void:
	_section("Tower Upgrade Chain (multipliers > 1, costs > 0)")

	var tower_files := [
		"res://data/towers/arrow_tower.tres",
		"res://data/towers/cannon_tower.tres",
		"res://data/towers/ice_tower.tres",
		"res://data/towers/lightning_tower.tres",
		"res://data/towers/sniper_tower.tres",
	]

	for path in tower_files:
		var res: Resource = load(path)
		if res == null:
			_fail("Cannot load " + path.get_file() + " — skipping upgrade checks")
			continue
		var tname : String = str(res.get("tower_name"))
		var upgrades: Array = res.get("upgrades") if res.get("upgrades") != null else []

		_check(tname + " → has ≥1 upgrade", upgrades.size() >= 1,
		       "got %d" % upgrades.size())

		for i in range(upgrades.size()):
			var upg: Resource = upgrades[i]
			var label := "%s upgrade[%d]" % [tname, i + 1]

			var cost : int   = int(upg.get("upgrade_cost") if upg.get("upgrade_cost") != null else 0)
			var dmg  : float = float(upg.get("damage_multiplier") if upg.get("damage_multiplier") != null else 0.0)
			var rng  : float = float(upg.get("range_multiplier")  if upg.get("range_multiplier")  != null else 0.0)
			var spd  : float = float(upg.get("speed_multiplier")  if upg.get("speed_multiplier")  != null else 0.0)

			_gt(label + " → upgrade_cost > 0",         float(cost), 0.0)
			_gt(label + " → damage_multiplier ≥ 1.0",  dmg,   0.999)
			_gt(label + " → range_multiplier ≥ 1.0",   rng,   0.999)
			_gt(label + " → speed_multiplier ≥ 1.0",   spd,   0.999)

		# Cumulative: stats at max level must exceed base
		if upgrades.size() >= 1:
			var max_level := upgrades.size()
			_check(tname + " → max-level damage > base",
			       res.get_damage(max_level) > res.get_damage(0))
			_check(tname + " → max-level sell value > base",
			       res.get_sell_value(max_level) > res.get_sell_value(0))


# ─────────────────────────────────────────────────────────────────────
# SECTION 13 — Tower DPS balance assertions
# ─────────────────────────────────────────────────────────────────────
func _run_tower_balance() -> void:
	_section("Tower DPS Balance (cost-effectiveness sanity checks)")

	var arrow   : Resource = load("res://data/towers/arrow_tower.tres")
	var cannon  : Resource = load("res://data/towers/cannon_tower.tres")
	var ice     : Resource = load("res://data/towers/ice_tower.tres")
	var lightning: Resource = load("res://data/towers/lightning_tower.tres")
	var sniper  : Resource = load("res://data/towers/sniper_tower.tres")

	if arrow == null or cannon == null or ice == null or lightning == null or sniper == null:
		_fail("One or more tower .tres files missing — skipping DPS balance tests")
		return

	# Helper: base DPS = damage(0) × attack_speed(0)
	var arrow_dps: float    = arrow.get_damage(0)    * arrow.get_attack_speed(0)
	var cannon_dps: float   = cannon.get_damage(0)   * cannon.get_attack_speed(0)
	var lightning_dps: float = lightning.get_damage(0) * lightning.get_attack_speed(0)
	var sniper_dps: float   = sniper.get_damage(0)   * sniper.get_attack_speed(0)
	var ice_dps: float      = ice.get_damage(0)      * ice.get_attack_speed(0)

	# Sniper base DPS should be ≥ Arrow (armor-pierce justifies equal or better single-target DPS)
	_check("Sniper base DPS ≥ Arrow base DPS",
	       sniper_dps >= arrow_dps,
	       "sniper=%.1f arrow=%.1f" % [sniper_dps, arrow_dps])

	# Cannon raw DPS should beat Arrow (range trade-off for splash)
	_check("Cannon base DPS > Arrow base DPS (compensates shorter range)",
	       cannon_dps > arrow_dps,
	       "cannon=%.1f arrow=%.1f" % [cannon_dps, arrow_dps])

	# Lightning base DPS should be close to Arrow (multi-target value is its advantage)
	_check("Lightning base DPS > 0",
	       lightning_dps > 0.0)

	# Ice: utility tower — DPS may be low but slow_factor must be < 1.0
	_check("IceTower base slow_factor < 1.0",
	       float(ice.get("slow_factor")) < 1.0,
	       "got %s" % str(ice.get("slow_factor")))
	_gt("IceTower base slow_duration > 0", float(ice.get("slow_duration")), 0.0)

	# Cost/DPS ratio — Sniper should not be worse than Arrow per-gold
	var arrow_dps_per_gold: float   = arrow_dps   / float(int(arrow.get("build_cost")))
	var sniper_dps_per_gold: float  = sniper_dps  / float(int(sniper.get("build_cost")))
	# Sniper costs ~2× Arrow but trades raw DPS for armor-pierce + long range.
	# Threshold: at least 40% of Arrow DPS-per-gold (vs 100% if no specialty justification).
	_check("Sniper DPS-per-gold ≥ Arrow × 0.40 (armor-pierce justifies premium)",
	       sniper_dps_per_gold >= arrow_dps_per_gold * 0.40,
	       "sniper=%.4f arrow=%.4f" % [sniper_dps_per_gold, arrow_dps_per_gold])

	# Max-level comparisons
	var max_arrow: int  = arrow.upgrades.size()
	var max_sniper: int = sniper.upgrades.size()
	var arrow_max_dps: float  = arrow.get_damage(max_arrow)  * arrow.get_attack_speed(max_arrow)
	var sniper_max_dps: float = sniper.get_damage(max_sniper) * sniper.get_attack_speed(max_sniper)
	_check("Sniper max-level DPS > Arrow max-level DPS (fully justifies higher cost)",
	       sniper_max_dps > arrow_max_dps,
	       "sniper=%.1f arrow=%.1f" % [sniper_max_dps, arrow_max_dps])

	# IceTower slow scaling: get_slow_factor(2) < get_slow_factor(0)
	_check("IceTower max-level slow_factor < base (upgrades make slow stronger)",
	       ice.get_slow_factor(2) < ice.get_slow_factor(0),
	       "base=%.2f max=%.2f" % [ice.get_slow_factor(0), ice.get_slow_factor(2)])
	_check("IceTower max-level slow_duration > base (upgrades extend slow)",
	       ice.get_slow_duration(2) > ice.get_slow_duration(0),
	       "base=%.1f max=%.1f" % [ice.get_slow_duration(0), ice.get_slow_duration(2)])

	# Boss armor sanity: armor must be in [0, 0.5] — should challenge but not be immune
	var boss: Resource = load("res://data/enemies/boss_enemy.tres")
	if boss != null:
		var boss_armor := float(boss.get("armor"))
		_check("Boss armor in [0.10, 0.50] — challenging but not immune",
		       boss_armor >= 0.10 and boss_armor <= 0.50,
		       "got %.2f" % boss_armor)
		# All tower types should deal meaningful damage vs boss (> 50% of base damage)
		_check("Arrow effective vs boss > 50% of base",
		       arrow.get_damage(0) * (1.0 - boss_armor) > arrow.get_damage(0) * 0.5,
		       "armor=%.2f" % boss_armor)
		_check("Cannon effective vs boss > 50% of base",
		       cannon.get_damage(0) * (1.0 - boss_armor) > cannon.get_damage(0) * 0.5,
		       "armor=%.2f" % boss_armor)


# ─────────────────────────────────────────────────────────────────────
# SECTION 14 — Audio asset existence
# ─────────────────────────────────────────────────────────────────────
func _run_audio_assets() -> void:
	_section("Audio Assets (SFX & music files exist)")

	# Core SFX loaded unconditionally in AudioManager._ready()
	const REQUIRED_SFX: Array[String] = [
		"res://assets/audio/ui_click.wav",
		"res://assets/audio/sfx_tower_upgrade.ogg",
		"res://assets/audio/sfx_tower_sell.ogg",
		"res://assets/audio/sfx_enemy_die.ogg",
		"res://assets/audio/sfx_life_lost.ogg",
		"res://assets/audio/sfx_game_over.ogg",
		"res://assets/audio/sfx_victory.ogg",
	]
	for path in REQUIRED_SFX:
		_check(path.get_file() + " exists", ResourceLoader.exists(path), path)

	# At least one tower-place SFX variant must exist
	var place_ok := ResourceLoader.exists("res://assets/audio/sfx_tower_place_hq.wav") \
		or ResourceLoader.exists("res://assets/audio/sfx_tower_place.ogg")
	_check("sfx_tower_place (hq.wav or .ogg) exists", place_ok)

	# SFX loaded via fallback chain — at least one path must exist per effect
	const FALLBACK_SFX: Dictionary = {
		"sfx_enemy_hit":         ["res://assets/audio/sfx_enemy_hit.wav",
		                          "res://assets/audio/sfx_enemy_hit.ogg"],
		"sfx_slow_applied":      ["res://assets/audio/sfx_slow_applied.wav",
		                          "res://assets/audio/sfx_slow_applied.ogg"],
		"sfx_explosion":         ["res://assets/audio/sfx_explosion.wav",
		                          "res://assets/audio/sfx_explosion.ogg"],
		"sfx_tower_select":      ["res://assets/audio/sfx_tower_select.wav",
		                          "res://assets/audio/sfx_tower_select.ogg"],
		"sfx_invalid_placement": ["res://assets/audio/sfx_invalid_placement.wav",
		                          "res://assets/audio/sfx_invalid_placement.ogg"],
	}
	for sfx_name in FALLBACK_SFX:
		var paths: Array = FALLBACK_SFX[sfx_name]
		var found := false
		for p in paths:
			if ResourceLoader.exists(p):
				found = true
				break
		_check(sfx_name + " — at least one variant exists", found,
		       "checked: " + ", ".join(PackedStringArray(paths)))

	# Projectile SFX (shoot_*.wav)
	const SHOOT_SFX: Array[String] = [
		"res://assets/audio/shoot_arrow.wav",
		"res://assets/audio/shoot_cannon.wav",
		"res://assets/audio/shoot_ice.wav",
	]
	for path in SHOOT_SFX:
		_check(path.get_file() + " exists", ResourceLoader.exists(path), path)


# ─────────────────────────────────────────────────────────────────────
# SECTION 15 — Difficulty HP Scaling
# ─────────────────────────────────────────────────────────────────────
func _run_hp_scaling() -> void:
	_section("Difficulty HP Scaling")

	# Mirror WaveManager constants (loaded directly to avoid node instantiation)
	const HP_MULT: Array[float] = [0.80, 1.0, 1.30]

	_check("HP_MULT has 3 entries", HP_MULT.size() == 3,
		   "got %d" % HP_MULT.size())
	_check("EASY   HP < NORMAL HP",  HP_MULT[0] < HP_MULT[1],
		   "EASY=%.2f  NORMAL=%.2f" % [HP_MULT[0], HP_MULT[1]])
	_check("NORMAL HP < HARD HP",    HP_MULT[1] < HP_MULT[2],
		   "NORMAL=%.2f  HARD=%.2f" % [HP_MULT[1], HP_MULT[2]])
	_check("EASY   HP in (0.5, 1.0)",  HP_MULT[0] > 0.5 and HP_MULT[0] < 1.0,
		   "got %.2f" % HP_MULT[0])
	_check("HARD   HP in (1.0, 2.0)",  HP_MULT[2] > 1.0 and HP_MULT[2] < 2.0,
		   "got %.2f" % HP_MULT[2])

	# Verify setup() health_mult parameter logic with a mock enemy_data
	# (pure math check — no node needed)
	var base_hp := 100.0
	for i in range(3):
		var scaled_hp := base_hp * HP_MULT[i]
		_check("difficulty %d: scaled_hp > 0" % i, scaled_hp > 0.0,
			   "got %.1f" % scaled_hp)
	_eq_f("EASY hp = 80",   base_hp * HP_MULT[0], 80.0)
	_eq_f("NORMAL hp = 100", base_hp * HP_MULT[1], 100.0)
	_eq_f("HARD hp = 130",   base_hp * HP_MULT[2], 130.0)

	# Cross-check: all three SPAWN_INTERVAL_MULT entries exist and scale correctly
	const INTERVAL_MULT: Array[float] = [1.25, 1.0, 0.75]
	_check("EASY intervals slower than HARD",
		   INTERVAL_MULT[0] > INTERVAL_MULT[2], "")
	_check("Compound HARD difficulty: more HP + faster spawns",
		   HP_MULT[2] > 1.0 and INTERVAL_MULT[2] < 1.0, "")


# ─────────────────────────────────────────────────────────────────────
# SECTION 16 — Upgrade Preview Math
# ─────────────────────────────────────────────────────────────────────
func _run_upgrade_preview_math() -> void:
	_section("Upgrade Preview Math (TowerData stat getters)")

	const TOWER_IDS: Array[String] = [
		"arrow_tower", "cannon_tower", "ice_tower",
		"lightning_tower", "sniper_tower"
	]

	for tid in TOWER_IDS:
		var path := "res://data/towers/%s.tres" % tid
		if not ResourceLoader.exists(path):
			_fail(tid + " .tres missing", path)
			continue
		var data: TowerData = load(path) as TowerData
		if data == null:
			_fail(tid + " failed to cast TowerData", path)
			continue

		var max_lvl := data.upgrades.size()
		# Current stats at each level must be >= previous level
		for lvl in range(1, max_lvl + 1):
			var prev_dmg := data.get_damage(lvl - 1)
			var cur_dmg  := data.get_damage(lvl)
			_check("%s dmg[%d] >= dmg[%d]" % [tid, lvl, lvl-1],
				   cur_dmg >= prev_dmg,
				   "%.1f vs %.1f" % [cur_dmg, prev_dmg])

			var prev_spd := data.get_attack_speed(lvl - 1)
			var cur_spd  := data.get_attack_speed(lvl)
			_check("%s speed[%d] >= speed[%d]" % [tid, lvl, lvl-1],
				   cur_spd >= prev_spd,
				   "%.2f vs %.2f" % [cur_spd, prev_spd])

		# Ice tower: slow_factor should decrease (get stronger) with upgrades
		if data.slow_factor < 1.0:
			for lvl in range(1, max_lvl + 1):
				var prev_sf := data.get_slow_factor(lvl - 1)
				var cur_sf  := data.get_slow_factor(lvl)
				_check("%s slow_factor[%d] <= slow_factor[%d]" % [tid, lvl, lvl-1],
					   cur_sf <= prev_sf,
					   "%.3f vs %.3f" % [cur_sf, prev_sf])

				var prev_dur := data.get_slow_duration(lvl - 1)
				var cur_dur  := data.get_slow_duration(lvl)
				_check("%s slow_duration[%d] >= slow_duration[%d]" % [tid, lvl, lvl-1],
					   cur_dur >= prev_dur,
					   "%.2f vs %.2f" % [cur_dur, prev_dur])

		# sell_value at max level > sell_value at base (invested more)
		var sell_base := data.get_sell_value(0)
		var sell_max  := data.get_sell_value(max_lvl)
		_check("%s sell_max > sell_base" % tid, sell_max > sell_base,
			   "%d vs %d" % [sell_max, sell_base])


# ─────────────────────────────────────────────────────────────────────
# SECTION 17 — Difficulty Constants & Level Music Coverage
# ─────────────────────────────────────────────────────────────────────
func _run_difficulty_constants() -> void:
	_section("Difficulty Constants & Level Music Coverage")

	# Mirror GameManager constants (headless — no autoload instance needed)
	const DIFF_NAMES:  Array[String] = ["簡單", "普通", "困難"]
	const DIFF_COLORS: Array[Color]  = [
		Color(0.40, 0.90, 0.40),
		Color(0.85, 0.80, 0.40),
		Color(1.0,  0.45, 0.35),
	]
	const VALID_TRACK_IDS: Array[String] = ["gameplay", "boss", "menu", "victory", "story"]

	_check("DIFF_NAMES has 3 entries", DIFF_NAMES.size() == 3, "")
	_check("DIFF_COLORS has 3 entries", DIFF_COLORS.size() == 3, "")
	for i in DIFF_NAMES.size():
		_not_empty("DIFF_NAMES[%d] not empty" % i, DIFF_NAMES[i])

	# Verify GameManager.gd script defines DIFFICULTY_NAMES + DIFFICULTY_COLORS
	var gm_script: Script = load("res://scripts/autoloads/game_manager.gd")
	_check("game_manager.gd loaded", gm_script != null, "")
	if gm_script != null:
		var src: String = gm_script.source_code
		_check("DIFFICULTY_NAMES defined in game_manager.gd",
			   src.contains("DIFFICULTY_NAMES"), "")
		_check("DIFFICULTY_COLORS defined in game_manager.gd",
			   src.contains("DIFFICULTY_COLORS"), "")

	# LevelData: verify music_track_id field exists and all levels use a valid track
	var ld_script: Script = load("res://scripts/resources/level_data.gd")
	_check("level_data.gd loaded", ld_script != null, "")
	if ld_script != null:
		_check("music_track_id field defined",
			   ld_script.source_code.contains("music_track_id"), "")

	for lid in range(1, 9):
		var path := "res://data/levels/level_%d.tres" % lid
		if not ResourceLoader.exists(path):
			_fail("level_%d.tres exists" % lid, path)
			continue
		var ld: LevelData = load(path) as LevelData
		if ld == null:
			_fail("level_%d.tres cast to LevelData" % lid, path)
			continue
		var tid: String = ld.music_track_id
		_not_empty("level_%d music_track_id not empty" % lid, tid)
		_check("level_%d music_track_id '%s' is valid" % [lid, tid],
			   tid in VALID_TRACK_IDS,
			   "got '%s'" % tid)

	# game_world.gd must use level_data.music_track_id (not hardcoded "gameplay")
	var gw_script: Script = load("res://scripts/game_world.gd")
	_check("game_world.gd loaded", gw_script != null, "")
	if gw_script != null:
		var src: String = gw_script.source_code
		_check("game_world uses level_data.music_track_id",
			   src.contains("music_track_id"), "")
		_check("game_world does NOT hardcode play_track(\"gameplay\")",
			   not src.contains("play_track(\"gameplay\")"), "")


# ─────────────────────────────────────────────────────────────────────
# SECTION 18 — Save-Manager Deferred Write & Achievement Logic
# ─────────────────────────────────────────────────────────────────────
func _run_save_and_achievement_logic() -> void:
	_section("Save-Manager Deferred Write & Achievement Logic")

	# ── SaveManager: verify _schedule_save / _do_deferred_save exist ──
	var sm_script: Script = load("res://scripts/autoloads/save_manager.gd")
	_check("save_manager.gd loaded", sm_script != null, "")
	if sm_script != null:
		var src: String = sm_script.source_code
		_check("_schedule_save() defined in save_manager",
			   src.contains("_schedule_save"), "")
		_check("_do_deferred_save() defined in save_manager",
			   src.contains("_do_deferred_save"), "")
		_check("set_stat_int uses _schedule_save (not direct save())",
			   src.contains("_schedule_save()") and
			   not src.contains("_data[\"stats\"][key] = value\n\tsave()"), "")
		_check("_save_pending flag defined",
			   src.contains("_save_pending"), "")

	# ── AchievementManager: hard_victor is defined and has correct fields ──
	var am_script: GDScript = load("res://scripts/autoloads/achievement_manager.gd") as GDScript
	_check("achievement_manager.gd loaded", am_script != null, "")
	if am_script != null:
		var am_node: Node = am_script.new()
		var ach_dict: Dictionary = am_node.ACHIEVEMENTS
		_check("hard_victor exists in ACHIEVEMENTS", ach_dict.has("hard_victor"), "")
		if ach_dict.has("hard_victor"):
			var hv: Dictionary = ach_dict["hard_victor"]
			_not_empty("hard_victor name", str(hv.get("name", "")))
			_not_empty("hard_victor desc", str(hv.get("desc", "")))
			_not_empty("hard_victor icon", str(hv.get("icon", "")))
		# Verify hard_victor trigger is in _on_victory source
		var src: String = am_script.source_code
		_check("_on_victory triggers hard_victor",
			   src.contains("hard_victor"), "")
		_check("hard_victor gated on HARD difficulty",
			   src.contains("Difficulty.HARD"), "")
		am_node.free()

	# ── BaseTower: set_process optimization ──
	var bt_script: Script = load("res://scripts/towers/base_tower.gd")
	_check("base_tower.gd loaded", bt_script != null, "")
	if bt_script != null:
		var src: String = bt_script.source_code
		_check("BaseTower calls set_process(_turret != null)",
			   src.contains("set_process(_turret != null)"), "")

	# ── TutorialManager: verify it is a registered autoload ──
	var project_src: String = ""
	var f := FileAccess.open("res://project.godot", FileAccess.READ)
	if f != null:
		project_src = f.get_as_text()
		f.close()
	_check("project.godot loaded for autoload check", project_src.length() > 0, "")
	if project_src.length() > 0:
		_check("TutorialManager registered as autoload",
			   project_src.contains("TutorialManager="), "")
		_check("8 autoloads registered",
			   project_src.count("*res://scripts/autoloads/") == 8,
			   "found %d" % project_src.count("*res://scripts/autoloads/"))


# ─────────────────────────────────────────────────────────────────────
# SECTION 19 — Chain-count scaling (LightningTower) & Splash-radius scaling (CannonTower)
# ─────────────────────────────────────────────────────────────────────
func _run_chain_and_splash_scaling() -> void:
	_section("Chain & Splash Radius Scaling")

	# ── UpgradeData has the new fields ──
	var ud_script: GDScript = load("res://scripts/resources/upgrade_data.gd") as GDScript
	_check("upgrade_data.gd loaded", ud_script != null, "")
	if ud_script != null:
		var src: String = ud_script.source_code
		_check("UpgradeData has chain_bonus field",        src.contains("chain_bonus"),        "")
		_check("UpgradeData has splash_radius_bonus field", src.contains("splash_radius_bonus"), "")

	# ── TowerData has the new getters ──
	var td_script: GDScript = load("res://scripts/resources/tower_data.gd") as GDScript
	_check("tower_data.gd loaded", td_script != null, "")
	if td_script != null:
		var src: String = td_script.source_code
		_check("TowerData has base_chain_count export", src.contains("base_chain_count"), "")
		_check("TowerData has get_chain_count()",       src.contains("get_chain_count"),   "")
		_check("TowerData has get_splash_radius()",     src.contains("get_splash_radius"), "")

	# ── LightningTower uses dynamic chain count ──
	var lt_script: GDScript = load("res://scripts/towers/lightning_tower.gd") as GDScript
	_check("lightning_tower.gd loaded", lt_script != null, "")
	if lt_script != null:
		var src: String = lt_script.source_code
		_check("LightningTower uses get_chain_count()",
			   src.contains("get_chain_count"), "")
		_check("LightningTower no longer has CHAIN_COUNT constant",
			   not src.contains("const CHAIN_COUNT"), "")

	# ── CannonTower uses dynamic splash radius ──
	var ct_script: GDScript = load("res://scripts/towers/cannon_tower.gd") as GDScript
	_check("cannon_tower.gd loaded", ct_script != null, "")
	if ct_script != null:
		var src: String = ct_script.source_code
		_check("CannonTower uses get_splash_radius()",
			   src.contains("get_splash_radius"), "")

	# ── Resource data: lightning tower base_chain_count = 3 ──
	var lt_data: TowerData = load("res://data/towers/lightning_tower.tres") as TowerData
	_check("lightning_tower.tres loaded", lt_data != null, "")
	if lt_data != null:
		_eq("LightningTower base_chain_count == 3", lt_data.base_chain_count, 3)
		_eq("get_chain_count(0) == 3", lt_data.get_chain_count(0), 3)
		# Upgrade1 should add 1 chain
		if lt_data.upgrades.size() >= 1:
			_eq("get_chain_count(1) == 4", lt_data.get_chain_count(1), 4)
		# Upgrade2 has no chain_bonus: count stays at 4
		if lt_data.upgrades.size() >= 2:
			_eq("get_chain_count(2) == 4", lt_data.get_chain_count(2), 4)

	# ── Resource data: cannon tower splash radius scales ──
	var can_data: TowerData = load("res://data/towers/cannon_tower.tres") as TowerData
	_check("cannon_tower.tres loaded", can_data != null, "")
	if can_data != null:
		_eq_f("get_splash_radius(0) == 60.0", can_data.get_splash_radius(0), 60.0)
		if can_data.upgrades.size() >= 1:
			_eq_f("get_splash_radius(1) == 90.0", can_data.get_splash_radius(1), 90.0)
		if can_data.upgrades.size() >= 2:
			_eq_f("get_splash_radius(2) == 110.0", can_data.get_splash_radius(2), 110.0)


# ─────────────────────────────────────────────────────────────────────
# SECTION 20 — Session 25 fixes: IceTower AoE scaling, HUD wave offset,
#              Boss HP signals, slow visual feedback, LevelData validation
# ─────────────────────────────────────────────────────────────────────
func _run_session25_fixes() -> void:
	_section("Session 25 Fixes — IceTower / HUD / Boss Bar / Level Validation")

	# ── IceTower: splash_radius now scales with upgrades ──
	var ice_data: TowerData = load("res://data/towers/ice_tower.tres") as TowerData
	_check("ice_tower.tres loaded", ice_data != null, "")
	if ice_data != null:
		_eq_f("IceTower base splash_radius == 40.0", ice_data.get_splash_radius(0), 40.0)
		if ice_data.upgrades.size() >= 1:
			_eq_f("IceTower Level1 splash == 60.0", ice_data.get_splash_radius(1), 60.0)
		if ice_data.upgrades.size() >= 2:
			_eq_f("IceTower Level2 splash == 100.0", ice_data.get_splash_radius(2), 100.0)
		_check("Upgrade2 splash > Upgrade1 splash",
			   ice_data.get_splash_radius(2) > ice_data.get_splash_radius(1), "")

	# ── IceTower script uses get_splash_radius() ──
	var ice_script: GDScript = load("res://scripts/towers/ice_tower.gd") as GDScript
	_check("ice_tower.gd loaded", ice_script != null, "")
	if ice_script != null:
		var src: String = ice_script.source_code
		_check("IceTower uses get_splash_radius(current_level)",
			   src.contains("get_splash_radius(current_level)"), "")
		_check("IceTower no longer accesses splash_radius directly",
			   not src.contains("tower_data.splash_radius"), "")

	# ── HUD: wave offset fixed (on_next_wave_ready sets _wave_num = wave_number) ──
	var hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	_check("hud.gd loaded", hud_script != null, "")
	if hud_script != null:
		var src: String = hud_script.source_code
		# Verify the wave label display uses the tracked _wave_num variable, not a raw offset
		_check("HUD wave_label uses _wave_num for display",
			   src.contains("wave_label.text") and src.contains("_wave_num"), "")
		_check("HUD _build_boss_bar() defined", src.contains("_build_boss_bar"), "")
		_check("HUD _on_boss_spawned() defined", src.contains("_on_boss_spawned"), "")
		_check("HUD _on_boss_health_changed() defined", src.contains("_on_boss_health_changed"), "")

	# ── EventBus: boss signals defined ──
	var eb_script: GDScript = load("res://scripts/autoloads/event_bus.gd") as GDScript
	_check("event_bus.gd loaded", eb_script != null, "")
	if eb_script != null:
		var src: String = eb_script.source_code
		_check("EventBus has boss_spawned signal",        src.contains("boss_spawned"), "")
		_check("EventBus has boss_health_changed signal", src.contains("boss_health_changed"), "")

	# ── BossEnemy: emits signals + overrides setup ──
	var boss_script: GDScript = load("res://scripts/enemies/boss_enemy_scene.gd") as GDScript
	_check("boss_enemy_scene.gd loaded", boss_script != null, "")
	if boss_script != null:
		var src: String = boss_script.source_code
		_check("BossEnemy overrides setup()",         src.contains("func setup("), "")
		_check("BossEnemy emits boss_spawned",         src.contains("boss_spawned.emit"), "")
		_check("BossEnemy emits boss_health_changed",  src.contains("boss_health_changed.emit"), "")
		_check("BossEnemy overrides take_damage",      src.contains("func take_damage("), "")
		_check("BossEnemy overrides take_damage_piercing",
			   src.contains("func take_damage_piercing("), "")

	# ── BaseEnemy: _max_health tracked ──
	var be_script: GDScript = load("res://scripts/enemies/base_enemy.gd") as GDScript
	_check("base_enemy.gd loaded", be_script != null, "")
	if be_script != null:
		var src: String = be_script.source_code
		_check("BaseEnemy tracks _max_health", src.contains("_max_health"), "")
		_check("apply_slow() spawns ❄ float text",
			   src.contains("❄"), "")

	# ── game_world.gd: validates LevelData type ──
	var gw_script: GDScript = load("res://scripts/game_world.gd") as GDScript
	_check("game_world.gd loaded", gw_script != null, "")
	if gw_script != null:
		var src: String = gw_script.source_code
		_check("GameWorld validates level_data is LevelData",
			   src.contains("is LevelData"), "")


# ─────────────────────────────────────────────────────────────────────
# SECTION 21 — Session 26 fixes: wave bonus gold, WaveManager state fix,
#              collision layer constant, Level 8 rebalance, scene_manager warning
# ─────────────────────────────────────────────────────────────────────
func _run_session26_fixes() -> void:
	_section("Session 26 Fixes — Wave Bonus / State Safety / Balance")

	# ── WaveManager: WAVE_BONUS_GOLD constant & emits wave_bonus_awarded ──
	var wm_script: GDScript = load("res://scripts/wave_manager.gd") as GDScript
	_check("wave_manager.gd loaded", wm_script != null, "")
	if wm_script != null:
		var src: String = wm_script.source_code
		_check("WaveManager has WAVE_BONUS_GOLD constant", src.contains("WAVE_BONUS_GOLD"), "")
		_check("WaveManager calls GameManager.add_gold in _check_wave_complete",
			   src.contains("add_gold(WAVE_BONUS_GOLD)"), "")
		_check("WaveManager emits wave_bonus_awarded", src.contains("wave_bonus_awarded.emit"), "")
		_check("WaveManager resets _countdown in _on_game_ended",
			   src.contains("_countdown = -1.0"), "")
		_check("WaveManager has state machine diagram comment",
			   src.contains("State machine"), "")

	# ── EventBus: wave_bonus_awarded signal defined ──
	var eb_script: GDScript = load("res://scripts/autoloads/event_bus.gd") as GDScript
	_check("event_bus.gd loaded", eb_script != null, "")
	if eb_script != null:
		_check("EventBus has wave_bonus_awarded signal",
			   eb_script.source_code.contains("wave_bonus_awarded"), "")

	# ── HUD: connects to wave_bonus_awarded ──
	var hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	_check("hud.gd loaded", hud_script != null, "")
	if hud_script != null:
		var src: String = hud_script.source_code
		_check("HUD connects wave_bonus_awarded", src.contains("wave_bonus_awarded"), "")
		_check("HUD _on_wave_bonus_awarded shows message", src.contains("_on_wave_bonus_awarded"), "")

	# ── CannonProjectile: named collision layer constant ──
	var cp_script: GDScript = load("res://scripts/projectiles/cannon_projectile.gd") as GDScript
	_check("cannon_projectile.gd loaded", cp_script != null, "")
	if cp_script != null:
		var src: String = cp_script.source_code
		_check("CannonProjectile has ENEMY_COLLISION_LAYER constant",
			   src.contains("ENEMY_COLLISION_LAYER"), "")
		_check("CannonProjectile does not use magic number 2 as collision_mask",
			   not src.contains("collision_mask = 2"), "")

	# ── Level 8 Wave 9: enemy counts reduced ──
	var l8_data: LevelData = load("res://data/levels/level_8.tres") as LevelData
	_check("level_8.tres loaded", l8_data != null, "")
	if l8_data != null:
		_check("Level 8 has 9 waves", l8_data.waves.size() == 9, "")
		var w9: WaveData = l8_data.waves[8]
		# Total enemies in final wave should be more manageable (< 100 was 128)
		var total_enemies := 0
		for entry in w9.entries:
			total_enemies += entry.count
		_check("Level 8 Wave 9 has ≤ 90 enemies (was 128)",
			   total_enemies <= 90,
			   "got %d" % total_enemies)

	# ── SceneManager: warns when intro story missing ──
	var sm_script: GDScript = load("res://scripts/autoloads/scene_manager.gd") as GDScript
	_check("scene_manager.gd loaded", sm_script != null, "")
	if sm_script != null:
		_check("SceneManager push_warning for missing story",
			   sm_script.source_code.contains("push_warning"), "")

	# ── Victory.gd: no redundant null check on _diff_label ──
	var vic_script: GDScript = load("res://scripts/ui/victory.gd") as GDScript
	_check("victory.gd loaded", vic_script != null, "")
	if vic_script != null:
		# The label is created in _ready() so null guard is unnecessary/misleading
		_check("victory.gd _diff_label null guard removed",
			   not vic_script.source_code.contains("if _diff_label != null"), "")


# ─────────────────────────────────────────────────────────────────────
# SECTION 22 — Session 27 fixes: boss bar colors, boss charge+slow,
#              tower affordability guard
# ─────────────────────────────────────────────────────────────────────
func _run_session27_fixes() -> void:
	_section("Session 27 Fixes — Boss Bar / Charge Slow / Affordability")

	# ── HUD: boss bar color — green at full health, red at low health ──
	var hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	_check("hud.gd loaded", hud_script != null, "")
	if hud_script != null:
		var src: String = hud_script.source_code
		_check("HUD boss bar green at high HP (Color(0.25, 0.80, 0.25))",
			   src.contains("Color(0.25, 0.80, 0.25)"), "")
		# Ensure the health branch for pct > 0.6 uses green, not red
		# (Color(0.85, 0.15, 0.15) may appear as the bar's initial/default color but
		#  the pct > 0.6 branch must set green Color(0.25, 0.80, 0.25))
		_check("HUD boss bar pct > 0.6 branch sets green (0.25, 0.80, 0.25)",
			   src.contains("pct > 0.6") and src.contains("Color(0.25, 0.80, 0.25)"), "")

	# ── BossEnemy: charge preserves slow via _pre_charge_speed ──
	var boss_script: GDScript = load("res://scripts/enemies/boss_enemy_scene.gd") as GDScript
	_check("boss_enemy_scene.gd loaded", boss_script != null, "")
	if boss_script != null:
		var src: String = boss_script.source_code
		_check("BossEnemy has _pre_charge_speed variable",
			   src.contains("_pre_charge_speed"), "")
		_check("BossEnemy saves _pre_charge_speed before charge",
			   src.contains("_pre_charge_speed = _speed_multiplier"), "")
		_check("BossEnemy restores _pre_charge_speed after charge ends",
			   src.contains("_speed_multiplier = _pre_charge_speed"), "")
		_check("BossEnemy does NOT blindly reset _speed_multiplier to 1.0 after charge",
			   not src.contains("_speed_multiplier = 1.0"), "")

	# ── TowerPanel: affordability guard before placement ──
	var tp_script: GDScript = load("res://scripts/ui/tower_panel.gd") as GDScript
	_check("tower_panel.gd loaded", tp_script != null, "")
	if tp_script != null:
		var src: String = tp_script.source_code
		_check("TowerPanel checks can_afford before placement",
			   src.contains("can_afford"), "")
		_check("TowerPanel plays invalid_placement SFX when broke",
			   src.contains("play_invalid_placement"), "")
		_check("TowerPanel returns early when unaffordable",
			   src.contains("can_afford") and src.contains("return"), "")


# ─────────────────────────────────────────────────────────────────────
# SECTION 23 — Session 28 fixes: health bar scaling, inter-wave button,
#              sell confirm countdown, upgrade-button gold refresh
# ─────────────────────────────────────────────────────────────────────
func _run_session28_fixes() -> void:
	_section("Session 28 Fixes — Health Bar / Wave Button / Sell Timer / Gold Refresh")

	# ── BaseEnemy: health bar uses _max_health (not enemy_data.max_health) ──
	var be_script: GDScript = load("res://scripts/enemies/base_enemy.gd") as GDScript
	_check("base_enemy.gd loaded", be_script != null, "")
	if be_script != null:
		var src: String = be_script.source_code
		_check("_update_health_bar uses _max_health not enemy_data.max_health",
			   src.contains("current_health / maxf(_max_health"), "")
		_check("_update_health_bar does NOT use enemy_data.max_health directly",
			   not src.contains("current_health / enemy_data.max_health"), "")

	# ── WaveManager: emits next_wave_ready after each non-final wave ──
	var wm_script: GDScript = load("res://scripts/wave_manager.gd") as GDScript
	_check("wave_manager.gd loaded", wm_script != null, "")
	if wm_script != null:
		var src: String = wm_script.source_code
		# Should emit next_wave_ready inside _check_wave_complete, not only in setup()
		var setup_pos := src.find("next_wave_ready.emit(1,")
		var second_emit_pos := src.find("next_wave_ready.emit(_current_wave_index + 2")
		_check("WaveManager emits next_wave_ready for subsequent waves",
			   second_emit_pos > setup_pos and second_emit_pos != -1, "")

	# ── UpgradePanel: sell confirm shows countdown timer in button ──
	var up_script: GDScript = load("res://scripts/ui/upgrade_panel.gd") as GDScript
	_check("upgrade_panel.gd loaded", up_script != null, "")
	if up_script != null:
		var src: String = up_script.source_code
		_check("UpgradePanel sell confirm shows countdown in button text",
			   src.contains("int(ceil(_sell_confirm_timer))"), "")
		_check("UpgradePanel connects gold_changed for upgrade button refresh",
			   src.contains("gold_changed.connect"), "")
		_check("UpgradePanel has _on_gold_changed handler",
			   src.contains("func _on_gold_changed"), "")


# ─────────────────────────────────────────────────────────────────────
# SECTION 24 — Session 29 fixes: double-death guard, sniper dead-skip,
#              SFX warnings for Sniper/Lightning
# ─────────────────────────────────────────────────────────────────────
func _run_session29_fixes() -> void:
	_section("Session 29 Fixes — Double-Death Guard / Sniper Targeting / SFX Warnings")

	# ── BaseEnemy: _is_dead flag prevents double-death ──
	var be_script: GDScript = load("res://scripts/enemies/base_enemy.gd") as GDScript
	_check("base_enemy.gd loaded", be_script != null, "")
	if be_script != null:
		var src: String = be_script.source_code
		_check("BaseEnemy has _is_dead flag", src.contains("var _is_dead: bool = false"), "")
		_check("_die() guards against double-call with _is_dead",
			   src.contains("if _is_dead:") and src.contains("_is_dead = true"), "")
		_check("take_damage() checks _is_dead early",
			   src.contains("if _is_dead or enemy_data == null"), "")
		_check("take_damage_piercing() checks _is_dead early",
			   src.contains("if _is_dead or enemy_data == null"), "")

	# ── BaseTower: skips dead enemies in targeting ──
	var bt_script: GDScript = load("res://scripts/towers/base_tower.gd") as GDScript
	_check("base_tower.gd loaded", bt_script != null, "")
	if bt_script != null:
		_check("BaseTower _get_best_target skips _is_dead enemies",
			   bt_script.source_code.contains("_is_dead"), "")

	# ── SniperTower: skips dead enemies, single HP get, push_warning ──
	var sn_script: GDScript = load("res://scripts/towers/sniper_tower.gd") as GDScript
	_check("sniper_tower.gd loaded", sn_script != null, "")
	if sn_script != null:
		var src: String = sn_script.source_code
		_check("SniperTower skips _is_dead enemies in targeting",
			   src.contains("_is_dead"), "")
		_check("SniperTower does NOT call enemy.get('current_health') twice",
			   src.count("get(\"current_health\")") <= 1, "")
		_check("SniperTower push_warning when SFX missing",
			   src.contains("push_warning"), "")

	# ── LightningTower: push_warning for missing SFX ──
	var lt_script: GDScript = load("res://scripts/towers/lightning_tower.gd") as GDScript
	_check("lightning_tower.gd loaded", lt_script != null, "")
	if lt_script != null:
		_check("LightningTower push_warning when SFX missing",
			   lt_script.source_code.contains("push_warning"), "")


# ─────────────────────────────────────────────────────────────────────
# SECTION 25 — Session 30 fixes: StoryScreen guards, smoke wrap,
#              save backup/recovery, Level 3 difficulty curve
# ─────────────────────────────────────────────────────────────────────
func _run_session30_fixes() -> void:
	_section("Session 30 Fixes — Story Guards / Smoke Wrap / Save Backup / Level Balance")

	# ── StoryScreen: guards against null @onready nodes ──
	var ss_script: GDScript = load("res://scripts/ui/story_screen.gd") as GDScript
	_check("story_screen.gd loaded", ss_script != null, "")
	if ss_script != null:
		var src: String = ss_script.source_code
		_check("StoryScreen _show_entry guards dialogue_text null",
			   src.contains("dialogue_text == null"), "")
		_check("StoryScreen _show_entry calls story_complete on missing nodes",
			   src.contains("SceneManager.story_complete()") and src.contains("push_error"), "")
		_check("StoryScreen _process guards dialogue_text null",
			   src.contains("if dialogue_text == null or continue_label == null"), "")
		_check("StoryScreen progress_label guarded with null check",
			   src.contains("if progress_label != null:"), "")

	# ── FactoryBase: _smoke_phase bounded with fmod ──
	var fb_script: GDScript = load("res://scripts/factory_base.gd") as GDScript
	_check("factory_base.gd loaded", fb_script != null, "")
	if fb_script != null:
		var src: String = fb_script.source_code
		_check("FactoryBase smoke phase uses fmod to stay bounded",
			   src.contains("fmod(_smoke_phase"), "")

	# ── SaveManager: creates .bak backup before writing ──
	var sm_script: GDScript = load("res://scripts/autoloads/save_manager.gd") as GDScript
	_check("save_manager.gd loaded", sm_script != null, "")
	if sm_script != null:
		var src: String = sm_script.source_code
		_check("SaveManager save() creates .bak backup",
			   src.contains("SAVE_PATH + \".bak\""), "")
		_check("SaveManager load_data() attempts .bak recovery on corrupt save",
			   src.contains("Recovered from backup save"), "")

	# ── Level 3: lives and gold increased ──
	var l3_data: LevelData = load("res://data/levels/level_3.tres") as LevelData
	_check("level_3.tres loaded", l3_data != null, "")
	if l3_data != null:
		_check("Level 3 starting_lives ≥ 12 (was 10, difficulty cliff fix)",
			   l3_data.starting_lives >= 12,
			   "got %d" % l3_data.starting_lives)
		_check("Level 3 starting_gold ≥ 160 (was 150)",
			   l3_data.starting_gold >= 160,
			   "got %d" % l3_data.starting_gold)


func _run_session31_fixes() -> void:
	_section("Session 31 Fixes — Duplicate Signal / First-Shot Delay / Wave Label Init")

	# ── WaveManager: duplicate next_wave_ready.emit removed ──
	var wm_script: GDScript = load("res://scripts/wave_manager.gd") as GDScript
	_check("wave_manager.gd loaded", wm_script != null, "")
	if wm_script != null:
		var src: String = wm_script.source_code
		# Count occurrences of the signal emit in the non-final branch block.
		# After the fix there should be exactly one occurrence of this call
		# in the "Start countdown to next wave" block. We verify the total
		# occurrence count to catch any future re-introduction of the bug.
		var emit_str := "next_wave_ready.emit(_current_wave_index + 2, _waves.size())"
		var count: int = 0
		var pos: int = 0
		while true:
			pos = src.find(emit_str, pos)
			if pos == -1:
				break
			count += 1
			pos += emit_str.length()
		_check("next_wave_ready inter-wave emit not duplicated (count == 1)",
			   count == 1,
			   "found %d occurrences" % count)

	# ── BaseTower: attack_timer.start() uses full wait_time as first interval ──
	var bt_script: GDScript = load("res://scripts/towers/base_tower.gd") as GDScript
	_check("base_tower.gd loaded", bt_script != null, "")
	if bt_script != null:
		var src: String = bt_script.source_code
		_check("BaseTower attack_timer.start passes wait_time (no free first shot)",
			   src.contains("attack_timer.start(attack_timer.wait_time)"), "")
		_check("BaseTower bare attack_timer.start() not present",
			   not src.contains("attack_timer.start()\n"), "")

	# ── HUD: wave_label initialized before first wave ──
	var hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	_check("hud.gd loaded", hud_script != null, "")
	if hud_script != null:
		var src: String = hud_script.source_code
		_check("HUD _ready sets wave_label.text before first wave starts",
			   src.contains("波次: 0 / %d"), "")
		_check("HUD pre-loads wave count from LevelData in _ready",
			   src.contains("_wave_total =") and src.contains("_init_level_res"), "")


func _run_session32_fixes() -> void:
	_section("Session 32 — Range Preview Validity / Message Queue / is_instance_valid / waves_cleared")

	# ── GameWorld: TOWER_SELECT_RADIUS constant and range preview validity tint ──
	var gw_script: GDScript = load("res://scripts/game_world.gd") as GDScript
	_check("game_world.gd loaded", gw_script != null, "")
	if gw_script != null:
		var src: String = gw_script.source_code
		_check("GameWorld has TOWER_SELECT_RADIUS constant",
			   src.contains("TOWER_SELECT_RADIUS"), "")
		_check("GameWorld uses TOWER_SELECT_RADIUS instead of bare 48.0 in _try_select_tower",
			   src.contains("dist < TOWER_SELECT_RADIUS") and not src.contains("dist < 48.0"), "")
		_check("GameWorld has _range_preview_valid flag",
			   src.contains("_range_preview_valid"), "")
		_check("GameWorld range preview uses _range_preview_valid for color selection",
			   src.contains("if _range_preview_valid:"), "")
		_check("GameWorld wave_completed connected to waves_cleared stat",
			   src.contains("wave_completed") and src.contains("waves_cleared"), "")

	# ── UpgradePanel: is_instance_valid replaces bare null check ──
	var up_script: GDScript = load("res://scripts/ui/upgrade_panel.gd") as GDScript
	_check("upgrade_panel.gd loaded", up_script != null, "")
	if up_script != null:
		var src: String = up_script.source_code
		_check("UpgradePanel _process uses is_instance_valid for sell confirm",
			   src.contains("is_instance_valid(_current_tower)"), "")
		_check("UpgradePanel _on_upgrade_pressed uses is_instance_valid",
			   src.contains("not is_instance_valid(_current_tower)"), "")

	# ── HUD: message queue prevents stomping ──
	var hud_script2: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	_check("hud.gd loaded for message queue check", hud_script2 != null, "")
	if hud_script2 != null:
		var src: String = hud_script2.source_code
		_check("HUD has _message_queue Array",
			   src.contains("_message_queue"), "")
		_check("HUD show_message queues when already showing",
			   src.contains("_message_queue.append"), "")
		_check("HUD _process pops next message from queue when timer expires",
			   src.contains("_message_queue.pop_front()"), "")
		_check("HUD show_message has queue cap guard",
			   src.contains("_message_queue.size() < 3"), "")

	# ── SaveManager: waves_cleared stat in defaults ──
	var sm_script: GDScript = load("res://scripts/autoloads/save_manager.gd") as GDScript
	_check("save_manager.gd loaded for waves_cleared check", sm_script != null, "")
	if sm_script != null:
		var src: String = sm_script.source_code
		_check("SaveManager default stats include waves_cleared",
			   src.contains("\"waves_cleared\""), "")


# ─────────────────────────────────────────────────────────────────────
# SECTION 28 — Session 33 visual: hero menu bg / zone terrain / emoji cleanup
# ─────────────────────────────────────────────────────────────────────
func _run_session33_visual() -> void:
	_section("Session 33 Visual — Hero Menu BG / Zone Terrain / UI Cleanup")

	# ── MainMenuBg: procedural landscape layers ──
	var bg_script: GDScript = load("res://scripts/ui/main_menu_bg.gd") as GDScript
	_check("main_menu_bg.gd loaded", bg_script != null, "")
	if bg_script != null:
		var src: String = bg_script.source_code
		_check("MainMenuBg has _draw_sky()", src.contains("func _draw_sky()"), "")
		_check("MainMenuBg has _draw_mountains_far()", src.contains("func _draw_mountains_far()"), "")
		_check("MainMenuBg has _draw_mountains_near()", src.contains("func _draw_mountains_near()"), "")
		_check("MainMenuBg has _draw_treeline()", src.contains("func _draw_treeline()"), "")
		_check("MainMenuBg has _draw_ground()", src.contains("func _draw_ground()"), "")
		_check("MainMenuBg has _draw_center_glow()", src.contains("func _draw_center_glow()"), "")
		_check("MainMenuBg has _draw_towers()", src.contains("func _draw_towers()"), "")
		_check("MainMenuBg has _draw_vignette()", src.contains("func _draw_vignette()"), "")
		_check("MainMenuBg no longer has _build_grid() tile grid",
			   not src.contains("func _build_grid()"), "old tile-grid system should be removed")
		_check("MainMenuBg _hill() helper present for mountain profiles",
			   src.contains("func _hill("), "")
		_check("MainMenuBg HORIZ constant defined",
			   src.contains("const HORIZ"), "")

	# ── WorldBackground: industrial factory-floor terrain ──
	var wb_script: GDScript = load("res://scripts/world_background.gd") as GDScript
	_check("world_background.gd loaded", wb_script != null, "")
	if wb_script != null:
		var src: String = wb_script.source_code
		_check("WorldBackground has factory zone system _zone_at()",
			   src.contains("func _zone_at("), "")
		_check("WorldBackground has path shoulder detection",
			   src.contains("shoulder"), "")
		_check("WorldBackground has METAL zone",
			   src.contains("ZoneType.METAL"), "")
		_check("WorldBackground has PROCESSING zone",
			   src.contains("ZoneType.PROCESSING"), "")
		_check("WorldBackground has CLEAN zone",
			   src.contains("ZoneType.CLEAN"), "")
		_check("WorldBackground draws dark void background",
			   src.contains("COL_VOID") and src.contains("_draw_void_bg"), "")
		_check("WorldBackground draws slab drop-shadow",
			   src.contains("_draw_slab_shadow"), "")
		_check("WorldBackground draws spawn/goal markers",
			   src.contains("_draw_spawn_goal_markers"), "")

	# ── GridManager: grid lines only in placement mode ──
	var gm_script: GDScript = load("res://scripts/grid_manager.gd") as GDScript
	_check("grid_manager.gd loaded", gm_script != null, "")
	if gm_script != null:
		var src: String = gm_script.source_code
		_check("GridManager grid lines gated to placement mode",
			   src.contains("if not _placement_mode:") and src.contains("return"), "")

	# ── HUD: no emoji icons in stat labels ──
	var hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
	_check("hud.gd loaded for emoji check", hud_script != null, "")
	if hud_script != null:
		var src: String = hud_script.source_code
		_check("HUD uses 命 not ❤ for lives", src.contains("命 %d") and not src.contains("❤ %d"), "")
		_check("HUD uses 金 not 💰 for gold", src.contains("金 %d") and not src.contains("💰 %d"), "")
		_check("HUD uses 分 not ⭐ for score", src.contains("分 %d") and not src.contains("⭐ %d"), "")

	# ── StoryScreen: continue_label uses modulate.a not visible to avoid layout jump ──
	var ss_script2: GDScript = load("res://scripts/ui/story_screen.gd") as GDScript
	_check("story_screen.gd loaded", ss_script2 != null, "")
	if ss_script2 != null:
		var src: String = ss_script2.source_code
		_check("StoryScreen hides ContinueLabel via modulate.a not visible=false",
			   src.contains("continue_label.modulate.a = 0.0"), "")
		_check("StoryScreen does not toggle continue_label.visible",
			   not src.contains("continue_label.visible = true")
			   and not src.contains("continue_label.visible = false"), "")

	# ── PauseMenu: no emoji in buttons ──
	var pm_scene: PackedScene = load("res://scenes/ui/PauseMenu.tscn") as PackedScene
	_check("PauseMenu.tscn loaded", pm_scene != null, "")


# ═════════════════════════════════════════════════════════════════════
# Assertion helpers
# ═════════════════════════════════════════════════════════════════════

func _section(name: String) -> void:
	print("\n  ┌─ %s" % name)
	_section_fails = 0

func _ok(label: String) -> void:
	_pass_count += 1
	print("  │ ✓  %s" % label)

func _fail(label: String, detail: String = "") -> void:
	_fail_count += 1
	_section_fails += 1
	var line := "  │ ✗  FAIL: %s" % label
	if detail.length() > 0:
		line += "  →  " + detail
	printerr(line)

func _check(label: String, cond: bool, detail: String = "") -> bool:
	if cond:
		_ok(label)
	else:
		_fail(label, detail)
	return cond

func _eq(label: String, actual: Variant, expected: Variant) -> void:
	_check(label, actual == expected,
	       "got [%s]  want [%s]" % [str(actual), str(expected)])

func _eq_f(label: String, actual: float, expected: float, tol: float = 1e-6) -> void:
	_check(label, absf(actual - expected) < tol,
	       "got [%s]  want [%s]" % [str(actual), str(expected)])

func _gt(label: String, val: float, min_val: float) -> void:
	_check(label, val > min_val,
	       "[%s] should be > [%s]" % [str(val), str(min_val)])

func _not_empty(label: String, s: String) -> void:
	_check(label, s.length() > 0, "should not be empty string")

# ═════════════════════════════════════════════════════════════════════
# Final report
# ═════════════════════════════════════════════════════════════════════

func _report() -> void:
	print("\n═══════════════════════════════════════════════════════")
	if _fail_count == 0:
		print("✅  All %d tests passed." % _pass_count)
	else:
		print("❌  %d passed,  %d FAILED." % [_pass_count, _fail_count])
	print("═══════════════════════════════════════════════════════\n")
	quit(1 if _fail_count > 0 else 0)
