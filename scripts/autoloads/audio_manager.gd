## ============================================================
## AudioManager — 音频管理器 (Audio Manager)
## ============================================================
## Purpose: Centralised control point for all game audio.
## Owns two AudioStreamPlayer nodes (music + SFX) and exposes
## a clean API for the rest of the game to play sounds without
## needing direct references to any audio node.
##
## Bus layout (configure in Project → Audio):
##   Master
##   ├─ Music   (used by the music player)
##   └─ SFX     (used by the SFX player)
##
## Volumes are loaded from SaveManager on _ready() so they
## survive between sessions.
##
## Usage:
##   AudioManager.play_music(preload("res://audio/music/theme.ogg"))
##   AudioManager.play_sfx(preload("res://audio/sfx/shoot.wav"))
##   AudioManager.set_music_volume(0.8)
## ============================================================

extends Node


# ── 常量 (Constants) ──────────────────────────────────────────

## SaveManager settings key for music volume.
const SETTING_MUSIC_VOLUME: String = "music_volume"

## ── 音樂軌道路徑 (Music Track Paths) ────────────────────────
## 將音樂檔案放置於對應路徑後即可自動載入並播放。
## 格式：Ogg Vorbis（.ogg），建議取自 OpenGameArt / Freesound（CC0 授權）。
## 每個軌道依序嘗試路徑清單，第一個存在的檔案將被載入。
## 這樣可以讓高品質 Sonniss 檔案自動覆蓋佔位 .ogg。
const MUSIC_TRACKS: Dictionary = {
	"menu":     ["res://assets/audio/music/music_menu_box.wav",
				 "res://assets/audio/music/music_menu.ogg"],
	"gameplay": ["res://assets/audio/music/music_gameplay.ogg"],
	"boss":     ["res://assets/audio/music/music_boss.ogg"],
	"victory":  ["res://assets/audio/music/music_victory.ogg"],
	"story":    ["res://assets/audio/music/music_story.wav",
				 "res://assets/audio/music/music_story.ogg"],
}

## 目前正在播放的軌道名稱（空字串 = 無音樂）
var _current_track: String = ""

## SaveManager settings key for SFX volume.
const SETTING_SFX_VOLUME: String = "sfx_volume"

## Duration in seconds for the music fade-in tween.
const MUSIC_FADE_DURATION: float = 1.5

## Minimum linear volume (maps to roughly -80 dB — effectively muted).
const MIN_VOLUME_LINEAR: float = 0.0001


# ── 内部节点 (Internal Nodes) ─────────────────────────────────

## Dedicated player for background music (long looping streams).
var _music_player: AudioStreamPlayer

## Pool of short one-shot SFX players for polyphonic playback.
## Multiple towers can fire simultaneously without cutting each other off.
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
const SFX_POOL_SIZE: int = 8

var ui_click_sfx: AudioStream = null

## Game event SFX (loaded lazily — null if file not present)
var _sfx_tower_place:        AudioStream = null
var _sfx_tower_upgrade:      AudioStream = null
var _sfx_tower_sell:         AudioStream = null
var _sfx_enemy_die:          AudioStream = null
var _sfx_life_lost:          AudioStream = null
var _sfx_game_over:          AudioStream = null
var _sfx_victory_sting:      AudioStream = null
var _sfx_enemy_hit:          AudioStream = null
var _sfx_slow_applied:       AudioStream = null
var _sfx_explosion:          AudioStream = null
var _sfx_tower_select:       AudioStream = null
var _sfx_invalid_placement:  AudioStream = null

## Active fade tween so we can kill it before starting a new one.
var _fade_tween: Tween = null


# ── 生命周期 (Lifecycle) ──────────────────────────────────────

