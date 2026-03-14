## GameWorld — root controller for active gameplay.
## Manages tower placement input, connects EventBus signals to UI,
## and bridges GridManager <-> WaveManager <-> towers/enemies.
class_name GameWorld
extends Node2D

## --- Node references (set via @onready with unique names %...) ---
@onready var grid_manager: GridManager         = $GridManager
@onready var wave_manager: WaveManager         = $WaveManager
@onready var tower_container: Node2D           = $TowerContainer
@onready var enemy_container: Node2D           = $EnemyContainer
@onready var projectile_container: Node2D      = $ProjectileContainer
@onready var hud: HUD                          = $UILayer/HUD
@onready var world_background: WorldBackground = $WorldBackground
@onready var factory_base: FactoryBase         = $FactoryBase
@onready var _camera: Camera2D                 = $Camera2D

const SHAKE_DURATION  := 0.35
const SHAKE_MAGNITUDE := 10.0
var _shake_timer: float = 0.0

## TowerData for the currently selected tower to place (null = select mode)
var _selected_tower_data: TowerData = null
## The tower node currently selected for upgrade/sell
var _selected_tower_node: Node = null

## Converted world-space waypoints for this level
var _world_waypoints: Array[Vector2] = []

func _ready() -> void:
	add_to_group("game_world")

	# Load level data
	var level_id := GameManager.current_level_id
	var level_res_path := "res://data/levels/level_%d.tres" % level_id
	var level_data: LevelData = load(level_res_path)
	if level_data == null:
		push_error("GameWorld: Could not load level data: " + level_res_path)
		return

	# Convert tile waypoints to world positions
	_world_waypoints = _tile_waypoints_to_world(level_data.waypoints)

	# Set up terrain background (must be before grid so it renders underneath)
	world_background.setup(level_data.waypoints)

	# Set up grid (marks path cells)
	grid_manager.setup(level_data.waypoints)

	# Position factory base at the end of the path
	if not _world_waypoints.is_empty():
		factory_base.global_position = _world_waypoints.back()

	# Connect EventBus FIRST — before setup() emits any signals
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)
	EventBus.all_waves_completed.connect(_on_all_waves_completed)
	EventBus.tower_selected.connect(_on_tower_selected)
	EventBus.tower_deselected.connect(_on_tower_deselected)
	EventBus.game_speed_changed.connect(_on_game_speed_changed)

	# Give HUD and TowerPanel a reference to this GameWorld node
	hud.set_game_world(self)
	if hud.tower_panel.has_method("set_game_world"):
		hud.tower_panel.set_game_world(self)

	# Connect WaveManager → HUD signals BEFORE setup() emits next_wave_ready
	wave_manager.next_wave_ready.connect(hud.on_next_wave_ready)
	wave_manager.next_wave_countdown.connect(hud.on_wave_countdown)
	wave_manager.all_waves_done.connect(hud.on_all_waves_done)

	# Set up wave manager last — setup() emits next_wave_ready immediately
	wave_manager.enemy_container = enemy_container
	wave_manager.set_waypoints(_world_waypoints)
	wave_manager.setup(level_data.waves, _world_waypoints[0] if not _world_waypoints.is_empty() else Vector2.ZERO)

	# Apply initial game speed
	Engine.time_scale = GameManager.game_speed

func _input(event: InputEvent) -> void:
	# ESC: cancel tower placement first, then pause
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			if _selected_tower_data != null:
				cancel_tower_placement()
				get_viewport().set_input_as_handled()
				return

	# Pause toggle
	if event.is_action_pressed("pause_game"):
		if GameManager.state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
		elif GameManager.state == GameManager.GameState.PAUSED:
			GameManager.resume_game()
		return

	# Tower placement click
	if _selected_tower_data != null and event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_try_place_tower(get_global_mouse_position())
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			cancel_tower_placement()
		return

	# Select existing tower on left click (when not in placement mode)
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_try_select_tower(get_global_mouse_position())
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			EventBus.tower_deselected.emit()

func _process(delta: float) -> void:
	# Update hover tile when in placement mode
	if _selected_tower_data != null:
		var tile := grid_manager.world_to_tile(get_global_mouse_position())
		grid_manager.set_hover(tile, grid_manager.can_build(tile))

	# Screen shake (enemy reached end, or boss death)
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var magnitude: float
		if _shake_override_timer > 0.0:
			_shake_override_timer -= delta
			magnitude = _shake_magnitude_override
		else:
			magnitude = SHAKE_MAGNITUDE
		var progress := maxf(_shake_timer / maxf(SHAKE_DURATION, 0.01), 0.0)
		_camera.offset = Vector2(
			randf_range(-1.0, 1.0) * magnitude * progress,
			randf_range(-1.0, 1.0) * magnitude * progress
		)
		if _shake_timer <= 0.0:
			_camera.offset = Vector2.ZERO

