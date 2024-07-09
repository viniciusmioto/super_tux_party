extends Node

func _ready() -> void:
	# Set up the network
	# TODO: load port and max_players from a config file?
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(ProjectSettings.get("server/port"),
			ProjectSettings.get("server/max_players"))
	multiplayer.multiplayer_peer = peer
	var server_multiplayer := MultiplayerAPI.create_default_interface()
	server_multiplayer.multiplayer_peer = peer

	# Start the actual server code
	load_server.call_deferred(server_multiplayer)

func load_server(server_multiplayer: MultiplayerAPI):
	var game := preload("res://server/game.tscn").instantiate()
	get_tree().set_multiplayer(server_multiplayer)
	get_tree().root.add_child(game)
	get_tree().set_multiplayer(server_multiplayer, game.get_node("Game").get_path())
	game.get_node("Game").init_server()
	queue_free()