func _ready() -> void:
	_build_players()
	_load_volumes_from_save()
	ui_click_sfx        = load("res://assets/audio/ui_click.wav")
	_sfx_tower_place    = _load_first(["res://assets/audio/sfx_tower_place_hq.wav",
									   "res://assets/audio/sfx_tower_place.ogg"])
	_sfx_tower_upgrade  = load("res://assets/audio/sfx_tower_upgrade.ogg")
	_sfx_tower_sell     = load("res://assets/audio/sfx_tower_sell.ogg")
	_sfx_enemy_die      = load("res://assets/audio/sfx_enemy_die.ogg")
	_sfx_life_lost      = load("res://assets/audio/sfx_life_lost.ogg")
	_sfx_game_over      = load("res://assets/audio/sfx_game_over.ogg")
	_sfx_victory_sting  = load("res://assets/audio/sfx_victory.ogg")
	## Fallback SFX — each property tries candidate paths in order (HQ → .ogg → Kenney).
	## Uses the same _load_first() pattern as MUSIC_TRACKS for consistency.
	const FALLBACK_SFX: Dictionary = {
		"_sfx_enemy_hit": [
			"res://assets/audio/sfx_enemy_hit.wav",
			"res://assets/audio/sfx_enemy_hit.ogg",
			"res://assets/kenney_impact-sounds/Audio/impactGeneric_light_000.ogg",
		],
		"_sfx_slow_applied": [
			"res://assets/audio/sfx_slow_applied.wav",
			"res://assets/audio/sfx_slow_applied.ogg",
			"res://assets/kenney_interface-sounds/Audio/glass_002.ogg",
		],
		"_sfx_explosion": [
			"res://assets/audio/sfx_explosion.wav",
			"res://assets/audio/sfx_explosion.ogg",
			"res://assets/kenney_impact-sounds/Audio/impactMetal_heavy_000.ogg",
		],
		"_sfx_tower_select": [
			"res://assets/audio/sfx_tower_select.wav",
			"res://assets/audio/sfx_tower_select.ogg",
			"res://assets/kenney_interface-sounds/Audio/select_001.ogg",
		],
		"_sfx_invalid_placement": [
			"res://assets/audio/sfx_invalid_placement.wav",
			"res://assets/audio/sfx_invalid_placement.ogg",
			"res://assets/kenney_interface-sounds/Audio/error_001.ogg",
		],
	}
	for prop: String in FALLBACK_SFX:
		set(prop, _load_first(FALLBACK_SFX[prop]))


## Create and configure both AudioStreamPlayer children.
func _build_players() -> void:
	# ── Music player ──────────────────────────────────────────
	_music_player      = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus  = "Music"
	# Music should loop; set the stream's loop flag when assigning.
	add_child(_music_player)

	# ── SFX pool ──────────────────────────────────────────────
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer%d" % i
		p.bus  = "SFX"
		add_child(p)
		_sfx_pool.append(p)


## Read stored volume preferences and apply them.
func _load_volumes_from_save() -> void:
	var music_vol: float = SaveManager.get_setting(SETTING_MUSIC_VOLUME)
	var sfx_vol:   float = SaveManager.get_setting(SETTING_SFX_VOLUME)
	_apply_volume_to_player(_music_player, music_vol)
	for p in _sfx_pool:
		_apply_volume_to_player(p, sfx_vol)


# ── 音乐 API (Music API) ──────────────────────────────────────

