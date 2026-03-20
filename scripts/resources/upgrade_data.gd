## UpgradeData — one upgrade tier for a tower.
## Referenced by TowerData.upgrades array.
class_name UpgradeData
extends Resource

@export var upgrade_name: String = "Upgrade"
@export var description: String = ""
@export var upgrade_cost: int = 100
@export var damage_multiplier: float = 1.3
@export var range_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0
## Multiplied into slow_factor each upgrade level (1.0 = no change, 0.8 = stronger slow)
@export var slow_factor_mult: float = 1.0
## Added to slow_duration each upgrade level (0.0 = no change)
@export var slow_duration_bonus: float = 0.0
## Added to chain_count each upgrade level (0 = no change; lightning tower only)
@export var chain_bonus: int = 0
## Added to splash_radius each upgrade level (0.0 = no change; cannon tower only)
@export var splash_radius_bonus: float = 0.0
