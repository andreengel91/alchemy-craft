extends Control

@onready var _list: VBoxContainer = %AchievList

func _ready() -> void:
	_build_list()

func _build_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	for id in AchievementManager.ACHIEVEMENTS.keys():
		_list.add_child(_make_row(id))

# ── Row builder ───────────────────────────────────────────────────────────────

func _make_row(id: String) -> Control:
	var a: Dictionary  = AchievementManager.ACHIEVEMENTS[id]
	var done: bool     = id in AchievementManager.unlocked

	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, 56)

	var sbox := StyleBoxFlat.new()
	sbox.bg_color = Color(0.10, 0.07, 0.18, 0.80) if done else Color(0.06, 0.04, 0.11, 0.60)
	sbox.border_width_left   = 1
	sbox.border_width_top    = 1
	sbox.border_width_right  = 1
	sbox.border_width_bottom = 1
	sbox.border_color = Color(0.55, 0.42, 0.75) if done else Color(0.22, 0.18, 0.30)
	sbox.corner_radius_top_left     = 4
	sbox.corner_radius_top_right    = 4
	sbox.corner_radius_bottom_right = 4
	sbox.corner_radius_bottom_left  = 4
	row.add_theme_stylebox_override("panel", sbox)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)

	# Icon
	var icon := Label.new()
	icon.text = "★" if done else "○"
	icon.custom_minimum_size = Vector2(24, 0)
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color",
		Color(1.0, 0.85, 0.20) if done else Color(0.35, 0.30, 0.45))
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Text column
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = a["title"] if done else "???"
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.35) if done else Color(0.40, 0.35, 0.50))
	vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = a["desc"] if done else "Keep discovering more recipes..."
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color",
		Color(0.72, 0.68, 0.80) if done else Color(0.35, 0.32, 0.42))
	vbox.add_child(desc_lbl)

	# Checkmark
	var check := Label.new()
	check.text = "✓" if done else ""
	check.add_theme_font_size_override("font_size", 14)
	check.add_theme_color_override("font_color", Color(0.40, 0.90, 0.45))
	check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(check)

	return row

# ── Signals ───────────────────────────────────────────────────────────────────

func _on_close_button_pressed() -> void:
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		get_viewport().set_input_as_handled()
		queue_free()
