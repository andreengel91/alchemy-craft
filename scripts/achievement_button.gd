extends Control

const _OVERVIEW_SCENE := preload("res://scenes/ui/achievement_overview.tscn")

func _on_button_pressed() -> void:
	var overview: Control = _OVERVIEW_SCENE.instantiate()
	get_tree().root.add_child(overview)
