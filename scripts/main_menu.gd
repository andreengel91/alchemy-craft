extends Control

func _on_start_button_pressed() -> void:
	TransitionManager.pixelate_to("res://scenes/main_game.tscn")



func _on_exit_button_pressed() -> void:
	get_tree().quit() # Replace with function body.
