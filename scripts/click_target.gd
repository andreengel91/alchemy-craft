extends Area2D

signal clicked

func _ready():
	print("Cauldron ready")
	connect("input_event", _on_input_event)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("CLICK erkannt")
		emit_signal("clicked")
