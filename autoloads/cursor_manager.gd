extends Node

enum CursorType { DEFAULT, HOVER, CLICK, DRAG, LOCKED }

const _CURSOR_PATHS: Dictionary = {
	CursorType.DEFAULT: "res://assets/ui/cursors/default.png",
	CursorType.HOVER:   "res://assets/ui/cursors/hover.png",
	CursorType.CLICK:   "res://assets/ui/cursors/click.png",
	CursorType.DRAG:    "res://assets/ui/cursors/drag.png",
	CursorType.LOCKED:  "res://assets/ui/cursors/locked.png",
}

const _CURSOR_HOTSPOTS: Dictionary = {
	CursorType.DEFAULT: Vector2.ZERO,
	CursorType.HOVER:   Vector2.ZERO,
	CursorType.CLICK:   Vector2.ZERO,
	CursorType.DRAG:    Vector2(8.0, 8.0),
	CursorType.LOCKED:  Vector2.ZERO,
}

var _textures: Dictionary = {}
var _hover_count: int = 0
var _is_dragging: bool = false

func _ready() -> void:
	_preload_cursors()
	_apply_cursor(CursorType.DEFAULT)
	get_tree().node_added.connect(_on_node_added)

func _preload_cursors() -> void:
	for type in _CURSOR_PATHS:
		var path: String = _CURSOR_PATHS[type]
		if ResourceLoader.exists(path):
			_textures[type] = load(path)
		else:
			push_warning("CursorManager: cursor texture missing: " + path)

# ── Auto-wiring (standard widget types only) ──────────────────────────────────

func _on_node_added(node: Node) -> void:
	if not node is Control:
		return
	var ctrl := node as Control
	if ctrl.mouse_entered.is_connected(_on_hover_enter):
		return
	# ONLY genuine interactive widget families.
	# Do NOT include generic Panels, Containers, or STOP-filter background nodes —
	# those cover the full screen and break the hover counter.
	if (ctrl is BaseButton   or   # Button, CheckBox, TextureButton, LinkButton …
		ctrl is LineEdit     or
		ctrl is TextEdit     or
		ctrl is HSlider      or
		ctrl is VSlider      or
		ctrl is ScrollBar    or   # VScrollBar / HScrollBar
		ctrl is SpinBox      or
		ctrl is OptionButton or
		ctrl is MenuButton):
		ctrl.mouse_entered.connect(_on_hover_enter)
		ctrl.mouse_exited.connect(_on_hover_exit)

# Explicit opt-in for custom interactive nodes (cauldron click area, material items …).
# Call this from the scene that owns the node.
func register_interactive(ctrl: Control) -> void:
	if not ctrl.mouse_entered.is_connected(_on_hover_enter):
		ctrl.mouse_entered.connect(_on_hover_enter)
	if not ctrl.mouse_exited.is_connected(_on_hover_exit):
		ctrl.mouse_exited.connect(_on_hover_exit)

# ── Cursor state ──────────────────────────────────────────────────────────────

func _on_hover_enter() -> void:
	_hover_count += 1
	_update_cursor()

func _on_hover_exit() -> void:
	_hover_count = max(0, _hover_count - 1)
	_update_cursor()

func set_drag(active: bool) -> void:
	_is_dragging = active
	if not active:
		# Reset counter after drag to avoid stale hover state if signals
		# misfired while the item was being dragged around the zone.
		_hover_count = 0
	_update_cursor()

# Direct one-off override (CLICK flash, LOCKED icon, etc.).
func set_cursor(type: CursorType) -> void:
	_apply_cursor(type)

func _update_cursor() -> void:
	if _is_dragging:
		_apply_cursor(CursorType.DRAG)
	elif _hover_count > 0:
		_apply_cursor(CursorType.HOVER)
	else:
		_apply_cursor(CursorType.DEFAULT)

func _apply_cursor(type: CursorType) -> void:
	var texture: Texture2D = _textures.get(type)
	var hotspot: Vector2 = _CURSOR_HOTSPOTS.get(type, Vector2.ZERO)
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, hotspot)
