extends Node3D

func _process(delta):
	self.position.z += 10 * delta

func _on_Area_body_entered(_body):
	if not multiplayer.is_server():
		return
	get_parent().lobby.minigame_nolok_loose()
