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
	_show_confirm_dialog()

# ── Reset confirmation dialog ─────────────────────────────────────────────────

var _confirm_dialog: Control = null

func _show_confirm_dialog() -> void:
	if _confirm_dialog != null:
		return

	# Full-screen root — blocks all mouse input to elements beneath it.
	_confirm_dialog = Control.new()
	_confirm_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm_dialog)

	# Semi-transparent dark overlay.
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_dialog.add_child(overlay)

	# Centre the dialog box.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_dialog.add_child(center)

	# Dialog panel — parchment background with dark-brown border.
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(300, 120)
	var sbox := StyleBoxFlat.new()
	sbox.bg_color          = Color(0.82, 0.73, 0.55)
	sbox.border_width_left  = 3
	sbox.border_width_top   = 3
	sbox.border_width_right = 3
	sbox.border_width_bottom = 3
	sbox.border_color = Color(0.45, 0.28, 0.10)
	sbox.corner_radius_top_left     = 6
	sbox.corner_radius_top_right    = 6
	sbox.corner_radius_bottom_right = 6
	sbox.corner_radius_bottom_left  = 6
	panel.add_theme_stylebox_override("panel", sbox)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   24)
	margin.add_theme_constant_override("margin_top",    22)
	margin.add_theme_constant_override("margin_right",  24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Warning label.
	var lbl := Label.new()
	lbl.text = "Are you sure?\nAll progress will be lost."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl)

	# Button row.
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)

	hbox.add_child(_make_dialog_btn("Cancel",  Color(0.61, 0.44, 0.29, 1.0), Color(0.86, 0.77, 0.63), _close_confirm_dialog))
	hbox.add_child(_make_dialog_btn("Confirm", Color(0.60, 0.22, 0.10), Color(0.70, 0.30, 0.16), _on_confirm_reset))

func _make_dialog_btn(label: String, bg: Color, bg_hover: Color, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(110, 28)
	btn.focus_mode = Control.FOCUS_NONE

	var _sbox := func(color: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = color
		s.corner_radius_top_left     = 4
		s.corner_radius_top_right    = 4
		s.corner_radius_bottom_right = 4
		s.corner_radius_bottom_left  = 4
		s.content_margin_left  = 8.0
		s.content_margin_right = 8.0
		return s

	btn.add_theme_stylebox_override("normal",  _sbox.call(bg))
	btn.add_theme_stylebox_override("hover",   _sbox.call(bg_hover))
	btn.add_theme_stylebox_override("pressed", _sbox.call(bg))
	btn.add_theme_color_override("font_color",         Color(0.92, 0.87, 0.78))
	btn.add_theme_color_override("font_hover_color",   Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.87, 0.78))
	btn.pressed.connect(cb)
	return btn

func _close_confirm_dialog() -> void:
	if _confirm_dialog != null:
		_confirm_dialog.queue_free()
		_confirm_dialog = null

func _on_confirm_reset() -> void:
	_close_confirm_dialog()
	emit_signal("reset_requested")

func _on_achievements_pressed() -> void:
	emit_signal("achievements_requested")

func _on_quit_button_pressed() -> void:
	emit_signal("quit_requested")
