extends Node3D

@onready var lobby := Lobby.get_lobby(self)
const fireball := preload("res://plugins/minigames/dungeon_parkour/fireball.tscn")

func _ready():
	create_fireballs()

@rpc func create_fireball(pos: Vector3):
	var instance = fireball.instantiate()
	instance.position = pos
	add_child(instance)

func create_fireballs():
	if not multiplayer.is_server():
		return
	lobby.broadcast(create_fireball.bind($Fireball2.position))
	create_fireball($Fireball2.position)
	
	await get_tree().create_timer(0.25).timeout
	
	lobby.broadcast(create_fireball.bind($Fireball3.position))
	create_fireball($Fireball3.position)
	
	await get_tree().create_timer(0.25).timeout
	
	lobby.broadcast(create_fireball.bind($Fireball1.position))

func _client_process(_delta: float):
	$Remaining.text = "%.1f"%$Timer2.time_left

func _server_process(_delta: float):
	if $Player1.position.y < -5:
		lobby.minigame_nolok_loose()

func _on_Finish_body_entered(_body):
	if not multiplayer.is_server():
		return
	lobby.minigame_nolok_win()

func _on_Timer2_timeout():
	if not multiplayer.is_server():
		return
	lobby.minigame_nolok_loose()
