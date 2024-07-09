extends Node3D

const SPEED = 2

func _ready():
	$AnimationPlayer.play(&"fly-start")
	$AnimationPlayer.queue(&"fly")

func _server_process(delta):
	var dir = Vector3(-self.position.x, 0, -self.position.z).normalized()
	self.rotation.y = atan2(dir.x, dir.z)
	self.position += dir * delta * SPEED
	get_parent().lobby.broadcast(position_updated.bind(position, rotation))

@rpc("unreliable") func position_updated(trans: Vector3, rot: Vector3):
	self.position = trans
	self.rotation = rot

@rpc func delete():
	queue_free()

func _on_area_3d_area_entered(area: Area3D):
	if not multiplayer.is_server():
		return
	if area.is_in_group(&"target"):
		get_parent().end_game()

func _on_area_3d_body_entered(body: Node3D):
	if not multiplayer.is_server():
		return
	if body.is_in_group(&"player"):
		get_parent().lobby.broadcast(delete)
		queue_free()
