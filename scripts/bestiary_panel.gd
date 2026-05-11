extends Control

const MATERIAL_ITEM_SCRIPT := preload("res://scripts/material_item.gd")
const RECIPE_PATH := "res://data/recipes.json"

@onready var _left_grid:   GridContainer = %LeftGrid
@onready var _right_grid:  GridContainer = %RightGrid
@onready var _empty_label: Label         = %EmptyLabel

var _recipes: Array = []
var _name_lookup: Dictionary = {}
var _lore: Dictionary = {}

func _ready() -> void:
	_load_data()

func _load_data() -> void:
	var file := FileAccess.open(RECIPE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary and parsed.has("recipes")):
		return
	_recipes = parsed["recipes"]
	for base in GameState.BASE_MATERIALS:
		_name_lookup[base] = base.replace("_", " ").capitalize()
	for r in _recipes:
		_name_lookup[r["result"]] = r["result_name"]
	var lore_file := FileAccess.open("res://data/lore.json", FileAccess.READ)
	if lore_file:
		var lore_parsed = JSON.parse_string(lore_file.get_as_text())
		lore_file.close()
		if lore_parsed is Dictionary:
			_lore = lore_parsed

# Called each time the panel opens so data stays current.
func refresh() -> void:
	_clear(_left_grid)
	_clear(_right_grid)

	var undiscovered_count := 0
	for mat_id in _collect_all_ids():
		if mat_id in GameState.unlocked_materials:
			_left_grid.add_child(_make_card(mat_id, true))
		else:
			_right_grid.add_child(_make_card(mat_id, false))
			undiscovered_count += 1

	_right_grid.visible  = undiscovered_count > 0
	_empty_label.visible = undiscovered_count == 0

func _clear(grid: GridContainer) -> void:
	while grid.get_child_count() > 0:
		grid.get_child(0).free()

# ── Data helpers ──────────────────────────────────────────────────────────────

func _collect_all_ids() -> Array:
	var seen: Dictionary = {}
	for base in GameState.BASE_MATERIALS:
		seen[base] = true
	for r in _recipes:
		for ing in r["ingredients"]:
			seen[ing] = true
		seen[r["result"]] = true
	var ids: Array = seen.keys()
	# Base materials first, everything else alphabetical.
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ab: bool = a in GameState.BASE_MATERIALS
		var bb: bool = b in GameState.BASE_MATERIALS
		if ab != bb:
			return ab
		return a < b
	)
	return ids

func _ingredient_total(mat_id: String) -> int:
	var n := 0
	for r in _recipes:
		if mat_id in r["ingredients"]:
			n += 1
	return n

func _ingredient_found(mat_id: String) -> int:
	var n := 0
	for r in _recipes:
		if mat_id in r["ingredients"] and r["result"] in GameState.discovered_recipes:
			n += 1
	return n

# ── Card builder ──────────────────────────────────────────────────────────────

func _make_card(mat_id: String, discovered: bool) -> Control:
	var total: int = _ingredient_total(mat_id)
	var found: int = _ingredient_found(mat_id) if discovered else 0
	var display_name: String = _name_lookup.get(mat_id, mat_id.replace("_", " ").capitalize())

	var card := Panel.new()
	card.custom_minimum_size = Vector2(88, 88)

	# Parchment-toned card background
	var sbox := StyleBoxFlat.new()
	sbox.bg_color     = Color(0.91, 0.83, 0.66) if discovered else Color(0.80, 0.71, 0.54)
	sbox.border_color = Color(0.62, 0.44, 0.22) if discovered else Color(0.52, 0.38, 0.20, 0.7)
	sbox.border_width_left   = 0
	sbox.border_width_top    = 0
	sbox.border_width_right  = 0
	sbox.border_width_bottom = 0
	sbox.corner_radius_top_left     = 5
	sbox.corner_radius_top_right    = 5
	sbox.corner_radius_bottom_right = 5
	sbox.corner_radius_bottom_left  = 5
	card.add_theme_stylebox_override("panel", sbox)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	card.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)

	# Swatch container — holds material icon + optional completion checkmark
	var swatch_wrap := Control.new()
	swatch_wrap.custom_minimum_size  = Vector2(28, 28)
	swatch_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(swatch_wrap)

	# Material colour swatch
	var _mat_tex := load("res://assets/materials/" + mat_id + ".png") as Texture2D if discovered else null
	var swatch: Control
	if _mat_tex:
		var tr := TextureRect.new()
		tr.texture     = _mat_tex
		tr.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		swatch = tr
	else:
		var cr := ColorRect.new()
		cr.color = MATERIAL_ITEM_SCRIPT.id_to_color(mat_id) if discovered \
				 else Color(0.42, 0.30, 0.16, 0.75)
		swatch = cr
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	swatch_wrap.add_child(swatch)

	# Name label — dark ink for discovered, faded for unknown
	var name_lbl := Label.new()
	name_lbl.text                 = display_name if discovered else "???"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 7)
	name_lbl.add_theme_color_override("font_color",
		Color(0.20, 0.11, 0.02) if discovered else Color(0.48, 0.36, 0.20, 0.8))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	# Recipe counter — only for materials that appear as ingredients
	if total > 0:
		var ctr := Label.new()
		ctr.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		ctr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ctr.add_theme_font_size_override("font_size", 7)
		if discovered:
			ctr.text = str(found) + "/" + str(total) + " recipes"
			var ratio := float(found) / float(total)
			# Faded brown → warm gold as completion increases
			ctr.add_theme_color_override("font_color",
				Color(0.42 + ratio * 0.30, 0.28 + ratio * 0.20, 0.04, 1.0))
		else:
			ctr.text = "? recipes"
			ctr.add_theme_color_override("font_color", Color(0.48, 0.36, 0.20, 0.6))
		vbox.add_child(ctr)

	# Full-card completion overlay — dark layer over icon + label, checkmark centered on top
	if discovered and total > 0 and found >= total:
		var dark := ColorRect.new()
		dark.color = Color(0, 0, 0, 0.0)
		dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(dark)
		var ck_tex := load("res://assets/ui/checkmark.png") as Texture2D
		if ck_tex:
			var ck := TextureRect.new()
			ck.texture      = ck_tex
			ck.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			ck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ck.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			dark.add_child(ck)

	return card

# ── Signals ───────────────────────────────────────────────────────────────────

func _on_close_button_pressed() -> void:
	visible = false

# ESC closes bestiary without propagating to CauldronWindow/main_game.
# Using _input() ensures this fires before main_game's _unhandled_input().
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("esc"):
		accept_event()
		visible = false
