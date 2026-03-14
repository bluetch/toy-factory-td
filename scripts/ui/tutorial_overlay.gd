## TutorialOverlay — 教學覆蓋層 UI。
## 依據 TutorialManager 提供的步驟顯示說明、高亮區域、繼續按鈕。
extends Control

# ── 節點參考 ─────────────────────────────────────────────────

@onready var dimmer:         ColorRect = $Dimmer
@onready var step_panel:     PanelContainer = $StepPanel
@onready var step_label:     Label  = $StepPanel/VBox/StepLabel
@onready var title_label:    Label  = $StepPanel/VBox/TitleLabel
@onready var body_label:     Label  = $StepPanel/VBox/BodyLabel
@onready var wait_label:     Label  = $StepPanel/VBox/WaitLabel
@onready var continue_btn:   Button = $StepPanel/VBox/ContinueButton
@onready var highlight_rect: ColorRect = $HighlightRect

# ── 高亮座標（螢幕座標，1728×960 視口） ──────────────────────

const HIGHLIGHT_TOWER_PANEL := Rect2(1568, 56, 160, 660)
const HIGHLIGHT_GRID        := Rect2(48, 64, 1472, 832)
const HIGHLIGHT_TOPBAR      := Rect2(0, 0, 1728, 56)
const HIGHLIGHT_NONE        := Rect2(-10, -10, 1, 1)

# ── 步驟資料 ─────────────────────────────────────────────────

const STEP_DATA := {
	TutorialManager.Step.INTRO: {
		"step":    "教學 1 / 4",
		"title":   "🏭  歡迎來到發條工廠！",
		"body":    "你是玩具機器人 Coco（AK-0247）。\n你的任務是守護工廠基地，\n阻止敵人沿路徑走到終點。\n\n敵人每失去一隻，工廠就少一條生命。\n生命歸零 — 遊戲結束。",
		"wait":    "",
		"btn":     "明白了，開始！ ▶",
		"highlight": "none",
	},
	TutorialManager.Step.PLACE_TOWER: {
		"step":    "教學 2 / 4",
		"title":   "🔧  放置防禦塔",
		"body":    "① 點擊右側面板選擇一座防禦塔\n② 點擊地圖上的藍色（可建造）格子放置",
		"wait":    "⏳  等待你放置第一座塔…",
		"btn":     "",
		"highlight": "tower_panel",
	},
	TutorialManager.Step.WAVE_INFO: {
		"step":    "教學 3 / 4",
		"title":   "⏱  波次系統",
		"body":    "頂部倒計時歸零後，敵人自動開始入侵。\n你也可以按「開始波次 ▶」\n提前跳過等待時間。\n\n右上角「1x / 2x」可切換加速模式。",
		"wait":    "",
		"btn":     "了解 ▶",
		"highlight": "topbar",
	},
	TutorialManager.Step.UPGRADE_INFO: {
		"step":    "教學 4 / 4",
		"title":   "⬆  升級與販售",
		"body":    "點擊已放置的防禦塔，\n左下角會出現升級面板。\n\n• 升級：提升傷害、射程、射速\n• 販售：回收 70% 建造費用\n\n靈活調配，才能守住防線！",
		"wait":    "",
		"btn":     "出發！守護工廠 🏭",
		"highlight": "none",
	},
	TutorialManager.Step.COMPLETE: {
		"step":    "",
		"title":   "✅  教學完成！",
		"body":    "加油，Coco。\n工廠的命運就交給你了。",
		"wait":    "",
		"btn":     "開始遊戲 ▶",
		"highlight": "none",
	},
}

# ── 內部狀態 ─────────────────────────────────────────────────

var _manager: Node = null   ## TutorialManager 參考

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	# 初始隱藏高亮框
	_set_highlight("none")
	continue_btn.pressed.connect(_on_continue)

## 由 TutorialManager 呼叫，傳入自身參考
func setup(manager: Node) -> void:
	_manager = manager

# ── 步驟顯示 ─────────────────────────────────────────────────

func show_step(step: TutorialManager.Step) -> void:
	var data: Dictionary = STEP_DATA.get(step, {})
	if data.is_empty():
		return

	# 填寫文字
	step_label.text    = data.get("step", "")
	step_label.visible = step_label.text != ""
	title_label.text   = data.get("title", "")
	body_label.text    = data.get("body", "")
	wait_label.text    = data.get("wait", "")
	wait_label.visible = wait_label.text != ""

	var btn_text: String = data.get("btn", "")
	continue_btn.text    = btn_text
	continue_btn.visible = btn_text != ""

	# 高亮
	_set_highlight(data.get("highlight", "none"))

	# 入場動畫
	step_panel.modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(step_panel, "modulate:a", 1.0, 0.25)

func _set_highlight(key: String) -> void:
	match key:
		"tower_panel":
			_apply_highlight(HIGHLIGHT_TOWER_PANEL)
			dimmer.color.a = 0.55
		"grid":
			_apply_highlight(HIGHLIGHT_GRID)
			dimmer.color.a = 0.55
		"topbar":
			_apply_highlight(HIGHLIGHT_TOPBAR)
			dimmer.color.a = 0.55
		_:
			_apply_highlight(HIGHLIGHT_NONE)
			dimmer.color.a = 0.40

func _apply_highlight(rect: Rect2) -> void:
	highlight_rect.position = rect.position
	highlight_rect.size     = rect.size

# ── 按鈕回調 ─────────────────────────────────────────────────

func _on_continue() -> void:
	AudioManager.play_ui_click()
	if _manager != null and _manager.has_method("advance"):
		_manager.advance()

# ── 退出動畫 ─────────────────────────────────────────────────

func dismiss() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)
