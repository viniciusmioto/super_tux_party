extends RigidBody3D

const JUMP_VELOCITY := 16.5
const BASE_SPEED := 4.0
const PLATFORM_SPEED := 3.0

@export var path: NodePath

enum State {
	IDLE,
	RUNNING,
	JUMP,
	STUNNED
}

var info: Lobby.PlayerInfo

# The current animation state
var player_state: int = State.IDLE

# The players movement speed
var speed := BASE_SPEED

# Regulates whether the player can jump
# Is reset when the ground is touched
var on_floor := true

var dead := false

var ai_direction := 0.0
var ai_direction_change := 0.0

var perm_rotation := Vector3()

func _ready():
	$Model.play_animation("idle")
	player_state = State.IDLE
	
	set_multiplayer_authority(info.addr.peer_id)

func face_direction(dir: Vector3, state: PhysicsDirectBodyState3D):
	if dir.length_squared() > 0.01:
		state.transform = state.transform.looking_at(self.position - dir, Vector3.UP)

func jump():
	if on_floor:
		if not multiplayer.is_server():
			$AudioStreamPlayer.play()
			$Model.play_animation("jump")
		linear_velocity.y = JUMP_VELOCITY
		on_floor = false
		player_state = State.JUMP
		return true
	return false

func process_ai(state: PhysicsDirectBodyState3D):
	ai_direction_change -= state.step
	if ai_direction_change <= 0.0:
		ai_direction = -sign(self.position.z)
		ai_direction_change += 0.5 + (randf() - 0.5) * 0.1
	if abs(position.z) > 1.0 and sign(position.z) == sign(ai_direction):
		ai_direction = 0.0
	var dir = Vector3()
	dir = Vector3(0, 0, ai_direction)
	var v =  speed * dir.normalized() + PLATFORM_SPEED * Vector3(0, 0, get_parent().direction)
	state.linear_velocity.x = v.x
	state.linear_velocity.z = v.z
	state.linear_velocity += dir * speed
	face_direction(dir, state)
	
	for hurdle in Utility.get_nodes_in_group(get_parent(), "hurdles"):
		if (hurdle.position - self.position).length_squared() <= 1.0:
			jump()

func process_player(state: PhysicsDirectBodyState3D):
	var dir = Vector3(0, 0, 0)
	dir.z += Input.get_action_strength("player{0}_up".format([info.player_id]))
	dir.z -= Input.get_action_strength("player{0}_down".format([info.player_id]))
	
	var v =  speed * dir.normalized()
	if on_floor:
		v += PLATFORM_SPEED * Vector3(0, 0, get_parent().direction)
	state.linear_velocity.x = v.x
	state.linear_velocity.z = v.z
	face_direction(dir, state)
	
	if Input.is_action_pressed("player{0}_action1".format([info.player_id])):
		jump()

	if player_state == State.IDLE and dir.length_squared() > 0.01:
		$Model.play_animation("run")
		player_state = State.RUNNING
	elif player_state == State.RUNNING and dir.length_squared() <= 0.01:
		$Model.play_animation("idle")
		player_state = State.IDLE

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_multiplayer_authority() or dead:
		return
	
	if info.is_ai():
		process_ai(state)
	else:
		process_player(state)

	if on_floor and player_state == State.JUMP:
		$Model.play_animation("idle")
		player_state = State.IDLE

	info.lobby.broadcast(update_state.bind(position, rotation, player_state))

@rpc("unreliable") func update_state(trans: Vector3, rot: Vector3, state: int):
	position = trans
	rotation = rot
	if player_state != state:
		match state:
			State.IDLE:
				$Model.play_animation("idle")
			State.RUNNING:
				$Model.play_animation("run")
			State.JUMP:
				$Model.play_animation("jump")
				if not multiplayer.is_server():
					$AudioStreamPlayer.play()
	player_state = state

func _on_Player_body_entered(body: Node) -> void:
	if body.is_in_group("ground"):
		on_floor = true

func _on_Player_body_exited(body: Node) -> void:
	if body.is_in_group("ground"):
		on_floor = false
