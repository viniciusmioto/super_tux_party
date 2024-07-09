extends HBoxContainer

@export var player_id: int = 0: set = set_player_id

@onready var lobby := Lobby.get_lobby(self)

var rewardscreen: Node

func set_player_id(p: int):
	player_id = p
	var action_name = "player{num}_ok".format({"num": player_id})
	var input = InputMap.action_get_events(action_name)[0]
	$VBoxContainer.add_child(ControlHelper.ui_from_event(input))
	show()

func client_accepted():
	$VBoxContainer.queue_free()
	$Label.hide()
	$AudioStreamPlayer.play()

func _input(event):
	if event.is_action_pressed("player{0}_ok".format([player_id])):
		rewardscreen.accept.rpc_id(1, player_id)
