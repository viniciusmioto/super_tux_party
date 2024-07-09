extends Node3D

const Minigame := preload("res://plugins/minigames/harvest_food/minigame.gd")
const Player := preload("res://plugins/minigames/harvest_food/player.gd")
const PumpkinModel := preload("res://plugins/minigames/harvest_food/pumpkin_model.gd")

const GROWTH_SPEED: float = 0.25
const MAX_POINTS: float = 1.0

@export var point_value: float = 0.0:
	set(x):
		point_value = x
		# Guard against invocation before _ready()
		if mesh:
			mesh.point_value = point_value
@export var active := false
var special := false:
	set(x):
		special = x
		# Guard against invocation before _ready()
		if mesh:
			mesh.special = special

@export var minigame: Minigame

@onready var mesh: PumpkinModel = $Pumpkin
@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D

func _ready():
	mesh.point_value = point_value
	mesh.special = special

func _process(delta: float) -> void:
	if active:
		point_value += delta * GROWTH_SPEED
	point_value = minf(point_value, MAX_POINTS)
	collision_shape.scale = Vector3.ONE * maxf(0.001, point_value)

func _on_area_3d_body_entered(body: Player) -> void:
	if multiplayer.is_server():
		body.plant = self

func _on_area_3d_body_exited(body: Player) -> void:
	if multiplayer.is_server() and body.plant == self:
		body.plant = null

func pickup(player: Player) -> void:
	player._on_carry(point_value, special)
	minigame.lobby.broadcast(reset)
	minigame.grow_new_plant()
	reset()

@rpc func activate(bonus: bool) -> void:
	active = true
	special = bonus

@rpc func reset() -> void:
	point_value = 0.0
	active = false
