extends Control

@export var item: ItemData

@onready var icon = $TextureRect

func set_item(new_item: ItemData):
	item = new_item
	icon.texture = item.icon if item else null
