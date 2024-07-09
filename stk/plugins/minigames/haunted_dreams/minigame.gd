extends Node3D

@onready var lobby := Lobby.get_lobby(self)

func end_game():
	$Control/Message.show()
	get_tree().paused = true
	await get_tree().create_timer(3).timeout
	get_tree().paused = false
	lobby.minigame_gnu_loose()

func _server_process(_delta):
	if $Control/Duration.time_left == 0:
		lobby.broadcast(game_ended)
		get_tree().paused = true
		await get_tree().create_timer(3).timeout
		get_tree().paused = false
		lobby.minigame_gnu_win()

func _client_process(_delta):
	$Control/Timer.text = str(snapped($Control/Duration.time_left, 0.1))

@rpc func game_ended():
	$Control/Timer.hide()
	$Control/Message.show()
	get_tree().paused = true

@rpc func spawn_ghost(pos: Vector3, ghostname: String):
	var ghost = preload("res://plugins/minigames/haunted_dreams/ghost.tscn").instantiate()
	ghost.position = pos
	ghost.name = ghostname
	add_child(ghost)

var num_ghost_spawned := 0
func _on_Timer_timeout():
	if not multiplayer.is_server():
		return
	if $Control/Duration.time_left > 5:
		var dir := randf() * 2 * PI
		var pos := Vector3(cos(dir) * 10, 1, sin(dir) * 10)

		num_ghost_spawned += 1
		var ghostname := "Ghost" + str(num_ghost_spawned)

		lobby.broadcast(spawn_ghost.bind(pos, ghostname))
		spawn_ghost(pos, ghostname)
