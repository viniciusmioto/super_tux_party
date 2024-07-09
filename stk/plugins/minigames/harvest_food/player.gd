extends CharacterBody3D

const Minigame := preload("res://plugins/minigames/harvest_food/minigame.gd")
const Plant := preload("res://plugins/minigames/harvest_food/plant.gd")
const Pumpkin := preload("res://plugins/minigames/harvest_food/pumpkin.gd")
const PumpkinModel := preload("res://plugins/minigames/harvest_food/pumpkin_model.gd")

const MOVEMENT_SPEED: float = 3.

var info: Lobby.PlayerInfo

var score: float = 0

var movement := Vector3()
var plant: Plant

var ai_wait := 0.0

var is_walking = false
var is_carrying = false

@export var minigame: Minigame
@export var target: Area3D

@onready var mesh: PumpkinModel = $Pumpkin
@onready var area: Area3D = $Area3D
@onready var character: Character = $Model

var carrying: float = 0.0:
	set(x):
		carrying = x
		mesh.point_value = carrying
		
		# Make the ai wait a bit when taking a plant / storing a plant
		match info.ai_difficulty:
			Lobby.Difficulty.EASY:
				ai_wait = 1.0
			Lobby.Difficulty.NORMAL:
				ai_wait = 0.5
			Lobby.Difficulty.HARD:
				ai_wait = 0.0

@rpc func _on_carry(value: float, bonus: bool):
	carrying = value
	mesh.special = bonus

func _physics_process(delta: float):
	if not info.is_local():
		return
	var dir := Vector3()
	
	if not info.is_ai():
		if Input.is_action_just_pressed("player%d_action1" % info.player_id):
			action.rpc_id(1)
		
		var input := Input.get_vector("player%d_down" % info.player_id, \
				"player%d_up" % info.player_id, \
				"player%d_left" % info.player_id, \
				"player%d_right" % info.player_id)
		dir = Vector3(input.x, 0, input.y)
	else:
		if ai_wait > 0.0:
			ai_wait -= delta
		elif is_zero_approx(carrying):
			var nodes := minigame.plants
			var maxpoints := nodes[0]
			# find plant with maximum points (distance as tie-breaker)
			for node in nodes:
				var dist: float = (node.position - position).length_squared()
				var olddist: float = (maxpoints.position - position).length_squared()
				var mostly_equal := absf(node.point_value - maxpoints.point_value) < 0.1
				var nearer := dist < olddist
				if node.point_value > maxpoints.point_value or \
						(mostly_equal and nearer):
					maxpoints = node
			dir = maxpoints.position - position
			dir.y = 0
			if dir.length_squared() < 0.5:
				action.rpc_id(1)
				dir = Vector3()
			else:
				dir = dir.normalized()
		else:
			dir = target.position - position
			dir.y = 0
			if dir.length_squared() < 6.0:
				look_at(Vector3(target.position.x, position.y, target.position.z).rotated(Vector3.UP, randf_range(-PI/8, PI/8)), Vector3.UP, true)
				action.rpc_id(1)
				dir = Vector3()
			else:
				dir = dir.normalized()
	
	movement += Vector3(0, -9.81, 0) * delta
	velocity = movement + dir * MOVEMENT_SPEED
	move_and_slide()
	
	if dir.length_squared() > 0:
		rotation.y = atan2(dir.x, dir.z)
	
	update_animation(dir.length_squared() > 0)
	minigame.lobby.broadcast(position_updated.bind(position, rotation, is_walking))
	if is_on_floor():
		movement = Vector3()

func update_animation(walking: bool):
	if is_walking == walking and is_carrying == not is_zero_approx(carrying):
		return
	match [walking, not is_zero_approx(carrying)]:
		[true, true]:
			character.play_animation("run-carry")
		[true, false]:
			character.play_animation("run")
		[false, true]:
			character.play_animation("carry")
		[false, false]:
			character.play_animation("idle")
	is_walking = walking
	is_carrying = not is_zero_approx(carrying)

@rpc("any_peer", "call_local") func action():
	if multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	if is_zero_approx(carrying):
		var bodies: Array[Node3D] = area.get_overlapping_bodies()
		if len(bodies) > 0:
			var body: Pumpkin = bodies[0]
			minigame.lobby.broadcast(_on_carry.bind(body.point_value, body.special))
			_on_carry(body.point_value, body.special)
			minigame.lobby.broadcast(body.remove)
			bodies[0].queue_free()
		elif plant:
			minigame.lobby.broadcast(_on_carry.bind(plant.point_value, plant.special))
			plant.pickup(self)
	else:
		minigame.throw(carrying, mesh.special, mesh.global_position, global_transform.basis.z)
		minigame.lobby.broadcast(_on_carry.bind(0.0, false))
		_on_carry(0.0, false)

@rpc("unreliable_ordered", "any_peer") func position_updated(pos: Vector3, rot: Vector3, walking: bool):
	if multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	update_animation(walking)
	position = pos
	rotation = rot
