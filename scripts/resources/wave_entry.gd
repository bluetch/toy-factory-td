## WaveEntry — one group of enemies within a wave.
class_name WaveEntry
extends Resource

@export var enemy_data: EnemyData
@export var count: int = 5
## Delay in seconds before this group starts spawning (within the wave)
@export var group_delay: float = 0.0
## Interval between individual enemy spawns in this group
@export var spawn_interval: float = 1.0
