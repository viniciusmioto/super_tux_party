extends Control

signal selected(player_id)

@onready var controller: Controller = get_parent().get_parent()

var current_player: int = -1

func select(player_id: int):
	controller.wait_for_duel_selection = true
	controller.start_timer_for_player(controller.lobby.get_player_by_id(player_id).addr)
	current_player = player_id
	var info = controller.lobby.get_player_by_id(current_player)
	_client_select.rpc_id(info.addr.peer_id, current_player)

@rpc("any_peer") func _client_selected(player_id: int):
	var info = controller.lobby.get_player_by_id(current_player)
	if multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	if player_id == current_player:
		controller.lobby.kick(info.addr.peer_id)
		return
	controller.wait_for_duel_selection = false
	controller.cancel_timer()
	selected.emit(player_id)

@rpc func _client_select(player_id: int):
	var players = []
	for player in controller.players:
		if player.info.player_id != player_id:
			players.append(player.info)

	var i := 1
	for info in players:
		var node = get_node("Player" + str(i))
		var character = info.character
		var texture = PluginSystem.character_loader.load_character_icon(character)
		node.texture_normal = texture

		node.focus_entered.connect(_on_focus_entered.bind(node))
		node.focus_exited.connect(_on_focus_exited.bind(node))
		node.mouse_entered.connect(_on_mouse_entered.bind(node))
		node.mouse_exited.connect(_on_mouse_exited.bind(node))
		node.pressed.connect(_on_duel_opponent_select.bind(info.player_id))
		i += 1

	$Player1.grab_focus()
	show()

func _on_duel_opponent_select(other_id: int) -> void:
	hide()
	_client_selected.rpc_id(1, other_id)

func _on_focus_entered(button) -> void:
	button.material.set_shader_parameter("enable_shader", true)

func _on_focus_exited(button) -> void:
	button.material.set_shader_parameter("enable_shader", false)

func _on_mouse_entered(button) -> void:
	button.material.set_shader_parameter("enable_shader", true)

func _on_mouse_exited(button) -> void:
	if not button.has_focus():
		button.material.set_shader_parameter("enable_shader", false)
