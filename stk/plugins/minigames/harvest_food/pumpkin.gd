extends RigidBody3D

const PumpkinModel := preload("res://plugins/minigames/harvest_food/pumpkin_model.gd")

@onready var mesh: PumpkinModel = $Pumpkin
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var special := false:
	set(x):
		special = x
		mesh.special = special

var point_value: float = 1.0:
	set(x):
		point_value = x
		mesh.point_value = point_value
		collision_shape.scale = Vector3.ONE * point_value
		collision_shape.position = Vector3(0, 0.5, 0) * point_value

func _ready():
	if not multiplayer.is_server():
		freeze = true

@rpc func remove():
	queue_free()

func _server_process(_delta):
	get_parent().lobby.broadcast(_position_updated.bind(position, rotation))

@rpc("unreliable_ordered") func _position_updated(pos: Vector3, rot: Vector3):
	position = pos
	rotation = rot
