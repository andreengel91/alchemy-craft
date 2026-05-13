extends Node

const SETTINGS_PATH       := "user://settings.cfg"
const DEFAULT_MUSIC_VOL   := 0.8
const DEFAULT_SFX_VOL     := 1.0

var music_volume: float = DEFAULT_MUSIC_VOL
var sfx_volume:   float = DEFAULT_SFX_VOL
var music_muted:  bool  = false
var sfx_muted:    bool  = false

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_load_settings()
	_apply_music()
	_apply_sfx()

# ── Public setters (called by pause menu) ────────────────────────────────────

func set_music_volume(linear: float) -> void:
	music_volume = linear
	_apply_music()
	_save_settings()

func set_sfx_volume(linear: float) -> void:
	sfx_volume = linear
	_apply_sfx()
	_save_settings()

func set_music_muted(muted: bool) -> void:
	music_muted = muted
	_apply_music()
	_save_settings()

func set_sfx_muted(muted: bool) -> void:
	sfx_muted = muted
	_apply_sfx()
	_save_settings()

# ── Internal ──────────────────────────────────────────────────────────────────

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func _apply_music() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, -80.0 if music_muted else _to_db(music_volume))

func _apply_sfx() -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, -80.0 if sfx_muted else _to_db(sfx_volume))

func _to_db(linear: float) -> float:
	return linear_to_db(linear) if linear > 0.0001 else -80.0

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume",   sfx_volume)
	cfg.set_value("audio", "music_muted",  music_muted)
	cfg.set_value("audio", "sfx_muted",    sfx_muted)
	cfg.save(SETTINGS_PATH)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume = cfg.get_value("audio", "music_volume", DEFAULT_MUSIC_VOL)
	sfx_volume   = cfg.get_value("audio", "sfx_volume",   DEFAULT_SFX_VOL)
	music_muted  = cfg.get_value("audio", "music_muted",  false)
	sfx_muted    = cfg.get_value("audio", "sfx_muted",    false)
