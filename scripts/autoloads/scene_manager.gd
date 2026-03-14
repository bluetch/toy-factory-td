## SceneManager — handles scene transitions with a fade-to-black effect.
## Uses a Tween (not AnimationPlayer) for reliability when created in code.
##
## Usage:
##   SceneManager.goto_level(1)
##   SceneManager.goto_main_menu()
##   SceneManager.goto_level_select()

extends Node

# ── Scene paths ──────────────────────────────────────────────
const MAIN_MENU_SCENE:    String = "res://scenes/MainMenu.tscn"
const LEVEL_SELECT_SCENE: String = "res://scenes/LevelSelect.tscn"
const GAME_WORLD_SCENE:   String = "res://scenes/GameWorld.tscn"
const STORY_SCREEN_SCENE: String = "res://scenes/StoryScreen.tscn"
const SETTINGS_SCENE:     String = "res://scenes/SettingsScreen.tscn"

const FADE_DURATION: float = 0.3

# ── Internal nodes ───────────────────────────────────────────
var _overlay: ColorRect
var _is_transitioning: bool = false
var _pending_after_story: Callable = Callable()
var _settings_return_path: String = ""

func _ready() -> void:
	# Build a full-screen black overlay on a top-level CanvasLayer
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	_overlay = ColorRect.new()
	_overlay.color        = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.anchor_right  = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_overlay)

# ── Public API ───────────────────────────────────────────────

func goto_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fade to black
	await _fade(1.0)

	# Change scene
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneManager: Failed to load '%s' (err %d)" % [scene_path, err])
		await _fade(0.0)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_is_transitioning = false
		return

	# Wait one frame so the new scene's _ready() runs before fade-in
	await get_tree().process_frame

	# Fade in
	await _fade(0.0)

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false

func reload_scene() -> void:
	var path := get_tree().current_scene.scene_file_path
	goto_scene(path)

func goto_main_menu() -> void:
	goto_scene(MAIN_MENU_SCENE)

func goto_level_select() -> void:
	goto_scene(LEVEL_SELECT_SCENE)

## Sets level data on GameManager then loads the shared GameWorld scene.
## Shows a story cutscene first if one exists for this level.
func goto_level(level_id: int) -> void:
	GameManager.start_level(level_id)
	var story_id := "story_%d" % level_id
	if StoryDatabase.has_story(story_id):
		goto_story(story_id, func() -> void: goto_scene(GAME_WORLD_SCENE))
	else:
		goto_scene(GAME_WORLD_SCENE)

## Show a story sequence then call after_callable when done.
func goto_story(story_id: String, after_callable: Callable) -> void:
	if not StoryDatabase.has_story(story_id):
		after_callable.call()
		return
	StoryDatabase.current_story_id = story_id
	_pending_after_story = after_callable
	goto_scene(STORY_SCREEN_SCENE)

## Called by StoryScreen when all entries are done (or ESC pressed).
func story_complete() -> void:
	var cb := _pending_after_story
	_pending_after_story = Callable()
	if cb.is_valid():
		cb.call()
	else:
		goto_main_menu()

## Open the settings screen and return to [param return_path] when done.
func goto_settings(return_path: String) -> void:
	_settings_return_path = return_path
	goto_scene(SETTINGS_SCENE)

## Called by SettingsScreen back button — returns to the scene that opened settings.
func settings_done() -> void:
	var path := _settings_return_path
	_settings_return_path = ""
	if path != "":
		goto_scene(path)
	else:
		goto_main_menu()

## Play a post-level outro cutscene (outro_N), then call on_complete.
## If no outro exists for level_id, calls on_complete immediately.
func goto_level_outro(level_id: int, on_complete: Callable) -> void:
	var outro_id := "outro_%d" % level_id
	if StoryDatabase.has_story(outro_id):
		goto_story(outro_id, on_complete)
	else:
		on_complete.call()

# ── Private helpers ──────────────────────────────────────────

## Tween _overlay alpha to [target] over FADE_DURATION seconds.
func _fade(target: float) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", target, FADE_DURATION)
	await tween.finished
