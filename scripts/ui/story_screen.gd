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

@onready var speaker_label:  Label              = $Right/VBox/SpeakerLabel
@onready var dialogue_text:  RichTextLabel      = $Right/VBox/DialogueText
@onready var continue_label: Label              = $Right/VBox/ContinueLabel
@onready var portrait:       CharacterPortrait  = $Left/Portrait
@onready var skip_label:     Label              = $SkipLabel

var _entries: Array   = []
var _current_idx: int = 0
var _visible_chars: float = 0.0
var _typing_done: bool    = false


func _ready() -> void:
	var story_id := StoryDatabase.current_story_id
	_entries = StoryDatabase.get_story(story_id)
	if _entries.is_empty():
		SceneManager.story_complete()
		return
	_show_entry(0)


func _show_entry(idx: int) -> void:
	_current_idx   = idx
	_visible_chars = 0.0
	_typing_done   = false
	continue_label.visible = false

	var entry: Dictionary = _entries[idx]
	var speaker: String   = entry.get("speaker", "")
	speaker_label.text    = speaker
	speaker_label.modulate = SPEAKER_COLORS.get(speaker, DEFAULT_SPEAKER_COLOR)
	dialogue_text.text    = entry.get("text", "")
	dialogue_text.visible_characters = 0
	portrait.set_character(entry.get("portrait", "narrator"))


func _process(delta: float) -> void:
	if _typing_done:
		return
	var char_count: int = dialogue_text.text.length()
	_visible_chars = minf(_visible_chars + delta * CHARS_PER_SECOND, float(char_count))
	dialogue_text.visible_characters = int(_visible_chars)
	if int(_visible_chars) >= char_count:
		_typing_done = true
		continue_label.visible = true


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

	if not _typing_done:
		_visible_chars = float(dialogue_text.text.length())
		dialogue_text.visible_characters = dialogue_text.text.length()
		_typing_done = true
		continue_label.visible = true
	else:
		_advance()
	get_viewport().set_input_as_handled()


func _advance() -> void:
	var next_idx := _current_idx + 1
	if next_idx >= _entries.size():
		SceneManager.story_complete()
	else:
		_show_entry(next_idx)
