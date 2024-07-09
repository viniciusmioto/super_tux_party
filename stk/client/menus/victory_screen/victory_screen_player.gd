extends Node3D

var destination

func _process(delta):
	if destination:
		var dir = (destination - position).normalized()
		rotation.y = atan2(dir.x, dir.z)
		position += dir * delta * 4
		
		if (destination - position).length() < 2*delta:
			destination = null
			rotation = Vector3(0, 0, 0)
			$Model.play_animation("happy")