## Play [param stream] as background music.
## If [param fade_in] is true the volume tweens from silence to
## the current music volume over MUSIC_FADE_DURATION seconds.
## Passing null is safe — it just stops the current music.
func play_music(stream: AudioStream, fade_in: bool = true) -> void:
	# Kill any in-progress fade so we don't fight ourselves.
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null

	if stream == null:
		stop_music()
		return

	# Remember the target volume before we potentially zero it out.
	var target_volume_db: float = _music_player.volume_db

	if fade_in:
		# Start silent, then tween up to the stored volume.
		_music_player.volume_db = linear_to_db(MIN_VOLUME_LINEAR)

	_music_player.stream = stream
	_music_player.play()

	if fade_in:
		_fade_tween = create_tween()
		_fade_tween.tween_property(
			_music_player,
			"volume_db",
			target_volume_db,
			MUSIC_FADE_DURATION
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## 以軌道名稱播放音樂（如 "menu", "gameplay", "boss"）。
## 若音樂檔案不存在則靜默忽略，不影響遊戲運作。
## 若已在播放相同軌道則不重複啟動。
func play_track(track_name: String, fade_in: bool = true) -> void:
	if track_name == _current_track and _music_player.playing:
		return
	if not MUSIC_TRACKS.has(track_name):
		push_warning("AudioManager: Unknown track '%s'." % track_name)
		return
	# Each track is now an Array of candidate paths; first existing file wins.
	var paths: Array = MUSIC_TRACKS[track_name]
	var stream: AudioStream = null
	for path: String in paths:
		if ResourceLoader.exists(path):
			stream = load(path)
			if stream != null:
				break
	if stream == null:
		return   ## 所有候選路徑皆不存在，靜默略過
	_current_track = track_name
	play_music(stream, fade_in)

## Stop the music player immediately.
func stop_music() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null

	if _music_player.playing:
		_music_player.stop()


# ── 音效 API (SFX API) ────────────────────────────────────────

## Play a one-shot sound effect using the round-robin pool.
## Multiple overlapping sounds (e.g. rapid tower fire) won't cut each other off.
## Null streams are silently ignored so callers don't need to guard against
## unloaded assets during development.
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.play()


## Convenience wrapper — plays the UI click sound assigned to ui_click_sfx.
## Call from any button pressed callback.
func play_ui_click() -> void:
	play_sfx(ui_click_sfx)

## Game event SFX convenience methods
func play_tower_place()        -> void: play_sfx(_sfx_tower_place)
func play_tower_upgrade()      -> void: play_sfx(_sfx_tower_upgrade)
func play_tower_sell()         -> void: play_sfx(_sfx_tower_sell)
func play_enemy_die()          -> void: play_sfx(_sfx_enemy_die)
func play_life_lost()          -> void: play_sfx(_sfx_life_lost)
func play_game_over()          -> void: play_sfx(_sfx_game_over)
func play_victory_sting()      -> void: play_sfx(_sfx_victory_sting)
func play_enemy_hit()          -> void: play_sfx(_sfx_enemy_hit)
func play_slow_applied()       -> void: play_sfx(_sfx_slow_applied)
func play_explosion()          -> void: play_sfx(_sfx_explosion)
func play_tower_select()       -> void: play_sfx(_sfx_tower_select)
func play_invalid_placement()  -> void: play_sfx(_sfx_invalid_placement)


# ── 音量控制 (Volume Control) ─────────────────────────────────

## Set music volume. [param vol] must be in the range 0.0–1.0.
## Persists the new value to SaveManager.
func set_music_volume(vol: float) -> void:
	vol = clampf(vol, 0.0, 1.0)
	_apply_volume_to_player(_music_player, vol)
	SaveManager.set_setting(SETTING_MUSIC_VOLUME, vol)


## Set SFX volume. [param vol] must be in the range 0.0–1.0.
## Persists the new value to SaveManager.
func set_sfx_volume(vol: float) -> void:
	vol = clampf(vol, 0.0, 1.0)
	for p in _sfx_pool:
		_apply_volume_to_player(p, vol)
	SaveManager.set_setting(SETTING_SFX_VOLUME, vol)


# ── 内部工具 (Internal Helpers) ───────────────────────────────

## Load the first existing path from a list; returns null if none found.
func _load_first(paths: Array) -> AudioStream:
	for path: String in paths:
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path)
			if s != null:
				return s
	return null

## Load an optional SFX file into the named property; silent no-op if missing.
func _try_load_sfx(path: String, property: String) -> void:
	if ResourceLoader.exists(path):
		set(property, load(path))


## Convert a linear 0.0–1.0 value to dB and assign it to
## [param player].  Values at or below MIN_VOLUME_LINEAR are
## treated as effectively muted to avoid -infinity dB.
func _apply_volume_to_player(player: AudioStreamPlayer, linear_vol: float) -> void:
	var clamped := maxf(linear_vol, MIN_VOLUME_LINEAR)
	player.volume_db = linear_to_db(clamped)
