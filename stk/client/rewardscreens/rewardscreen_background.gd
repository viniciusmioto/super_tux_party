extends Control

func _ready():
	if not multiplayer.is_server():
		$AudioStreamPlayer2.play()
		get_tree().create_timer(4).timeout.connect($AudioStreamPlayer.play)
