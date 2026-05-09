extends CanvasLayer

const DURATION := 5.0

@onready var _panel:     Panel = $Panel
@onready var _title_lbl: Label = $Panel/HBox/VBox/TitleLabel
@onready var _desc_lbl:  Label = $Panel/HBox/VBox/DescLabel

func show_achievement(title: String, desc: String) -> void:
	_title_lbl.text = title
	_desc_lbl.text  = desc
	layer = 120

	var vp_size := get_viewport().get_visible_rect().size
	_panel.position = Vector2(vp_size.x - 360.0, vp_size.y + 10.0)
	_panel.modulate.a = 1.0

	# Slide up from below-right
	var tw := create_tween()
	tw.tween_property(_panel, "position:y", vp_size.y - 100.0, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished

	await get_tree().create_timer(DURATION - 0.7).timeout

	# Fade out
	var tw2 := create_tween()
	tw2.tween_property(_panel, "modulate:a", 0.0, 0.7)
	await tw2.finished
	queue_free()
