extends Camera3D
class_name SplitScreenCamera

func _process(_delta):
	$SubViewport/Camera3D.transform = global_transform
