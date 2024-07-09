@tool
extends Node3D

@export var force: float = 15
@export var hit_height: float = 0

var CANNON_BALL = preload("res://plugins/minigames/forest_run/Forest Arena/CannonBall.tscn")

var material := StandardMaterial3D.new()

func _process(_delta):
	if Engine.is_editor_hint():
		var mesh: ImmediateMesh = $Preview.mesh
		mesh.clear_surfaces()
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
		mesh.surface_set_color(Color.RED)
		var velocity = $Marker3D.position.normalized() * force
		var i = 0
		while true:
			var pos = ($"Scene Root6".transform * $"Scene Root6/ForestCannonBall".transform).origin + (i * 0.1) * (velocity + i * 0.05 * Vector3(0, -9.81, 0))
			mesh.surface_add_vertex(pos)
			if pos.y < hit_height - self.global_transform.origin.y:
				break
			i = i + 1
		mesh.surface_end()

func fire():
	$AnimationPlayer.queue("throw")
	await $AnimationPlayer.animation_finished
	
	var trans = $"Scene Root6/ForestCannonBall".global_transform
	var ball = CANNON_BALL.instantiate()
	add_child(ball)
	ball.set_as_top_level(true)
	ball.velocity = ($Marker3D.global_transform.origin - self.global_transform.origin).normalized() * force
	ball.transform = trans
	ball.hit_height = hit_height
