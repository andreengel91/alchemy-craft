extends Node

const RECIPE_PATH := "res://data/recipes.json"

var _recipes: Array = []

func _ready() -> void:
	_load()

func _load() -> void:
	var file := FileAccess.open(RECIPE_PATH, FileAccess.READ)
	if not file:
		push_error("RecipeDatabase: cannot open " + RECIPE_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and parsed.has("recipes"):
		_recipes = parsed["recipes"]

func unique_result_count() -> int:
	var seen := {}
	for r in _recipes:
		seen[r["result"]] = true
	return seen.size()

func find_recipe(a: String, b: String) -> Dictionary:
	for r in _recipes:
		var ing: Array = r["ingredients"]
		if (ing[0] == a and ing[1] == b) or (ing[0] == b and ing[1] == a):
			return r
	return {}
