extends Node3D

@onready var lobby := Lobby.get_lobby(self)

func fire_catapults():
	for i in range(1, 8):
		get_node("Catapult" + str(i)).fire()
		await get_tree().create_timer(0.1).timeout

func _client_process(_delta: float):
	$Remaining.text = str(snapped($Timer2.time_left, 0.1))

func _server_process(_delta: float):
	if $Player1.position.y < -5:
		lobby.minigame_gnu_loose()

func _on_Finish_body_entered(_body):
	if not multiplayer.is_server():
		return
	lobby.minigame_gnu_win()

func _on_Timer2_timeout():
	if not multiplayer.is_server():
		return
	lobby.minigame_gnu_loose()
