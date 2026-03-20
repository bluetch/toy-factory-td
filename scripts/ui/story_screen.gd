## StoryScreen — displays a sequence of story entries with typewriter effect.
## Loaded by SceneManager after setting StoryDatabase.current_story_id.
class_name StoryScreen
extends Control

const CHARS_PER_SECOND := 38.0
const SPEAKER_COLORS: Dictionary = {
	"COCO":     Color(0.95, 0.72, 0.20),
	"齒輪爺爺": Color(0.72, 0.85, 0.55),
	"旁白":     Color(0.70, 0.80, 1.00),
	"Longing":  Color(0.80, 0.50, 1.00),
}
const DEFAULT_SPEAKER_COLOR := Color(0.90, 0.90, 0.90)

@onready var speaker_label:  Label             = $Right/VBox/SpeakerLabel
@onready var dialogue_text:  RichTextLabel     = $Right/VBox/DialogueText
@onready var continue_label: Label             = $Right/VBox/ContinueLabel
@onready var progress_label: Label             = $Right/VBox/ProgressLabel
@onready var portrait:       CharacterPortrait = $Left/Portrait
@onready var skip_label:     Label             = $SkipLabel
@onready var dialogue_vbox:  VBoxContainer     = $Right/VBox

var _entries: Array   = []
var _current_idx: int = 0
var _visible_chars: float = 0.0
var _typing_done: bool    = false
var _blink_timer: float   = 0.0
var _entry_tween: Tween   = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Ensure skip hint is visible and has the right prompt
	if skip_label != null:
		skip_label.text = "ESC 跳過 / 點擊繼續"
	AudioManager.play_track("story")
	var story_id := StoryDatabase.current_story_id
	_entries = StoryDatabase.get_story(story_id)
	if _entries.is_empty():
		SceneManager.story_complete()
		return
	_show_entry(0)


func _show_entry(idx: int) -> void:
	# Guard against missing scene nodes — if any required node is absent, bail gracefully.
	if dialogue_text == null or continue_label == null or speaker_label == null:
		push_error("StoryScreen: required dialogue nodes missing. Skipping story.")
		SceneManager.story_complete()
		return
	_current_idx   = idx
	_visible_chars = 0.0
	_typing_done   = false
	_blink_timer   = 0.0
	continue_label.modulate.a = 0.0   # hide without collapsing layout space

	var entry: Dictionary = _entries[idx]
	var speaker: String   = entry.get("speaker", "")
	speaker_label.text    = speaker
	speaker_label.modulate = SPEAKER_COLORS.get(speaker, DEFAULT_SPEAKER_COLOR)

	dialogue_text.text = entry.get("text", "")
	dialogue_text.visible_characters = 0

	# Animate dialogue panel: slide in from the right + fade
	dialogue_vbox.modulate.a = 0.0
	if _entry_tween:
		_entry_tween.kill()
	_entry_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_entry_tween.tween_property(dialogue_vbox, "modulate:a", 1.0, 0.25)

	# Cross-fade portrait (guard against null portrait node)
	var new_portrait: String = entry.get("portrait", "narrator")
	if portrait != null:
		portrait.fade_to(new_portrait)

	# Progress label
	if progress_label != null:
		progress_label.text = "%d / %d" % [idx + 1, _entries.size()]


func _process(delta: float) -> void:
	if dialogue_text == null or continue_label == null:
		return
	if not _typing_done:
		var char_count: int = dialogue_text.text.length()
		_visible_chars = minf(_visible_chars + delta * CHARS_PER_SECOND, float(char_count))
		dialogue_text.visible_characters = int(_visible_chars)
		if int(_visible_chars) >= char_count:
			_typing_done = true
			_blink_timer = 0.0   # blink loop will drive modulate.a from here
	else:
		# Blink continue label
		_blink_timer += delta
		continue_label.modulate.a = 0.55 + 0.45 * sin(_blink_timer * TAU * 0.9)


func _input(event: InputEvent) -> void:
	# Escape key → skip entire story
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			SceneManager.story_complete()
			get_viewport().set_input_as_handled()
			return

	# Advance on click or Space/Enter/Z
	var is_advance := false
	if event is InputEventMouseButton:
		is_advance = (event as InputEventMouseButton).pressed
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		is_advance = key_event.pressed and not key_event.echo \
			and (key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER \
				or key_event.keycode == KEY_Z)

	if not is_advance:
		return

	AudioManager.play_ui_click()

	if not _typing_done:
		# Complete current line instantly
		_visible_chars = float(dialogue_text.text.length())
		dialogue_text.visible_characters = dialogue_text.text.length()
		_typing_done = true
		_blink_timer = 0.0
	else:
		_advance()
	get_viewport().set_input_as_handled()


func _advance() -> void:
	var next_idx := _current_idx + 1
	if next_idx >= _entries.size():
		SceneManager.story_complete()
	else:
		_show_entry(next_idx)
