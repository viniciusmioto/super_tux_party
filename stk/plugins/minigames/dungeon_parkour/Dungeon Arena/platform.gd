@tool
extends Node3D

@export var moving: bool = false
@export var speed: int = 3

@export var path: Array[Vector3]

var index = 0

func _process(delta):
	if not moving:
		return
	
	var destination = path[index]
	
	var dir = destination - $Body.global_transform.origin
	if dir.length_squared() < 2*delta:
		index = (index + 1) % len(path)
	$Body.translate(dir.normalized() * delta * speed)


func _on_Area_body_entered(_body):
	self.moving = true
