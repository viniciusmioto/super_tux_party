extends CharacterBody3D

const SPEED := 10.
const MAX_TIME := 4.

var time = 0

@rpc func die():
	queue_free()

@rpc("unreliable") func _position_update(pos: Vector3):
	self.position = pos

func _server_process(delta):
	time += delta
	
	var forward := Vector3(0, 0, -1)
	var collider := move_and_collide(forward * SPEED * delta)
	
	if time > MAX_TIME:
		get_parent().lobby.broadcast(die)
		queue_free()
		return
	
	if collider != null and collider.get_collider() != null:
		var object := collider.get_collider()
		if object.is_in_group(&"players") or object.is_in_group(&"box"):
			get_parent().lobby.broadcast(die)
			queue_free()
			object.knockout(Vector3(0, 3.5, -8))
	get_parent().lobby.broadcast(_position_update.bind(self.position))
