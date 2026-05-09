extends Node

signal achievement_unlocked(id: String, title: String, description: String)

const SAVE_PATH   := "user://achievements.json"
const RECIPE_PATH := "res://data/recipes.json"

const _POPUP_SCENE := preload("res://scenes/ui/achievement_popup.tscn")

# Built in _ready() — includes base 6 plus 20 per-material threshold achievements.
var ACHIEVEMENTS: Dictionary = {}

var unlocked: Array[String] = []

var _session_count: int = 0
var _recipes: Array = []
var _unique_result_count: int = 0

func _ready() -> void:
	_build_achievements()
	_load_recipes()
	_load_save()
	GameState.recipe_discovered.connect(_on_recipe_discovered)

# ── Setup ─────────────────────────────────────────────────────────────────────

func _build_achievements() -> void:
	ACHIEVEMENTS = {
		"first_spark":  {"title": "First Spark",   "desc": "Discovered your first recipe."},
		"apprentice":   {"title": "Apprentice",    "desc": "Discovered 10 recipes."},
		"alchemist":    {"title": "Alchemist",     "desc": "Discovered 50 recipes."},
		"grand_master": {"title": "Grand Master",  "desc": "Discovered every possible recipe."},
		"speed_brewer": {"title": "Speed Brewer",  "desc": "Discovered 5 recipes in one session."},
		"explorer":     {"title": "Explorer",      "desc": "Used every base element as an ingredient at least once."},
	}
	# 4 threshold achievements per base material (25 / 50 / 75 / 100 %)
	const RANKS := [
		["_25",       " Dabbler",  "25"],
		["_50",       " Student",  "50"],
		["_75",       " Scholar",  "75"],
		["_complete", " Master",  "100"],
	]
	for base in GameState.BASE_MATERIALS:
		var base_name: String = base.capitalize()
		for rank in RANKS:
			ACHIEVEMENTS[base + rank[0]] = {
				"title": base_name + rank[1],
				"desc":  "Discovered " + rank[2] + "% of " + base_name + " recipes.",
			}

func _load_recipes() -> void:
	var file := FileAccess.open(RECIPE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and parsed.has("recipes"):
		_recipes = parsed["recipes"]
	var seen := {}
	for r in _recipes:
		seen[r["result"]] = true
	_unique_result_count = seen.size()

# ── Checking ──────────────────────────────────────────────────────────────────

func _on_recipe_discovered(_result_id: String) -> void:
	_session_count += 1
	_check_all()

func _check_all() -> void:
	var count: int = GameState.discovered_recipes.size()

	# General achievements
	_try_unlock("first_spark",  count >= 1)
	_try_unlock("apprentice",   count >= 10)
	_try_unlock("alchemist",    count >= 50)
	_try_unlock("grand_master", _unique_result_count > 0 and count >= _unique_result_count)
	_try_unlock("speed_brewer", _session_count >= 5)
	_try_unlock("explorer",     _check_explorer())

	# Per-base-material thresholds
	for base in GameState.BASE_MATERIALS:
		var total: int = _ingredient_total(base)
		if total == 0:
			continue
		var found: int = _ingredient_found(base)
		var pct: float = float(found) / float(total)
		_try_unlock(base + "_25",       pct >= 0.25)
		_try_unlock(base + "_50",       pct >= 0.50)
		_try_unlock(base + "_75",       pct >= 0.75)
		_try_unlock(base + "_complete", pct >= 1.00)

func _check_explorer() -> bool:
	for base in GameState.BASE_MATERIALS:
		var used := false
		for r in _recipes:
			if base in r["ingredients"] and r["result"] in GameState.discovered_recipes:
				used = true
				break
		if not used:
			return false
	return not GameState.BASE_MATERIALS.is_empty()

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

# ── Unlocking ─────────────────────────────────────────────────────────────────

func _try_unlock(id: String, condition: bool) -> void:
	if not condition or id in unlocked:
		return
	if not ACHIEVEMENTS.has(id):
		return
	unlocked.append(id)
	_save()
	var a: Dictionary = ACHIEVEMENTS[id]
	achievement_unlocked.emit(id, a["title"], a["desc"])
	var popup: Node = _POPUP_SCENE.instantiate()
	get_tree().root.add_child(popup)
	popup.call("show_achievement", a["title"], a["desc"])

func reset() -> void:
	unlocked.clear()
	_session_count = 0
	_save()

# ── Persistence ───────────────────────────────────────────────────────────────

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and parsed.has("unlocked"):
		unlocked.assign(parsed["unlocked"])

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"unlocked": unlocked}))
		file.close()
