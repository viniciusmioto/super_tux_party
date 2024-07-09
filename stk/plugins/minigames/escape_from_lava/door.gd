extends StaticBody3D

var can_be_opened = true

@rpc("authority", "call_local") func _client_destroy():
	$CollisionShape3D.set_deferred("disabled", true)
	$"WoodenDoor/AnimationPlayer".play("destroy")

func destroy():
	Lobby.get_lobby(self).broadcast(_client_destroy)
	_client_destroy()

@rpc("authority", "call_local") func _client_open():
	$CollisionShape3D.set_deferred("disabled", true)
	$"WoodenDoor/AnimationPlayer".play("open")

func open():
	if is_multiplayer_authority() and can_be_opened:
		Lobby.get_lobby(self).broadcast(_client_open)
		_client_open()
		can_be_opened = false

func _on_Area_body_entered(body):
	if body.is_in_group("players"):
		open()