## Called by TowerPanel when player selects a tower to build
func begin_tower_placement(tower_data: TowerData) -> void:
	# Check if player can afford it
	if not GameManager.can_afford(tower_data.build_cost):
		hud.show_message("Not enough gold!")
		return
	_selected_tower_data = tower_data
	EventBus.tower_deselected.emit()

## Cancel current tower placement
func cancel_tower_placement() -> void:
	_selected_tower_data = null
	grid_manager.clear_hover()

## Attempt to place the selected tower at the given world position
func _try_place_tower(world_pos: Vector2) -> void:
	var tile := grid_manager.world_to_tile(world_pos)
	if not grid_manager.can_build(tile):
		hud.show_message("Cannot build here!")
		return
	if not GameManager.spend_gold(_selected_tower_data.build_cost):
		hud.show_message("Not enough gold!")
		return

	# Instantiate tower scene
	var packed: PackedScene = load(_selected_tower_data.scene_path)
	if packed == null:
		push_error("GameWorld: Could not load tower scene: " + _selected_tower_data.scene_path)
		return
	var tower: Node2D = packed.instantiate()
	tower_container.add_child(tower)
	tower.global_position = grid_manager.tile_to_world(tile)
	if tower.has_method("initialize"):
		tower.initialize(_selected_tower_data, projectile_container)

	grid_manager.place_tower(tile)
	EventBus.tower_placed.emit(tower, tile)

	# Stay in placement mode so player can place multiple towers
	# Press RMB or press Escape to exit
	# grid_manager hover stays active

## Try to select an already-placed tower
func _try_select_tower(world_pos: Vector2) -> void:
	for tower in tower_container.get_children():
		if tower is Node2D:
			var dist := (tower as Node2D).global_position.distance_to(world_pos)
			if dist < 40.0:
				EventBus.tower_selected.emit(tower)
				return
	EventBus.tower_deselected.emit()

func sell_selected_tower() -> void:
	if _selected_tower_node == null:
		return
	if not _selected_tower_node.has_method("get_sell_value"):
		return
	var refund: int = _selected_tower_node.get_sell_value()
	var tile := grid_manager.world_to_tile((_selected_tower_node as Node2D).global_position)
	GameManager.add_gold(refund)
	EventBus.tower_sold.emit(tile, refund)
	grid_manager.remove_tower(tile)
	_selected_tower_node.queue_free()
	_selected_tower_node = null
	EventBus.tower_deselected.emit()

func upgrade_selected_tower() -> void:
	if _selected_tower_node == null:
		return
	if not _selected_tower_node.has_method("upgrade"):
		return
	var upgrade_cost: int = _selected_tower_node.get_upgrade_cost()
	if not GameManager.spend_gold(upgrade_cost):
		hud.show_message("Not enough gold!")
		return
	_selected_tower_node.upgrade()
	EventBus.tower_upgraded.emit(_selected_tower_node, _selected_tower_node.current_level)

## Convert tile-coordinate waypoints to world-space Vector2 positions
func _tile_waypoints_to_world(tile_waypoints: Array[Vector2i]) -> Array[Vector2]:
	var world_wps: Array[Vector2] = []
	for tile in tile_waypoints:
		world_wps.append(grid_manager.tile_to_world(tile))
	return world_wps

# ---- EventBus callbacks ----

## Public: trigger a camera shake (used by BossEnemy on death)
func trigger_shake(duration: float, magnitude: float) -> void:
	_shake_timer              = maxf(_shake_timer, duration)
	_shake_magnitude_override = magnitude
	_shake_override_timer     = duration

var _shake_magnitude_override: float = 0.0
var _shake_override_timer:     float = 0.0

func _on_enemy_reached_end() -> void:
	GameManager.lose_life()
	_shake_timer = SHAKE_DURATION

func _on_all_waves_completed() -> void:
	# Short delay before showing victory screen
	await get_tree().create_timer(1.5).timeout
	GameManager.victory()

func _on_tower_selected(tower: Node) -> void:
	_selected_tower_node = tower
	cancel_tower_placement()
	hud.show_upgrade_panel(tower)

func _on_tower_deselected() -> void:
	_selected_tower_node = null
	hud.hide_upgrade_panel()

func _on_game_speed_changed(new_speed: float) -> void:
	Engine.time_scale = new_speed
