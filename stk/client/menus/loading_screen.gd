extends Control

@onready var lobby = Lobby.get_lobby(self)

func _process(_delta):
	var progress := Global.get_loader_progress()
	
	$CenterContainer/VBoxContainer/ProgressBar.max_value = 100
	$CenterContainer/VBoxContainer/ProgressBar.value = progress * 100
