extends Control

signal closed

const OVERLAP_DIST   := 52.0
const POPUP_DURATION := 2.5

@onready var _material_list:  VBoxContainer = %MaterialList
@onready var _craft_zone:     Control       = %CraftZone
@onready var _popup:          Panel         = %DiscoveryPopup
@onready var _popup_label:    Label         = %PopupLabel
@onready var _popup_swatch:   ColorRect     = %PopupSwatch
@onready var _recipe_counter: Label         = %RecipeCounter
@onready var _bestiary_btn:   Button        = %BestiaryButton

var _db: Node = null
var _popup_timer: float = 0.0
var _bestiary_panel: Control = null

const MATERIAL_ITEM_SCRIPT := preload("res://scripts/material_item.gd")
const _BESTIARY_SCENE      := preload("res://scenes/ui/bestiary_panel.tscn")

func _ready() -> void:
	_db = Node.new()
	_db.set_script(preload("res://scripts/recipe_database.gd"))
	add_child(_db)
	_popup.visible = false
	_refresh_list()
	_update_recipe_counter()
	var book_icon := load("res://assets/ui/book.png") as Texture2D
	if book_icon:
		_bestiary_btn.icon = book_icon
	else:
		_bestiary_btn.text = "B"

func _process(delta: float) -> void:
	if _popup.visible:
		_popup_timer -= delta
		if _popup_timer <= 0.0:
			_popup.visible = false

# ── Materials list (left panel) ───────────────────────────────────────────────

func _refresh_list() -> void:
	for c in _material_list.get_children():
		c.queue_free()
	for id in GameState.unlocked_materials:
		_add_list_entry(id)

func _add_list_entry(id: String) -> void:
	var btn := Button.new()
	btn.text = _pretty(id)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 36)
	btn.pressed.connect(_spawn_in_zone.bind(id))
	_material_list.add_child(btn)

# ── Craft zone ────────────────────────────────────────────────────────────────

func _spawn_in_zone(id: String) -> void:
	var item := _make_item(id)
	var zone_size := _craft_zone.size if _craft_zone.size.x > 0 else Vector2(640, 480)
	item.position = zone_size * 0.5 - _ITEM_HALF + Vector2(randf_range(-60, 60), randf_range(-40, 40))
	_craft_zone.add_child(item)

func _make_item(id: String) -> Control:
	var root := VBoxContainer.new()
	root.set_script(MATERIAL_ITEM_SCRIPT)
	root.custom_minimum_size = Vector2(64, 0)
	root.add_theme_constant_override("separation", 6)

	var _mat_tex := load("res://assets/materials/" + id + ".png") as Texture2D
	var swatch: Control
	if _mat_tex:
		var tr := TextureRect.new()
		tr.texture = _mat_tex
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		swatch = tr
	else:
		var cr := ColorRect.new()
		cr.color = MATERIAL_ITEM_SCRIPT.id_to_color(id)
		swatch = cr
	swatch.name = "Swatch"
	swatch.custom_minimum_size = Vector2(64, 64)
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(swatch)

	var label := Label.new()
	label.name = "Label"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)

	root.setup(id, _pretty(id))
	root.drag_ended.connect(_on_item_drag_ended)
	return root

func _on_item_drag_ended(item: Control) -> void:
	_check_overlaps(item)

const _ITEM_HALF := Vector2(32, 40)  # half of 64x80

func _check_overlaps(item: Control) -> void:
	var item_center: Vector2 = item.position + _ITEM_HALF
	for child in _craft_zone.get_children():
		var other := child as Control
		# Skip non-material nodes (e.g. ZoneBg) and the item itself
		if other == null or other == item or other.get("material_id") == null:
			continue
		var other_center: Vector2 = other.position + _ITEM_HALF
		if item_center.distance_to(other_center) < OVERLAP_DIST:
			_try_combine(item, other)
			return

func _try_combine(a: Control, b: Control) -> void:
	var result: Dictionary = _db.find_recipe(a.material_id, b.material_id)
	if result.is_empty():
		return
	var mid_pos := (a.position + b.position) * 0.5
	a.queue_free()
	b.queue_free()
	var new_item := _make_item(result["result"])
	new_item.position = mid_pos
	_craft_zone.add_child(new_item)

	var is_new := GameState.add_material(result["result"])
	GameState.add_discovered_recipe(result["result"])
	if is_new:
		_add_list_entry(result["result"])
		_show_popup(result["result"], result["result_name"])
		_update_recipe_counter()

# ── Recipe counter ───────────────────────────────────────────────────────────

func _update_recipe_counter() -> void:
	var discovered := GameState.unlocked_materials.size() - GameState.BASE_MATERIALS.size()
	var total: int = _db.unique_result_count()
	_recipe_counter.text = str(discovered) + " / " + str(total) + " recipes discovered"

# ── Bestiary ──────────────────────────────────────────────────────────────────

func _on_bestiary_btn_pressed() -> void:
	if _bestiary_panel == null:
		_bestiary_panel = _BESTIARY_SCENE.instantiate()
		add_child(_bestiary_panel)
	_bestiary_panel.refresh()
	_bestiary_panel.visible = true

# ── Discovery popup ───────────────────────────────────────────────────────────

func _show_popup(id: String, display_name: String) -> void:
	_popup_label.text = "Discovered: " + display_name + "!"
	for child in _popup_swatch.get_children():
		child.queue_free()
	var _pop_tex := load("res://assets/materials/" + id + ".png") as Texture2D
	if _pop_tex:
		_popup_swatch.color = Color.TRANSPARENT
		var tr := TextureRect.new()
		tr.texture = _pop_tex
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_popup_swatch.add_child(tr)
	else:
		_popup_swatch.color = _swatch_color(id)
	_popup.visible = true
	_popup_timer = POPUP_DURATION
	var tween := create_tween()
	_popup.modulate.a = 0.0
	tween.tween_property(_popup, "modulate:a", 1.0, 0.3)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _pretty(id: String) -> String:
	return id.replace("_", " ").capitalize()

func _swatch_color(id: String) -> Color:
	return MATERIAL_ITEM_SCRIPT.id_to_color(id)

func _on_close_button_pressed() -> void:
	emit_signal("closed")

func _on_clear_button_pressed() -> void:
	for child in _craft_zone.get_children():
		if child.get("material_id") != null:
			child.queue_free()
