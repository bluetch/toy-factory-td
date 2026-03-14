## TutorialManager — 管理首次遊玩的教學引導。
## 當 SaveManager 尚未記錄 "tutorial_done" 時，
## 在 GameWorld 場景載入後自動啟動教學覆蓋層。
extends Node

enum Step {
	INTRO,          ## 歡迎說明
	PLACE_TOWER,    ## 選塔並放置
	WAVE_INFO,      ## 波次說明
	UPGRADE_INFO,   ## 升級/販售說明
	COMPLETE,       ## 教學結束
}

const OVERLAY_SCENE := "res://scenes/ui/TutorialOverlay.tscn"
const SETTING_KEY   := "tutorial_done"

var _current_step: Step = Step.INTRO
var _overlay: Node = null
var _is_active: bool = false
var _tower_placed_connected: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	# 監聽場景樹節點新增，偵測 GameWorld 是否就緒
	get_tree().node_added.connect(_on_node_added)

# ── 啟動偵測 ─────────────────────────────────────────────────

func _on_node_added(node: Node) -> void:
	if _is_active:
		return
	if node.is_in_group("game_world") and not SaveManager.get_setting_bool(SETTING_KEY):
		# 延遲一幀讓 GameWorld._ready() 完整執行
		call_deferred("_start_tutorial", node)

func _start_tutorial(game_world: Node) -> void:
	if _is_active:
		return
	_is_active = true
	_current_step = Step.INTRO

	var packed: PackedScene = load(OVERLAY_SCENE)
	if packed == null:
		push_warning("TutorialManager: Cannot load overlay scene.")
		_is_active = false
		return

	_overlay = packed.instantiate()

	# 掛載到 UILayer（若存在）以確保渲染在最頂層
	var ui_layer: Node = game_world.get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(_overlay)
	else:
		game_world.add_child(_overlay)

	if _overlay.has_method("setup"):
		_overlay.setup(self)

	_show_current_step()

# ── 步驟控制 ─────────────────────────────────────────────────

func _show_current_step() -> void:
	if _overlay != null and _overlay.has_method("show_step"):
		_overlay.show_step(_current_step)

## 由 TutorialOverlay 的「繼續」按鈕呼叫
func advance() -> void:
	match _current_step:
		Step.INTRO:
			_current_step = Step.PLACE_TOWER
			# 等待玩家放置第一座塔
			if not _tower_placed_connected:
				EventBus.tower_placed.connect(_on_tower_placed, CONNECT_ONE_SHOT)
				_tower_placed_connected = true
		Step.WAVE_INFO:
			_current_step = Step.UPGRADE_INFO
		Step.UPGRADE_INFO:
			_current_step = Step.COMPLETE
		Step.COMPLETE:
			_finish()
	_show_current_step()

## 玩家成功放置第一座塔後自動前進
func _on_tower_placed(_tower: Node, _tile: Vector2i) -> void:
	_tower_placed_connected = false
	_current_step = Step.WAVE_INFO
	_show_current_step()

# ── 結束 ─────────────────────────────────────────────────────

func _finish() -> void:
	SaveManager.set_setting_bool(SETTING_KEY, true)
	_is_active = false
	if _overlay != null and is_instance_valid(_overlay):
		# 滑出動畫後 queue_free（由 overlay 自行處理）
		if _overlay.has_method("dismiss"):
			_overlay.dismiss()
		else:
			_overlay.queue_free()
	_overlay = null

## 讓玩家在設定畫面重置教學（下次進遊玩場景時重新觸發）
func reset_tutorial() -> void:
	SaveManager.set_setting_bool(SETTING_KEY, false)
