extends Node

@onready var player := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(player)
	player.bus = "Music"
	player.stream = load("res://assets/audio/music/background_loop.mp3")
	player.volume_db = 0
	player.play()
