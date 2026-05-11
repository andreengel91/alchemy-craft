extends Control

signal closed

const OVERLAP_DIST  := 52.0
const HINT_COOLDOWN := 300.0  # 5 minutes in seconds

@onready var _material_list:   VBoxContainer = %MaterialList
@onready var _craft_zone:      Control       = %CraftZone
@onready var _recipe_counter:  Label         = %RecipeCounter
@onready var _bestiary_btn:    Button        = %BestiaryButton
@onready var _hint_btn:        Button        = %HintButton
@onready var _hint_container:  Panel         = %HintContainer
@onready var _hint_lbl:        Label         = %HintLabel

var _db: Node = null
var _hint_visible_timer: float = 0.0
var _last_hint_display: String = ""
var _bestiary_panel: Control = null
var _lore: Dictionary = {}

const MATERIAL_ITEM_SCRIPT := preload("res://scripts/material_item.gd")
const _BESTIARY_SCENE      := preload("res://scenes/ui/bestiary_panel.tscn")
const _LORE_TOAST_SCENE    := preload("res://scenes/ui/lore_toast.tscn")

const MATERIAL_DESCRIPTORS := {
	"fire": "burning", "water": "flowing", "earth": "solid",
	"shadow": "hidden", "light": "radiant", "steam": "rising",
	"lava": "molten", "mud": "murky", "holy_water": "sacred",
	"crystal": "prismatic", "twilight": "liminal", "obsidian": "glassy",
	"clay": "unformed", "divinity": "transcendent", "gem": "precious",
	"void": "empty", "ancient_stone": "ancient", "abyss": "abyssal",
	"sacred_inferno": "righteous", "philosophers_stone": "legendary",
	"forbidden_relic": "sealed", "murk": "opaque", "hellfire": "infernal",
	"radiance": "brilliant", "cursed_soil": "tainted", "ocean": "vast",
	"sand": "drifting", "fog": "drifting", "cloud": "towering",
	"sun": "blazing", "plasma": "volatile", "lightning": "crackling",
	"storm": "raging", "ice": "frozen", "snow": "ephemeral",
}

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_db = Node.new()
	_db.set_script(preload("res://scripts/recipe_database.gd"))
	add_child(_db)
	_hint_container.visible = false
	_refresh_list()
	_update_recipe_counter()
	_update_hint_button()
	_load_lore()
	var book_icon := load("res://assets/ui/book.png") as Texture2D
	if book_icon:
		_bestiary_btn.icon = book_icon
	else:
		_bestiary_btn.text = "B"

func _process(delta: float) -> void:
	if _hint_container.visible:
		_hint_visible_timer -= delta
		if _hint_visible_timer <= 0.0:
			_fade_out_hint()
	_update_hint_button()

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
	btn.custom_minimum_size = Vector2(0, 30)
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
		_update_recipe_counter()
		_show_lore_toast(result["result"], result["result_name"])
		if _bestiary_panel != null and _bestiary_panel.visible:
			_bestiary_panel.refresh()

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

# ── Hint system ───────────────────────────────────────────────────────────────

func _on_hint_btn_pressed() -> void:
	var hint := _get_hint()
	_hint_lbl.text = hint
	_hint_container.modulate.a = 0.0
	_hint_container.visible = true
	_hint_visible_timer = 5.0
	var tw := create_tween()
	tw.tween_property(_hint_container, "modulate:a", 1.0, 0.3)
	GameState.hint_ready_at = Time.get_unix_time_from_system() + HINT_COOLDOWN

func _fade_out_hint() -> void:
	var tw := create_tween()
	tw.tween_property(_hint_container, "modulate:a", 0.0, 0.4)
	await tw.finished
	_hint_container.visible = false

func _update_hint_button() -> void:
	var now := Time.get_unix_time_from_system()
	var remaining := GameState.hint_ready_at - now
	if remaining <= 0.0:
		if _hint_btn.disabled:
			_hint_btn.disabled = false
			_hint_btn.text = "? Hint"
			_last_hint_display = ""
	else:
		_hint_btn.disabled = true
		var mins := int(remaining) / 60
		var secs := int(remaining) % 60
		var display := "%d:%02d" % [mins, secs]
		if display != _last_hint_display:
			_hint_btn.text = display
			_last_hint_display = display

func _get_hint() -> String:
	var all_recipes: Array = _db.get_all_recipes()
	var candidates: Array = []
	for r in all_recipes:
		# Skip already discovered results
		if r["result"] in GameState.discovered_recipes:
			continue
		# Only suggest recipes where both ingredients are already unlocked
		var ing_a: String = r["ingredients"][0]
		var ing_b: String = r["ingredients"][1]
		if ing_a in GameState.unlocked_materials and ing_b in GameState.unlocked_materials:
			candidates.append(r)
	if candidates.is_empty():
		return "You have mastered all alchemical secrets."
	var recipe: Dictionary = candidates[randi() % candidates.size()]
	var da: String = MATERIAL_DESCRIPTORS.get(recipe["ingredients"][0], recipe["ingredients"][0].replace("_", " "))
	var db_str: String = MATERIAL_DESCRIPTORS.get(recipe["ingredients"][1], recipe["ingredients"][1].replace("_", " "))
	return "Something %s meets something %s..." % [da, db_str]

# ── Lore toast ────────────────────────────────────────────────────────────────

func _load_lore() -> void:
	var file := FileAccess.open("res://data/lore.json", FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_lore = parsed

func _show_lore_toast(mat_id: String, mat_name: String) -> void:
	var lore_text: String = _lore.get(mat_id, "")
	if lore_text.is_empty():
		return
	var toast: Node = _LORE_TOAST_SCENE.instantiate()
	get_tree().root.add_child(toast)
	toast.call("setup", mat_name, lore_text)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _pretty(id: String) -> String:
	return id.replace("_", " ").capitalize()

func _on_close_button_pressed() -> void:
	emit_signal("closed")

func _on_clear_button_pressed() -> void:
	for child in _craft_zone.get_children():
		if child.get("material_id") != null:
			child.queue_free()
