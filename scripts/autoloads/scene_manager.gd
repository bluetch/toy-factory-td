## ============================================================
## SceneManager — 场景管理器 (Scene Transition Manager)
## ============================================================
## Purpose: Centralise all scene changes behind a smooth
## fade-to-black animation so every transition looks consistent.
##
## Architecture:
##   This autoload owns a CanvasLayer (layer 100) that always
##   renders on top of the game world.  Inside it lives a
##   full-screen black ColorRect and an AnimationPlayer with two
##   named animations:
##     "fade_out" — alpha 0 → 1  (screen goes black)
##     "fade_in"  — alpha 1 → 0  (black lifts, scene visible)
##
## Usage:
##   SceneManager.goto_scene("res://scenes/game/game.tscn")
##   SceneManager.goto_main_menu()
##   SceneManager.goto_level(2)
## ============================================================

extends Node


# ── 既知场景路径 (Known Scene Paths) ─────────────────────────

const MAIN_MENU_SCENE:   String = "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT_SCENE: String = "res://scenes/ui/level_select.tscn"
const LEVEL_SCENE_TEMPLATE: String = "res://scenes/levels/level_%d.tscn"

## Duration in seconds for each half of the fade transition.
const FADE_DURATION: float = 0.4


# ── 内部节点引用 (Internal Node References) ──────────────────

## The CanvasLayer that keeps the overlay above everything else.
var _canvas_layer: CanvasLayer

## Full-screen black rectangle used as the fade overlay.
var _overlay: ColorRect

## Drives the fade_in and fade_out animations procedurally.
var _anim_player: AnimationPlayer

## Prevents overlapping transition calls.
var _is_transitioning: bool = false


# ── 生命周期 (Lifecycle) ──────────────────────────────────────

func _ready() -> void:
	_build_overlay()


## Construct all overlay nodes in code so no external scene file
## is required for the SceneManager autoload.
func _build_overlay() -> void:
	# ── CanvasLayer ───────────────────────────────────────────
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100          # Always on top.
	_canvas_layer.name  = "FadeLayer"
	add_child(_canvas_layer)

	# ── ColorRect (full-screen black, initially transparent) ──
	_overlay      = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.color                        = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.anchor_left                  = 0.0
	_overlay.anchor_top                   = 0.0
	_overlay.anchor_right                 = 1.0
	_overlay.anchor_bottom                = 1.0
	_overlay.offset_left                  = 0.0
	_overlay.offset_top                   = 0.0
	_overlay.offset_right                 = 0.0
	_overlay.offset_bottom                = 0.0
	_overlay.mouse_filter                 = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_overlay)

	# ── AnimationPlayer ───────────────────────────────────────
	_anim_player      = AnimationPlayer.new()
	_anim_player.name = "FadeAnimPlayer"
	_canvas_layer.add_child(_anim_player)

	_build_animations()


## Create the fade_out and fade_in animations programmatically
## so the autoload has zero external dependencies.
func _build_animations() -> void:
	var library := AnimationLibrary.new()

	# ── fade_out: transparent → opaque (screen goes black) ────
	var fade_out := Animation.new()
	fade_out.length = FADE_DURATION

	var track_out: int = fade_out.add_track(Animation.TYPE_VALUE)
	fade_out.track_set_path(track_out, "FadeOverlay:color:a")
	fade_out.track_insert_key(track_out, 0.0,           0.0)
	fade_out.track_insert_key(track_out, FADE_DURATION,  1.0)
	fade_out.loop_mode = Animation.LOOP_NONE

	# ── fade_in: opaque → transparent (scene becomes visible) ─
	var fade_in := Animation.new()
	fade_in.length = FADE_DURATION

	var track_in: int = fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(track_in, "FadeOverlay:color:a")
	fade_in.track_insert_key(track_in, 0.0,           1.0)
	fade_in.track_insert_key(track_in, FADE_DURATION,  0.0)
	fade_in.loop_mode = Animation.LOOP_NONE

	library.add_animation("fade_out", fade_out)
	library.add_animation("fade_in",  fade_in)

	_anim_player.add_animation_library("", library)


# ── 公共 API (Public API) ─────────────────────────────────────

## Transition to [param scene_path] with a fade-to-black effect.
## Calls are silently dropped while a transition is already running.
func goto_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# Make the overlay block input during the transition so the
	# player cannot click anything while the screen is black.
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# ── Fade out ──────────────────────────────────────────────
	_anim_player.play("fade_out")
	await _anim_player.animation_finished

	# ── Change scene ──────────────────────────────────────────
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneManager: Failed to load scene '%s' (error %d)." % [scene_path, err])
		# Fade back in so the player is not stuck on a black screen.
		_anim_player.play("fade_in")
		await _anim_player.animation_finished
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_is_transitioning     = false
		return

	# ── Fade in ───────────────────────────────────────────────
	_anim_player.play("fade_in")
	await _anim_player.animation_finished

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning     = false


## Reload the currently active scene.
func reload_scene() -> void:
	if _is_transitioning:
		return

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		push_error("SceneManager: No current scene to reload.")
		return

	goto_scene(current_scene.scene_file_path)


## Navigate to the main menu scene.
func goto_main_menu() -> void:
	goto_scene(MAIN_MENU_SCENE)


## Navigate to the level-select screen.
func goto_level_select() -> void:
	goto_scene(LEVEL_SELECT_SCENE)


## Navigate to the gameplay scene for the given level ID.
## [param level_id] Integer in the range 1–3.
func goto_level(level_id: int) -> void:
	var scene_path := LEVEL_SCENE_TEMPLATE % level_id
	goto_scene(scene_path)
