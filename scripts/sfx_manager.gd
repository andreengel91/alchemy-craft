extends Node

# Swap placeholder files by replacing the .wav files in assets/sfx/.
# To use a different format, update the three preload paths below.
const _SND_CRAFT       := preload("res://assets/sfx/craft_success.wav")
const _SND_BUBBLE      := preload("res://assets/sfx/cauldron_bubble.wav")
const _SND_PAGE        := preload("res://assets/sfx/page_turn.wav")
const _SND_ACHIEVEMENT := preload("res://assets/sfx/achievement.wav")
const _SND_TRANSITION  := preload("res://assets/sfx/transition.wav")
const _SND_CLICK       := preload("res://assets/sfx/click.wav")

const _BUBBLE_MIN := 30.0   # minimum seconds between ambient bubble sounds
const _BUBBLE_MAX := 60.0  # maximum seconds between ambient bubble sounds

var _player_craft:       AudioStreamPlayer
var _player_bubble:      AudioStreamPlayer
var _player_page:        AudioStreamPlayer
var _player_achievement: AudioStreamPlayer
var _player_transition:  AudioStreamPlayer
var _player_click:       AudioStreamPlayer
var _bubble_timer:       Timer

func _ready() -> void:
	_player_craft       = _make_player(_SND_CRAFT)
	_player_bubble      = _make_player(_SND_BUBBLE)
	_player_page        = _make_player(_SND_PAGE)
	_player_achievement = _make_player(_SND_ACHIEVEMENT)
	_player_transition  = _make_player(_SND_TRANSITION)
	_player_click       = _make_player(_SND_CLICK)
	_player_click.volume_db = linear_to_db(0.3)

	_bubble_timer = Timer.new()
	_bubble_timer.one_shot = true
	_bubble_timer.timeout.connect(_on_bubble_timeout)
	add_child(_bubble_timer)
	_bubble_timer.start(randf_range(_BUBBLE_MIN, _BUBBLE_MAX))

# ── Public API ────────────────────────────────────────────────────────────────

func play_craft_success() -> void:
	_player_craft.play()

func play_cauldron_bubble() -> void:
	_player_bubble.play()

func play_page_turn() -> void:
	_player_page.play()

func play_achievement() -> void:
	_player_achievement.play()

func play_transition() -> void:
	_player_transition.play()

func play_click() -> void:
	_player_click.play()

func suppress_next_click() -> void:
	_click_suppressed = true

# ── Internal ──────────────────────────────────────────────────────────────────

var _click_suppressed: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_deferred_play_click.call_deferred()

func _deferred_play_click() -> void:
	if _click_suppressed:
		_click_suppressed = false
		return
	play_click()

func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "SFX"
	add_child(p)
	return p

func _on_bubble_timeout() -> void:
	play_cauldron_bubble()
	_bubble_timer.start(randf_range(_BUBBLE_MIN, _BUBBLE_MAX))
