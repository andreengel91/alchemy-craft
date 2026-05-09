extends Node

signal recipe_discovered(result_id: String)

const SAVE_PATH := "user://alchemy_save.json"
const BASE_MATERIALS := ["fire", "water", "earth", "shadow", "light"]

var unlocked_materials: Array[String] = []
var discovered_recipes: Array[String] = []

# Stored as Unix timestamp — persists across CauldronWindow open/close
# but resets on game restart. Not saved to disk intentionally.
var hint_ready_at: float = 0.0

func _ready() -> void:
	load_game()
	if unlocked_materials.is_empty():
		unlocked_materials.assign(BASE_MATERIALS)

func add_material(id: String) -> bool:
	if id not in unlocked_materials:
		unlocked_materials.append(id)
		save_game()
		return true
	return false

func add_discovered_recipe(result_id: String) -> void:
	if result_id not in discovered_recipes:
		discovered_recipes.append(result_id)
		save_game()
		recipe_discovered.emit(result_id)

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"unlocked_materials": unlocked_materials,
			"discovered_recipes": discovered_recipes
		}))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	if parsed.has("unlocked_materials"):
		unlocked_materials.assign(parsed["unlocked_materials"])
	if parsed.has("discovered_recipes"):
		discovered_recipes.assign(parsed["discovered_recipes"])

func reset_save() -> void:
	unlocked_materials.assign(BASE_MATERIALS)
	discovered_recipes.clear()
	hint_ready_at = 0.0
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
