extends Control

signal resumed
signal reset_requested
signal quit_requested
signal achievements_requested

@onready var _music_slider: HSlider  = %MusicSlider
@onready var _music_mute:   CheckBox = %MusicMute
@onready var _sfx_slider:   HSlider  = %SFXSlider
@onready var _sfx_mute:     CheckBox = %SFXMute

func _ready() -> void:
	_music_slider.set_value_no_signal(AudioManager.music_volume)
	_music_mute.set_pressed_no_signal(AudioManager.music_muted)
	_sfx_slider.set_value_no_signal(AudioManager.sfx_volume)
	_sfx_mute.set_pressed_no_signal(AudioManager.sfx_muted)

# ── Audio handlers ────────────────────────────────────────────────────────────

func _on_music_slider_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_music_mute_toggled(pressed: bool) -> void:
	AudioManager.set_music_muted(pressed)

func _on_sfx_slider_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)

func _on_sfx_mute_toggled(pressed: bool) -> void:
	AudioManager.set_sfx_muted(pressed)

# ── Menu button handlers ──────────────────────────────────────────────────────

func _on_resume_pressed() -> void:
	emit_signal("resumed")

func _on_reset_pressed() -> void:
	emit_signal("reset_requested")

func _on_achievements_pressed() -> void:
	emit_signal("achievements_requested")

func _on_quit_button_pressed() -> void:
	emit_signal("quit_requested")
