extends Node3D

var info: Lobby.PlayerInfo

var paddle_cooldown := 0.0

@export var force_dir: Vector3
@export var flip_paddle: bool

func _ready():
	if info.is_ai() and multiplayer.is_server():
		paddle_cooldown = randf()
	if flip_paddle:
		$"Scene Root".rotation.y *= -1
		$"Scene Root".scale.x *= -1
		$"Scene Root".position.x *= -1

@rpc func fired():
	$Model.play_animation("punch")
	$Model.play_animation("idle")
	$AnimationPlayer.play("paddle")

@rpc("any_peer", "call_local") func fire():
	if info.addr.peer_id != multiplayer.get_remote_sender_id():
		return
	if get_parent().fire(self.position, force_dir) and paddle_cooldown == 0:
		get_parent().lobby.broadcast(fired)
		paddle_cooldown = 1 if not info.is_ai() else 2

func _server_process(delta: float):
	paddle_cooldown = max(0, paddle_cooldown - delta)

func _process(_delta: float):
	if not info.is_local():
		return
	if not info.is_ai():
		if Input.is_action_just_pressed("player%d_action1" % info.player_id):
			fire.rpc_id(1)
	else:
		var pos = get_parent().position
		var rot = get_parent().rotation_degrees
		
		if (rot.y > 20 and force_dir.x > 0) or (rot.y < -20 and force_dir.x < 0):
			return
		
		var rocks = []
		for rock in Utility.get_nodes_in_group(get_parent(), "rock"):
			if rock.position.z < pos.z + 10 and rock.position.z > pos.z and abs(rock.position.x - pos.x) < 6:
				rocks.append(rock)
		
		if len(rocks) == 0:
			fire.rpc_id(1)
			return
		
		for rock in rocks:
			if rock.position.x - pos.x >= -0.1 and force_dir.x < 0:
				fire.rpc_id(1)
				return
			elif rock.position.x - pos.x < -0.1 and force_dir.x > 0:
				fire.rpc_id(1)
				return
