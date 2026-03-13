## EnemyData — defines stats for one enemy type.
class_name EnemyData
extends Resource

@export var enemy_id: String = ""
@export var enemy_name: String = ""

@export var max_health: float = 60.0
@export var move_speed: float = 80.0      # pixels per second
## armor: fraction of damage absorbed (0.0 = no armor, 0.5 = 50% reduction)
@export var armor: float = 0.0
@export var gold_reward: int = 20
@export var score_reward: int = 10

## Path to the enemy packed scene
@export var scene_path: String = ""
