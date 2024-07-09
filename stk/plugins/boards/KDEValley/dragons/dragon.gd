extends Node3D

func _ready():
	set_as_top_level(true)
	$AnimationPlayer.play("walk", -1, 0)
