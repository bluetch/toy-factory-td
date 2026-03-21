## SkillManager — Roguelike skill system autoload.
##
## Tracks the player's chosen skills across levels within a single run.
## Call reset() when starting a new run (main menu / level select).
##
## Effect types understood by the bonus getters:
##   "damage_mult"          → multiplied together per tower_filter
##   "speed_mult"           → multiplied together per tower_filter
##   "range_mult"           → multiplied together per tower_filter
##   "wave_gold"            → summed → flat bonus on every wave-complete reward
##   "start_gold"           → summed → flat bonus added to gold at level start
##   "lives_bonus"          → summed → extra lives at level start
##   "build_cost_mult"      → multiplied together (global only)
##   "sell_ratio_bonus"     → summed → added to tower sell_ratio
##   "splash_bonus"         → summed → extra px on CannonTower splash
##   "slow_bonus"           → summed → stronger IceTower slow fraction
##   "slow_duration_bonus"  → summed → extra seconds on IceTower slow
##   "chain_bonus"          → summed (int) → extra LightningTower chain jumps
##   "crit_chance"          → summed (clamped 0–0.75) → SniperTower crit %
extends Node

## Emitted whenever a skill is applied so UI can refresh.
signal skill_applied(skill_id: String)

## All skills available in the pool.
var _pool: Array[SkillData] = []

## Currently stacked skills for this run: skill_id → stack count.
var _stacks: Dictionary = {}


func _ready() -> void:
	_build_pool()
	EventBus.game_over_triggered.connect(reset)


## Clear all skill stacks (call when starting a new run).
func reset() -> void:
	_stacks = {}


# ── Pool query ────────────────────────────────────────────────────────────────

func get_skill_stack(skill_id: String) -> int:
	return _stacks.get(skill_id, 0)


## Apply (increment stack of) a skill by id.
func apply(skill_id: String) -> void:
	_stacks[skill_id] = get_skill_stack(skill_id) + 1
	skill_applied.emit(skill_id)


## Return [count] distinct random skills weighted by rarity, filtered by max_stacks.
func pick_random_skills(count: int) -> Array[SkillData]:
	# Build weighted pool: common ×3, rare ×2, epic ×1
	var weighted: Array[SkillData] = []
	for s: SkillData in _pool:
		if s.max_stacks > 0 and get_skill_stack(s.skill_id) >= s.max_stacks:
			continue
		var w := 3 if s.rarity == 0 else (2 if s.rarity == 1 else 1)
		for _i in range(w):
			weighted.append(s)
	weighted.shuffle()
	# Deduplicate while preserving weighted order
	var seen: Dictionary = {}
	var result: Array[SkillData] = []
	for s: SkillData in weighted:
		if not seen.has(s.skill_id):
			seen[s.skill_id] = true
			result.append(s)
			if result.size() >= count:
				break
	return result


# ── Bonus getters ─────────────────────────────────────────────────────────────

## Damage multiplier for tower_id (product of all applicable stacks).
func get_damage_mult(tower_id: String) -> float:
	return _product_mult("damage_mult", tower_id)

## Attack-speed multiplier.
func get_speed_mult(tower_id: String) -> float:
	return _product_mult("speed_mult", tower_id)

## Range multiplier.
func get_range_mult(tower_id: String) -> float:
	return _product_mult("range_mult", tower_id)

## Flat gold added on top of the base wave-bonus reward.
func get_wave_gold_bonus() -> int:
	return int(_sum_float("wave_gold", ""))

## Flat gold added at the start of each level.
func get_start_gold_bonus() -> int:
	return int(_sum_float("start_gold", ""))

## Extra lives added at the start of each level.
func get_lives_bonus() -> int:
	return int(_sum_float("lives_bonus", ""))

## Overall build-cost multiplier (product; <1 = cheaper).
func get_build_cost_mult() -> float:
	return _product_mult("build_cost_mult", "")

## Bonus added to sell_ratio (0.08 per stack = 8%).
func get_sell_ratio_bonus() -> float:
	return _sum_float("sell_ratio_bonus", "")

## Extra splash radius for CannonTower (pixels).
func get_splash_bonus() -> float:
	return _sum_float("splash_bonus", "CannonTower")

## Extra slow strength for IceTower (0.15 = 15% stronger reduction in speed).
func get_slow_bonus() -> float:
	return _sum_float("slow_bonus", "IceTower")

## Extra slow duration for IceTower (seconds).
func get_slow_duration_bonus() -> float:
	return _sum_float("slow_duration_bonus", "IceTower")

## Extra chain-jump count for LightningTower.
func get_chain_bonus() -> int:
	return int(_sum_float("chain_bonus", "LightningTower"))

## Sniper crit chance 0–0.75.
func get_crit_chance() -> float:
	return clampf(_sum_float("crit_chance", "SniperTower"), 0.0, 0.75)

## Effective build cost after discount (rounds to int).
func effective_build_cost(base_cost: int) -> int:
	return int(roundi(base_cost * get_build_cost_mult()))


# ── Internal helpers ──────────────────────────────────────────────────────────

