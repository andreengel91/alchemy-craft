extends Node

signal transition_finished

const _PIX_SHADER  := preload("res://shaders/pixelate_transition.gdshader")
const _DUST_SHADER := preload("res://shaders/magic_dust_dissolve.gdshader")

var _layer:     CanvasLayer
var _pix_rect:  ColorRect
var _dust_rect: ColorRect
var _particles: CPUParticles2D
var _pix_mat:   ShaderMaterial
var _dust_mat:  ShaderMaterial
var _busy := false

func _ready() -> void:
	_build_layer()

# ── Setup ─────────────────────────────────────────────────────────────────────

func _build_layer() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 128
	_layer.name = "TransitionLayer"
	add_child(_layer)

	_pix_mat = ShaderMaterial.new()
	_pix_mat.shader = _PIX_SHADER
	_pix_mat.set_shader_parameter("pixel_size", 0.5)

	_pix_rect = ColorRect.new()
	_pix_rect.name = "PixelateRect"
	_pix_rect.color = Color.WHITE
	_pix_rect.material = _pix_mat
	_pix_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_pix_rect.visible = false
	_layer.add_child(_pix_rect)

	_dust_mat = ShaderMaterial.new()
	_dust_mat.shader = _DUST_SHADER
	_dust_mat.set_shader_parameter("dissolve_amount", 0.0)

	_dust_rect = ColorRect.new()
	_dust_rect.name = "DustRect"
	_dust_rect.color = Color(0.04, 0.02, 0.08, 1.0)
	_dust_rect.material = _dust_mat
	_dust_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_dust_rect.visible = false
	_layer.add_child(_dust_rect)

	_particles = CPUParticles2D.new()
	_particles.name = "DustParticles"
	_setup_particles()
	_layer.add_child(_particles)

func _setup_particles() -> void:
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = 900.0
	_particles.direction = Vector2(0.0, -1.0)
	_particles.spread = 80.0
	_particles.gravity = Vector2(0.0, -25.0)
	_particles.initial_velocity_min = 20.0
	_particles.initial_velocity_max = 90.0
	_particles.scale_amount_min = 1.5
	_particles.scale_amount_max = 5.0

	var grad := Gradient.new()
	grad.colors  = PackedColorArray([Color(1.0, 0.82, 0.2, 1.0), Color(1.0, 0.45, 0.05, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	_particles.color_ramp = grad

	_particles.amount       = 200
	_particles.lifetime     = 1.5
	_particles.explosiveness = 0.5
	_particles.one_shot     = true
	_particles.emitting     = false

# ── Helpers ───────────────────────────────────────────────────────────────────

func _fit_to_viewport() -> void:
	var sz := get_viewport().get_visible_rect().size
	_pix_rect.size  = sz
	_pix_rect.position = Vector2.ZERO
	_dust_rect.size = sz
	_dust_rect.position = Vector2.ZERO
	_particles.position = sz * 0.5

func _set_pixel_size(val: float) -> void:
	_pix_mat.set_shader_parameter("pixel_size", val)

func _set_dissolve(val: float) -> void:
	_dust_mat.set_shader_parameter("dissolve_amount", val)

func _finish() -> void:
	_busy = false
	transition_finished.emit()

# ── Public API ────────────────────────────────────────────────────────────────

## Pixelates the screen out, swaps to scene_path, then de-pixelates in.
func pixelate_to(scene_path: String, duration: float = 1.6) -> void:
	if _busy:
		return
	_busy = true
	_fit_to_viewport()

	_pix_mat.set_shader_parameter("pixel_size", 1)
	_pix_rect.visible = true

	var t := create_tween()
	t.tween_method(_set_pixel_size, 1.0, 28.0, duration * 1)
	await t.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	var t2 := create_tween()
	t2.tween_method(_set_pixel_size, 28.0, 1.0, duration * 1)
	await t2.finished

	_pix_rect.visible = false
	_finish()

## Plays a magic-dust dissolve.
## scene_path="" → intro reveal only (call from the new scene's _ready).
## scene_path set → dissolve out, swap scene, dissolve in.
func magic_dust_to(scene_path: String, duration: float = 0.8) -> void:
	if _busy:
		return
	_busy = true
	_fit_to_viewport()

	if scene_path.is_empty():
		# Intro: start opaque, dissolve to reveal the scene beneath
		_dust_mat.set_shader_parameter("dissolve_amount", 0.0)
		_dust_rect.visible = true
		_particles.emitting = true

		var t := create_tween()
		t.tween_method(_set_dissolve, 0.0, 1.0, duration)
		await t.finished

		_dust_rect.visible = false
		_finish()
	else:
		# Dissolve out → scene change → dissolve in
		_dust_mat.set_shader_parameter("dissolve_amount", 1.0)
		_dust_rect.visible = true
		_particles.emitting = true

		var t := create_tween()
		t.tween_method(_set_dissolve, 1.0, 0.0, duration * 0.45)
		await t.finished

		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame
		await get_tree().process_frame

		_particles.emitting = true
		var t2 := create_tween()
		t2.tween_method(_set_dissolve, 0.0, 1.0, duration * 0.55)
		await t2.finished

		_dust_rect.visible = false
		_finish()
