## TowerData — defines the static stats for one tower type.
## Stored as .tres files in res://data/towers/
## Supports up to 3 upgrade levels (level 0 = base, 1 = upgraded, 2 = max).
class_name TowerData
extends Resource

## --- Identity ---
@export var tower_id: String = ""
@export var tower_name: String = ""
@export var description: String = ""

## --- Cost ---
@export var build_cost: int = 100
## Sell refund = build_cost * sell_ratio + sum(upgrade costs * sell_ratio)
@export var sell_ratio: float = 0.7

## --- Base stats (level 0) ---
@export var base_damage: float = 10.0
@export var base_attack_speed: float = 1.0   # attacks per second
@export var base_range: float = 200.0         # pixels
@export var projectile_speed: float = 400.0
@export var splash_radius: float = 0.0        # 0 = no splash
@export var slow_factor: float = 1.0          # 1.0 = no slow, 0.5 = 50% speed
@export var slow_duration: float = 0.0
## Base number of chain-lightning jumps (lightning tower only; 0 = unused)
@export var base_chain_count: int = 0

## --- Upgrade levels ---
## Each UpgradeData contains cost + multipliers applied on top of current stats
@export var upgrades: Array[UpgradeData] = []

## --- Scene & visual ---
## Path to the tower's packed scene (e.g. res://scenes/towers/ArrowTower.tscn)
@export var scene_path: String = ""

## Returns total sell value given current_level (0-based)
func get_sell_value(current_level: int) -> int:
	var total_spent: int = build_cost
	for i in range(current_level):
		if i < upgrades.size():
			total_spent += upgrades[i].upgrade_cost
	return int(total_spent * sell_ratio)

## Returns damage for a given level
func get_damage(level: int) -> float:
	var dmg := base_damage
	for i in range(level):
		if i < upgrades.size():
			dmg *= upgrades[i].damage_multiplier
	return dmg

## Returns range for a given level
func get_range(level: int) -> float:
	var r := base_range
	for i in range(level):
		if i < upgrades.size():
			r *= upgrades[i].range_multiplier
	return r

## Returns attack speed for a given level
func get_attack_speed(level: int) -> float:
	var spd := base_attack_speed
	for i in range(level):
		if i < upgrades.size():
			spd *= upgrades[i].speed_multiplier
	return spd

## Returns slow_factor for a given level (each upgrade multiplies the factor, making slow stronger)
func get_slow_factor(level: int) -> float:
	var sf := slow_factor
	for i in range(level):
		if i < upgrades.size():
			sf *= upgrades[i].slow_factor_mult
	return sf

## Returns slow_duration for a given level (each upgrade adds a bonus in seconds)
func get_slow_duration(level: int) -> float:
	var sd := slow_duration
	for i in range(level):
		if i < upgrades.size():
			sd += upgrades[i].slow_duration_bonus
	return sd

## Returns chain count for a given level (lightning tower; each upgrade may add jumps)
func get_chain_count(level: int) -> int:
	var count := base_chain_count
	for i in range(level):
		if i < upgrades.size():
			count += upgrades[i].chain_bonus
	return count

## Returns splash radius for a given level (cannon tower; each upgrade may add radius)
func get_splash_radius(level: int) -> float:
	var r := splash_radius
	for i in range(level):
		if i < upgrades.size():
			r += upgrades[i].splash_radius_bonus
	return r
