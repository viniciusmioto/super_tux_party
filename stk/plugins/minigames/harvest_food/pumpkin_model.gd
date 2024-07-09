extends Node3D

const normal := preload("res://assets/models/food/OBJ/Orange.tres")
const gold := preload("res://assets/materials/gold.tres")

var special := false:
	set(x):
		special = x
		var mesh: MeshInstance3D = $Pumpkin_Cylinder_047
		mesh.set_surface_override_material(1, gold if special else normal)
var point_value: float = 0.0:
	set(x):
		point_value = x
		scale = Vector3.ONE * point_value
