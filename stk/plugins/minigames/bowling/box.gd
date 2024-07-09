extends StaticBody3D

const GRAVITY := Vector3(0, -9.81, 0)
var movement := Vector3(0, -4, 0)

var is_falling := true

func _ready():
	$Sprite3D.set_as_top_level(true)
	$Sprite3D.position.y = 0.25

@rpc("unreliable") func _position_update(pos: Vector3, visibility: float):
	self.position = pos
	$Sprite3D.modulate.a = visibility

func _server_process(delta: float):
	movement += GRAVITY * delta
	
	var collision := move_and_collide(movement * delta)
	if is_falling:
		$Sprite3D.modulate.a = 1 - clamp((self.position.y - 0.5) / 5, 0, 0.8)
	
	if collision != null and is_falling and multiplayer.is_server():
		is_falling = false
		$Sprite3D.modulate.a = 0
		var object = collision.get_collider()
		if object.is_in_group(&"players"):
			object.stun(1)
			var knockback_dir = object.position - self.position
			if knockback_dir.length_squared() <= 1e-9:
				knockback_dir = Vector3(0, 0, -1)
			else:
				knockback_dir = knockback_dir.normalized()
			object.position -= knockback_dir * delta * 5
		elif object.is_in_group(&"box"):
			object.knockout(Vector3())
	get_parent().lobby.broadcast(_position_update.bind(self.position, $Sprite3D.modulate.a))

func knockout(_movement: Vector3):
	get_parent().lobby.broadcast(_client_knockout)
	queue_free()

@rpc func _client_knockout():
	$AnimationPlayer.play("destroy")
	$CollisionShape3D.disabled = true

func _on_AnimationPlayer_animation_finished(_anim):
	queue_free()
