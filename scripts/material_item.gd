extends Control

# Emitted when the item is released after a drag.
signal drag_ended(item: Control)

const MATERIAL_COLORS := {
	"fire": Color(1.00,0.47,0.12), "water": Color(0.12,0.39,0.86),
	"earth": Color(0.55,0.35,0.17), "shadow": Color(0.22,0.00,0.29),
	"light": Color(1.00,1.00,0.67), "steam": Color(0.78,0.78,0.86),
	"lava": Color(0.86,0.24,0.04), "hellfire": Color(0.71,0.00,0.12),
	"radiance": Color(1.00,0.86,0.00), "mud": Color(0.39,0.27,0.12),
	"murk": Color(0.08,0.24,0.31), "holy_water": Color(0.39,0.86,1.00),
	"cursed_soil": Color(0.20,0.14,0.08), "crystal": Color(0.67,0.94,1.00),
	"twilight": Color(0.59,0.31,0.71), "obsidian": Color(0.16,0.16,0.20),
	"clay": Color(0.75,0.43,0.31), "divinity": Color(1.00,0.98,0.86),
	"gem": Color(0.20,0.78,0.39), "void": Color(0.04,0.02,0.08),
	"ancient_stone": Color(0.47,0.43,0.39), "abyss": Color(0.04,0.02,0.16),
	"sacred_inferno": Color(0.94,0.47,0.00),
	"philosophers_stone": Color(0.86,0.71,0.78),
	"forbidden_relic": Color(0.12,0.31,0.27),
}

static func id_to_color(id: String) -> Color:
	if MATERIAL_COLORS.has(id):
		return MATERIAL_COLORS[id]
	var h := float(id.hash() & 0x7FFFFFFF) / float(0x7FFFFFFF)
	var s := 0.55 + float((id + "s").hash() & 0xFF) / float(0xFF) * 0.30
	var v := 0.70 + float((id + "v").hash() & 0xFF) / float(0xFF) * 0.25
	return Color.from_hsv(h, s, v)

var material_id: String = ""
var material_name_text: String = ""
var is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func setup(id: String, mname: String) -> void:
	material_id = id
	material_name_text = mname
	custom_minimum_size = Vector2(64, 80)
	# Children are added by cauldron_window before setup() is called.
	var swatch := get_node_or_null("Swatch") as ColorRect
	var lbl := get_node_or_null("Label") as Label
	if swatch:
		swatch.color = id_to_color(id)
	if lbl:
		lbl.text = mname

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			_drag_offset = get_local_mouse_position()
			move_to_front()
			CursorManager.set_drag(true)
			SFXManager.suppress_next_click()
			get_viewport().set_input_as_handled()
		else:
			is_dragging = false
			emit_signal("drag_ended", self)
			CursorManager.set_drag(false)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and is_dragging:
		position += event.relative
		get_viewport().set_input_as_handled()
