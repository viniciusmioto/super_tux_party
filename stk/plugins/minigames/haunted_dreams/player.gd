extends CharacterBody3D

const SPEED := 3

var info: Lobby.PlayerInfo

func _ready():
	set_multiplayer_authority(info.addr.peer_id)

func _process(_delta):
	if not info.is_local():
		return
	
	var dir: Vector3
	if not info.is_ai():
		dir.x = Input.get_action_strength("player%d_right" % info.player_id) - Input.get_action_strength("player%d_left" % info.player_id)
		dir.z = Input.get_action_strength("player%d_down" % info.player_id) - Input.get_action_strength("player%d_up" % info.player_id)
	else:
		var target
		var dist = INF
		for ghost in Utility.get_nodes_in_group(get_parent(), "ghost"):
			var ndist = (ghost.position - self.position).length_squared()
			if ghost.position.length_squared() < 25 and dist > ndist:
				target = ghost
				dist = ndist
		
		if target:
			$Navigation.target_position = target.position
			dir = ($Navigation.get_next_path_position() - self.position).normalized() * SPEED
			dir.y = 0
	
	var animation := "idle"
	if dir.length_squared() > 0:
		dir = dir.normalized() * SPEED
		rotation.y = atan2(dir.x, dir.z)
		animation = "run"
	
	$Model.play_animation(animation)
	set_velocity(dir + Vector3(0, -1, 0))
	move_and_slide()
	get_parent().lobby.broadcast(position_updated.bind(position, rotation, animation))

@rpc func position_updated(trans, rot, anim):
	self.position = trans
	self.rotation = rot
	$Model.play_animation(anim)
