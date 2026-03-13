## LevelData — defines static configuration for one level.
class_name LevelData
extends Resource

@export var level_id: int = 1
@export var level_name: String = "Level 1"
@export var description: String = ""

@export var starting_lives: int = 20
@export var starting_gold: int = 300

## Ordered waypoints in TILE coordinates (Vector2i).
## The path goes in straight horizontal/vertical segments between waypoints.
## First waypoint = enemy spawn, last waypoint = base (exit).
@export var waypoints: Array[Vector2i] = []

@export var waves: Array[WaveData] = []
