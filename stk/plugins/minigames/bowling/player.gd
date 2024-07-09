extends CharacterBody3D

@export var is_solo_player: bool = false

const GRAVITY = Vector3(0, -9.81, 0)
const SPEED = 4
const GROUND_BOX := AABB(Vector3(-2.5, 0, -5.5), Vector3(5, 4, 5))

var info: Lobby.PlayerInfo

enum STATE {
	IDLE,
	RUNNING,
	JUMP,
	STUNNED,
	DEAD
}

const FIRE_COOLDOWN_TIME := 0.85
var fire_cooldown := 0.5

@onready var MAX_DIR_CHANGE_TIME := 1.0 if is_solo_player else 2.0
@onready var MIN_DIR_CHANGE_TIME := 0.5 if is_solo_player else 1.0
const MIN_JUMP_TIME := 0.5
const MAX_JUMP_TIME := 1.5

var ai_running_dir := Vector3()
var ai_time_dir_change := 0.0
var ai_jump_timer := randf_range(MIN_JUMP_TIME, MAX_JUMP_TIME)

var stun_duration := 0.0

var state := STATE.IDLE: set = set_state

var movement := Vector3()

func _ready() -> void:
	set_multiplayer_authority(info.addr.peer_id)

func set_state(new_state: STATE):
	if state != new_state:
		state = new_state
		match new_state:
			STATE.IDLE, STATE.DEAD:
				$Model.play_animation("idle")
			STATE.RUNNING:
				$Model.play_animation("run")
			STATE.JUMP:
				$Model.play_animation("jump")

var fired_count := 0
@rpc("call_local") func fire():
	if fire_cooldown <= 0 and state != STATE.DEAD:
		var ball := preload("res://plugins/minigames/bowling/ball.tscn").instantiate()
		ball.position = position + Vector3(0, 0.25, -2)
		ball.name = "Ball" + str(fired_count)
		get_parent().add_child(ball)
		
		fire_cooldown = FIRE_COOLDOWN_TIME
		fired_count += 1

func solo_player(delta: float):
	if not info.is_ai():
		if Input.is_action_just_pressed("player%d_action2" % info.player_id):
			fire()
			get_parent().lobby.broadcast(fire)
		var right_strength := Input.get_action_strength("player%d_right" % info.player_id)
		var left_strength := Input.get_action_strength("player%d_left" % info.player_id)
		position.x += (right_strength - left_strength) * SPEED * delta
	else:
		fire()
		get_parent().lobby.broadcast(fire)
		if position.x <= -2.7 or position. x >= 2.7:
			ai_running_dir = -ai_running_dir
		ai_time_dir_change -= delta
		if ai_time_dir_change <= 0:
			if randi() % 2 == 0:
				ai_running_dir = Vector3(1, 0, 0)
			else:
				ai_running_dir = Vector3(-1, 0, 0)
			ai_time_dir_change = randf_range(MIN_DIR_CHANGE_TIME, MAX_DIR_CHANGE_TIME)
		position += ai_running_dir * SPEED * delta

	position.x = clamp(position.x, -2.75, 2.75)
	get_parent().lobby.broadcast(position_updated.bind(position, rotation, state))

func group_player(delta: float):
	var dir = Vector3()
	
	if not info.is_ai() and stun_duration == 0:
		dir.x = Input.get_action_strength("player%d_right" % info.player_id) - Input.get_action_strength("player%d_left" % info.player_id)
		dir.z = Input.get_action_strength("player%d_down" % info.player_id) - Input.get_action_strength("player%d_up" % info.player_id)
		
		if Input.is_action_pressed("player%d_action1" % info.player_id) and is_on_floor():
			state = STATE.JUMP
			movement = Vector3(0, 4, 0)
	elif stun_duration == 0:
		ai_time_dir_change -= delta
		if ai_time_dir_change <= 0:
			ai_running_dir = Vector3(1, 0, 0).rotated(Vector3(0, 1, 0), randf_range(-PI, PI))
			ai_time_dir_change = randf_range(MIN_DIR_CHANGE_TIME, MAX_DIR_CHANGE_TIME)
		
		var test_pos = position + ai_running_dir * delta
		if not GROUND_BOX.has_point(Vector3(test_pos.x, 0, test_pos.z)):
			ai_running_dir = -ai_running_dir
		
		if is_on_floor():
			ai_jump_timer -= delta
			if ai_jump_timer <= 0:
				ai_jump_timer = randf_range(MIN_JUMP_TIME, MAX_JUMP_TIME)
				state = STATE.JUMP
				movement = Vector3(0, 4, 0)
		
		dir = ai_running_dir
	
	if position.y < -2:
		knockout(Vector3())
		queue_free()
	
	if dir.length() > 0:
		state = STATE.RUNNING
		dir = dir.normalized()
		if not is_solo_player:
			rotation = Vector3(0, atan2(dir.x, dir.z), 0)
	elif stun_duration == 0:
		state = STATE.IDLE
	
	movement += GRAVITY * delta
	
	set_velocity(movement + dir * SPEED)
	set_up_direction(Vector3(0, 1, 0))
	move_and_slide()
	
	if is_on_floor():
		movement = Vector3()
		if state == STATE.JUMP:
			state = STATE.IDLE
	get_parent().lobby.broadcast(position_updated.bind(position, rotation, state))

@rpc("unreliable") func position_updated(pos: Vector3, rot: Vector3, nstate: STATE):
	if state == STATE.DEAD or not nstate in STATE.values() or nstate == STATE.DEAD:
		return
	if is_solo_player:
		pos.y = position.y
		pos.z = position.z
	position = pos
	rotation = rot
	state = nstate

func _physics_process(delta: float):
	if state == STATE.DEAD:
		movement += GRAVITY * delta
		
		# Knock out all players that are hit by a knocked out player
		var collision := move_and_collide(movement * delta)
		
		if collision != null and multiplayer.is_server():
			var object := collision.get_collider()
			if object.is_in_group("players") or object.is_in_group("box"):
				object.knockout(movement)
		return
	
	fire_cooldown -= delta
	stun_duration = max(stun_duration - delta, 0)
	if not info.is_local():
		return
	if is_solo_player:
		solo_player(delta)
	elif state != STATE.DEAD:
		group_player(delta)

func knockout(mov: Vector3):
	if state != STATE.DEAD:
		state = STATE.DEAD
		get_parent().knockout()
		movement = mov
		get_parent().lobby.broadcast(get_parent().die.bind(info.player_id, movement))

@rpc("any_peer") func _client_stun(duration: float):
	# Only allowed by the server
	if multiplayer.get_remote_sender_id() != 1:
		return
	$Model.play_animation("stun")
	state = STATE.STUNNED
	stun_duration = max(stun_duration, duration)

func stun(duration: float):
	get_parent().lobby.broadcast(_client_stun.bind(duration))
	stun_duration = max(stun_duration, duration)
