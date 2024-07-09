extends Node3D

const MAX_CONSECUTIVE_HURDLES := 1

var players_alive := 4
var players_finished := 0
var placement := [ null, null, null, null ]

var speedup_timeout := 10.0

var direction := 0.05
var time_to_direction_change := 1.0

var stop := false

var lobby: Lobby
@onready var players = Utility.get_nodes_in_group(self, "players")

func _enter_tree() -> void:
	lobby = Lobby.get_lobby(self)

func update_speed(delta: float):
	if abs(direction) < 1.0:
		direction += sign(direction) * delta * 0.2
		direction = clamp(direction, -1.0, 1.0)
	elif speedup_timeout == 0.0:
		direction += sign(direction) * delta * 0.05
		direction = clamp(direction, -8, 8)
	else:
		speedup_timeout -= delta
		if speedup_timeout <= 0.0:
			speedup_timeout = 0.0

@rpc func change_direction():
	direction = -direction

func _client_process(delta: float):
	if stop:
		return
	update_speed(delta)
	$conveyor_belt/AnimationPlayer.speed_scale = direction

func _server_process(delta: float):
	if stop:
		return
	update_speed(delta)
	time_to_direction_change -= delta
	if time_to_direction_change <= 0.0:
		direction = -direction
		lobby.broadcast(change_direction)
		time_to_direction_change += randf() * 5.0 + 1.0
	for player in players:
		if not player.dead and player.position.y < -10:
			player.dead = true
			player.hide()
			placement[players_alive - 1] = player.info.player_id
			players_alive -= 1
			if players_alive <= 1:
				stop = true
				lobby.broadcast(do_stop)
				get_tree().create_timer(1).timeout.connect(finished)

@rpc func do_stop():
	stop = true

func finished():
	for player in Utility.get_nodes_in_group(self, "players"):
		if not player.dead:
			placement[players_alive - 1] = player.info.player_id
			players_alive -= 1
	lobby.minigame_win_by_position(placement)
