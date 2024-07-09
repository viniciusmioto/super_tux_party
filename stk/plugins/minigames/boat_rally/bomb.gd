extends Node3D

func _ready():
	$Sprite3D.set_as_top_level(true)
	$Sprite3D.position.y = 0

func _process(delta):
	self.position.y -= 9.81 * delta
	if self.position.y <= 0:
		$Sprite3D.hide()
	else:
		$Sprite3D.material_override.set("albedo_color", Color(1, 1, 1, 1 - max(self.position.y, 0) / 20.0))
	
	if self.position.y < -5:
		queue_free()

@rpc func explode():
	$Mesh.hide()
	$Sprite3D.hide()
	$Particles.emitting = true
	get_parent().set_process(false)
	self.set_process(false)

func _on_Bomb_body_entered(body):
	if not multiplayer.is_server():
		return
	if body.is_in_group("player") and not body.is_hit:
		body.is_hit = true
		var lobby: Lobby = get_parent().get_parent().lobby
		lobby.broadcast(explode)
		get_parent().set_process(false)
		self.set_process(false)
		await get_tree().create_timer(2).timeout
		lobby.minigame_nolok_loose()
