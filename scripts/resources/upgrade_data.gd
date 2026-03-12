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
