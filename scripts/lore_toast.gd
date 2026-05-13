extends CanvasLayer

@onready var _panel:    Panel = $Panel
@onready var _name_lbl: Label = $Panel/VBox/MatName
@onready var _lore_lbl: Label = $Panel/VBox/LoreText

const FADE_IN  := 0.3
const STAY     := 4.0
const FADE_OUT := 0.5

func setup(mat_name: String, lore_text: String) -> void:
	_name_lbl.text = mat_name
	_lore_lbl.text = lore_text
	layer = 119

	var vp   := get_viewport().get_visible_rect().size
	var pw   := _panel.custom_minimum_size.x
	_panel.position = Vector2((vp.x - pw) * 0.5, vp.y - 60.0)
	_panel.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, FADE_IN)
	await tw.finished

	await get_tree().create_timer(STAY).timeout

	var tw2 := create_tween()
	tw2.tween_property(_panel, "modulate:a", 0.0, FADE_OUT)
	await tw2.finished
	queue_free()
