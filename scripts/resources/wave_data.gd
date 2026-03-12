## WaveData — defines one wave (list of enemy groups).
class_name WaveData
extends Resource

@export var wave_number: int = 1
## Seconds after the previous wave ends before this wave auto-starts
## If -1, player must press "Next Wave" manually
@export var auto_start_delay: float = -1.0
@export var entries: Array[WaveEntry] = []
