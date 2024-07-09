extends Node

var lobby := Lobby.get_lobby(self)

func position_beneath(node: Node3D, control: Control):
	var offset = Vector2(control.size.x / 2, -5)
	control.position = node.get_viewport().get_camera_3d().unproject_position(node.position) - offset

func position_above(node: Node3D, control: Control):
	var offset = Vector2(control.size.x / 2, -(control.size.y + 5))
	control.position = node.get_viewport().get_camera_3d().unproject_position(node.position + Vector3(0, 2, 0)) - offset

func load_character(player_id: int, parent: Node3D, animation: String = ""):
	var info = lobby.get_player_by_id(player_id)
	var model = PluginSystem.character_loader.load_character(info.character)
	model.name = "Model"
	parent.add_child(model)
	model.freeze_animation()
	if animation:
		get_tree().create_timer(3).timeout.connect(_start_animation.bind(model, animation))

func _start_animation(model: Node3D, animation: String):
	model.resume_animation()
	model.play_animation(animation)

var needed_oks = 0

func _enter_tree() -> void:
	lobby = Lobby.get_lobby(self)

func _ready():
	name = "RewardScreen"
	get_viewport().size_changed.connect(_update_viewport_size)
	_update_viewport_size()
	get_tree().create_timer(4).timeout.connect($UIUpdate.start)
	for node in Utility.get_nodes_in_group(self, &"continue_check"):
		node.rewardscreen = self

func _update_viewport_size():
	$SubViewportContainer/SubViewport.size = get_viewport().size
	
	for i in range(1, 5):
		var node = get_node_or_null("SubViewportContainer/SubViewport/Placement{0}".format([i]))
		if not node:
			continue
		position_beneath(node, node.get_node("VBoxContainer"))
		var winner_text = node.get_node_or_null("WinnerText")
		if winner_text:
			position_above(node, winner_text)

# Some boilerplate rpc function definitions
# This is necessary, because since Godot4 these methods must be declared
# on the sending side as well
@rpc("any_peer") func accept(_player_id: int): pass

@rpc func client_accepted(player_id: int):
	for node in Utility.get_nodes_in_group(self, "continue_check"):
		if node.player_id == player_id:
			node.client_accepted()