func _product_mult(effect_type: String, tower_id: String) -> float:
	var result := 1.0
	for s: SkillData in _pool:
		if s.effect_type != effect_type:
			continue
		if s.tower_filter != "" and s.tower_filter != tower_id:
			continue
		var n := get_skill_stack(s.skill_id)
		if n > 0:
			result *= pow(s.effect_value, n)
	return result


func _sum_float(effect_type: String, tower_filter: String) -> float:
	var total := 0.0
	for s: SkillData in _pool:
		if s.effect_type != effect_type:
			continue
		if tower_filter != "" and s.tower_filter != tower_filter:
			continue
		total += s.effect_value * get_skill_stack(s.skill_id)
	return total


# ── Skill definitions ─────────────────────────────────────────────────────────

func _build_pool() -> void:
	_pool = []
	# ── Common ────────────────────────────────────────────────────────────
	_def("gold_rain",    "金雨",     "每波完成額外 +12 金",           "💰", 0, 4, "",              "wave_gold",           12.0)
	_def("iron_will",    "鋼鐵意志", "每關開始 +2 生命值",             "🛡", 0, 4, "",              "lives_bonus",          2.0)
	_def("efficiency",   "工廠效能", "所有防禦塔建造費降低 8%",        "🔧", 0, 3, "",              "build_cost_mult",      0.92)
	_def("arrow_focus",  "箭術專精", "Arrow 塔傷害 ×1.2",              "🏹", 0, 3, "ArrowTower",    "damage_mult",          1.2)
	_def("cannon_shell", "重型炮彈", "Cannon 塔傷害 ×1.25",            "💣", 0, 3, "CannonTower",   "damage_mult",          1.25)
	_def("swift_arrow",  "疾風箭",   "Arrow 塔攻速 ×1.18",             "💨", 0, 3, "ArrowTower",    "speed_mult",           1.18)
	_def("scope",        "狙擊鏡",   "Sniper 塔射程 ×1.25",            "🔭", 0, 3, "SniperTower",   "range_mult",           1.25)
	# ── Rare ──────────────────────────────────────────────────────────────
	_def("treasury",     "財政部",   "每關開始 +60 金",                "🏦", 1, 5, "",              "start_gold",          60.0)
	_def("salvage",      "廢物利用", "防禦塔出售回收率 +8%",           "♻", 1, 3, "",              "sell_ratio_bonus",     0.08)
	_def("eagle_eye",    "鷹眼",     "Arrow 塔射程 ×1.3",              "👁", 1, 2, "ArrowTower",    "range_mult",           1.3)
	_def("gunpowder",    "新式火藥", "Cannon 塔爆炸半徑 +30 px",       "💥", 1, 3, "CannonTower",   "splash_bonus",        30.0)
	_def("permafrost",   "永凍層",   "Ice 塔減速強度 +15%",            "❄", 1, 2, "IceTower",      "slow_bonus",           0.15)
	_def("rapid_fire",   "速射模組", "Cannon 塔攻速 ×1.20",            "🔩", 1, 3, "CannonTower",   "speed_mult",           1.20)
	_def("frost_lens",   "冰晶鏡片", "Ice 塔射程 ×1.25",               "🔮", 1, 2, "IceTower",      "range_mult",           1.25)
	_def("arc_range",    "弧電延伸", "Lightning 塔射程 ×1.25",         "🗲",  1, 2, "LightningTower","range_mult",           1.25)
	# ── Epic ──────────────────────────────────────────────────────────────
	_def("conductor",    "超級導體", "Lightning 塔跳數 +1",            "⚡", 2, 2, "LightningTower","chain_bonus",          1.0)
	_def("headshot",     "精準爆頭", "Sniper 塔 25% 機率雙倍傷害",     "🎯", 2, 2, "SniperTower",   "crit_chance",          0.25)
	_def("overcharge",   "超載",     "Lightning 塔傷害 ×1.4",          "🌩", 2, 2, "LightningTower","damage_mult",          1.4)
	_def("blizzard",     "暴風雪",   "Ice 塔減速持續 +1.0 秒",         "🌨", 2, 2, "IceTower",      "slow_duration_bonus",  1.0)
	_def("ap_round",     "穿甲彈",   "Sniper 塔傷害 ×1.4",             "🔫", 2, 2, "SniperTower",   "damage_mult",          1.4)
	_def("sniper_quick", "閃電出擊", "Sniper 塔攻速 ×1.30",            "🏃", 2, 2, "SniperTower",   "speed_mult",           1.30)
	_def("war_economy",  "戰時經濟", "每波完成額外 +25 金",            "💹", 2, 2, "",              "wave_gold",           25.0)


func _def(id: String, sname: String, desc: String, icon: String,
		rarity: int, max_st: int, filter: String,
		etype: String, evalue: float) -> void:
	var s := SkillData.new()
	s.skill_id     = id
	s.skill_name   = sname
	s.description  = desc
	s.icon         = icon
	s.rarity       = rarity
	s.max_stacks   = max_st
	s.tower_filter = filter
	s.effect_type  = etype
	s.effect_value = evalue
	_pool.append(s)
