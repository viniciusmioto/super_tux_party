extends Node3D

func display_action(action):
	$SubViewport/ControlView2D.display_action(action)

func clear_display():
	$SubViewport/ControlView2D.clear_display()
