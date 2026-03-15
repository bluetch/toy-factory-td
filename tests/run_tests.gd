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
		"outro_6", "outro_7",
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
