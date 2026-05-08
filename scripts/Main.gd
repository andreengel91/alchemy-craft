extends Node2D

var crafting_ui_scene = preload("res://scenes/CraftingUI.tscn")
var crafting_ui = null

func _ready():
	$Cauldron.connect("clicked", _on_sprite_clicked)

func _on_sprite_clicked():
	if crafting_ui == null:
		crafting_ui = crafting_ui_scene.instantiate()
		$CraftingUI.add_child(crafting_ui)
	else:
		crafting_ui.visible = true
