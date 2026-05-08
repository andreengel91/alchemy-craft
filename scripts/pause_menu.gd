extends Control

signal resumed
signal reset_requested
signal quit_requested

func _on_resume_pressed() -> void:
	emit_signal("resumed")

func _on_reset_pressed() -> void:
	emit_signal("reset_requested")

func _on_quit_pressed() -> void:
	emit_signal("quit_requested")
