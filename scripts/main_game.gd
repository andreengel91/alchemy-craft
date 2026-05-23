extends Node2D

@onready var _cauldron: TextureButton = $Cauldron
@onready var _cauldron_window_layer: CanvasLayer = $CauldronWindowLayer

var _window_scene   := preload("res://scenes/cauldron_window.tscn")
var _pause_scene    := preload("res://scenes/pause_menu.tscn")
var _window_instance: Control = null
var _pause_instance:  Control = null

func _ready() -> void:
	_cauldron.pressed.connect(_open_cauldron)
	# Wait for any active transition (pixelate_to from main_menu) to finish first
	if TransitionManager._busy:
		await TransitionManager.transition_finished

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("esc"):
		return
	get_viewport().set_input_as_handled()
	if _window_instance:
		_close_cauldron()
	elif _pause_instance:
		_close_pause()
	else:
		_open_pause()

# ── Cauldron window ───────────────────────────────────────────────────────────

func _open_cauldron() -> void:
	if _window_instance or _pause_instance:
		return
	_window_instance = _window_scene.instantiate()
	_window_instance.closed.connect(_close_cauldron)
	_cauldron_window_layer.add_child(_window_instance)
	SFXManager.play_page_turn()

func _close_cauldron() -> void:
	if _window_instance:
		_window_instance.queue_free()
		_window_instance = null

# ── Pause menu ────────────────────────────────────────────────────────────────

func _open_pause() -> void:
	_pause_instance = _pause_scene.instantiate()
	_pause_instance.resumed.connect(_close_pause)
	_pause_instance.reset_requested.connect(_on_reset)
	_pause_instance.quit_requested.connect(_on_quit)
	_pause_instance.achievements_requested.connect(_open_achievements_from_pause)
	_cauldron_window_layer.add_child(_pause_instance)
	SFXManager.play_page_turn()

func _open_achievements_from_pause() -> void:
	# Hide (not destroy) pause menu — game stays paused, only UI changes
	_pause_instance.visible = false
	var overview: Control = preload("res://scenes/ui/achievement_overview.tscn").instantiate()
	get_tree().root.add_child(overview)
	SFXManager.play_page_turn()
	# Re-show pause menu when achievements panel is closed
	overview.tree_exited.connect(func() -> void:
		if is_instance_valid(_pause_instance):
			_pause_instance.visible = true
	)

func _close_pause() -> void:
	if _pause_instance:
		_pause_instance.queue_free()
		_pause_instance = null

func _on_reset() -> void:
	_close_pause()
	GameState.reset_save()
	AchievementManager.reset()
	get_tree().reload_current_scene()

func _on_quit() -> void:
	_close_pause()
	TransitionManager.pixelate_to("res://scenes/main_menu.tscn")
