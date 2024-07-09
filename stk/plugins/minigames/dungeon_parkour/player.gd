extends CharacterBody3D

const SPEED = 5
const JUMP_POWER = 8
const GRAVITY = 18

enum State {
	IDLE,
	RUN,
	JUMP
}

var info: Lobby.PlayerInfo

var movementSpeed := Vector2()
var verticalSpeed := 0.0
var state = State.IDLE

var ai_current_waypoint: Node3D = null
var ai_rand_start: float

func _ready():
	set_multiplayer_authority(info.addr.peer_id)
	$CameraTracker.set_as_top_level(true)
	
	if info.is_ai():
		ai_current_waypoint = $"../Ground/Waypoint"
		ai_rand_start = randf()

@rpc("unreliable") func position_updated(trans: Vector3, rot: Vector3, new_state):
	self.position = trans
	self.rotation = rot
	$CameraTracker.position.x = self.position.x
	$CameraTracker.position.z = self.position.z
	if state != new_state:
		state = new_state
		match state:
			State.IDLE:
				$Model.play_animation("idle")
			State.RUN:
				$Model.play_animation("run")
			State.JUMP:
				$Model.play_animation("jump")

func _physics_process(delta):
	if not info.is_local():
		return
	
	ai_rand_start -= delta
	if ai_rand_start > 0:
		return
	var jump = false
	
	if not info.is_ai():
		movementSpeed = Vector2(
			Input.get_action_strength("player%d_right" % info.player_id) - Input.get_action_strength("player%d_left" % info.player_id),
			Input.get_action_strength("player%d_down" % info.player_id) - Input.get_action_strength("player%d_up" % info.player_id)
		).normalized() * SPEED
		
		jump = Input.is_action_pressed("player%d_action1" % info.player_id)
	else:
		var dir: Vector3 = ai_current_waypoint.global_transform.origin - position
		dir.y = 0
		
		if dir.length() < randf() * 0.5:
			jump = true
			ai_current_waypoint = ai_current_waypoint.get_node(ai_current_waypoint.get_nodes()[0])
		
		if abs(dir.x) < 0.05:
			dir.x = 0
		if abs(dir.z) < 0.05:
			dir.z = 0
		
		dir = dir.normalized() * SPEED
		movementSpeed.x = dir.x
		movementSpeed.y = dir.z
	
	if (is_on_floor() and jump and not state == State.JUMP):
		verticalSpeed = JUMP_POWER
	elif is_on_floor() and verticalSpeed < 0:
		verticalSpeed = 0
	else:
		verticalSpeed -= GRAVITY * delta
	
	$Model.rotation.y = atan2(movementSpeed.x, movementSpeed.y)
	if is_on_floor():
		if (movementSpeed.x or movementSpeed.y) and not jump:
			if state != State.RUN:
				$Model.play_animation("run")
				state = State.RUN
		elif jump:
			$Model.play_animation("jump")
			state = State.JUMP
		elif state == State.RUN or state == State.JUMP:
			$Model.play_animation("idle")
			state = State.IDLE
	
	move_and_slide()
	velocity = Vector3(movementSpeed.x, verticalSpeed, movementSpeed.y) + get_platform_velocity() * delta
	get_parent().lobby.broadcast(position_updated.bind(position, rotation, state))
	
	$CameraTracker.position.x = position.x
	$CameraTracker.position.z = position.z
