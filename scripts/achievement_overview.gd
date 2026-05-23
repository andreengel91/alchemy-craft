extends Control

@onready var _list:        VBoxContainer = %AchievList
@onready var _counter_lbl: Label         = %CounterLabel
@onready var _counter_bar: ProgressBar   = %CounterBar

func _ready() -> void:
	_build_list()

func _build_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	for id in AchievementManager.ACHIEVEMENTS.keys():
		_list.add_child(_make_row(id))
	_refresh_counter()

func _refresh_counter() -> void:
	var total := AchievementManager.ACHIEVEMENTS.size()
	var done  := AchievementManager.unlocked.size()
	var pct   := int(round(float(done) / float(total) * 100.0)) if total > 0 else 0
	_counter_lbl.text      = "%d / %d Achievements \n (%d%%)" % [done, total, pct]
	_counter_bar.max_value = total
	_counter_bar.value     = done

# ── Row builder ───────────────────────────────────────────────────────────────

func _make_row(id: String) -> Control:
	var a: Dictionary  = AchievementManager.ACHIEVEMENTS[id]
	var done: bool     = id in AchievementManager.unlocked

	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, 56)

	var sbox := StyleBoxFlat.new()
	sbox.bg_color = Color(0.80, 0.71, 0.54) if done else Color(0.612, 0.435, 0.294, 0.604)
	sbox.border_width_left   = 0
	sbox.border_width_top    = 0
	sbox.border_width_right  = 0
	sbox.border_width_bottom = 0
	sbox.border_color = Color(0.0, 0.0, 0.0, 0.0) if done else Color(0.0, 0.0, 0.0, 0.0)
	sbox.corner_radius_top_left     = 0
	sbox.corner_radius_top_right    = 0
	sbox.corner_radius_bottom_right = 0
	sbox.corner_radius_bottom_left  = 0
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
		Color(0.298, 0.169, 0.031, 1.0) if done else Color(0.612, 0.435, 0.294, 1.0))
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
		Color(0.298, 0.169, 0.031, 1.0) if done else Color(0.612, 0.435, 0.294, 1.0))
	vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = a["desc"] if done else "Keep discovering more recipes..."
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color",
		Color(0.298, 0.169, 0.031, 0.608) if done else Color(0.612, 0.435, 0.294, 1.0))
	vbox.add_child(desc_lbl)

	return row

# ── Signals ───────────────────────────────────────────────────────────────────

func close() -> void:
	queue_free()

func _on_close_button_pressed() -> void:
	close()
	
func _on_button_pressed() -> void:
	close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		get_viewport().set_input_as_handled()
		close()
