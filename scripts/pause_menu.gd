extends Control

signal resumed
signal reset_requested
signal quit_requested
signal achievements_requested

func _on_resume_pressed() -> void:
	emit_signal("resumed")

func _on_reset_pressed() -> void:
	emit_signal("reset_requested")

func _on_achievements_pressed() -> void:
	emit_signal("achievements_requested")

func _on_quit_button_pressed() -> void:
	emit_signal("quit_requested")
