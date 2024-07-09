extends Node

func init_server():
	multiplayer.peer_disconnected.connect(self._on_peer_disconnected)
	get_tree().node_added.connect(self._on_node_added)

func _process(delta: float) -> void:
	# Run the server main loop
	# Note: We cannot use self.propagate_call here because we need to check
	# whether the node to be called is currently disabled from processing
	Utility.propagate_process_call(self, "_server_process", [delta])

func _on_node_added(node: Node):
	if is_ancestor_of(node):
		# Hack to disable audio playback in the server scene tree
		# I don't know of a better way to do this :(
		if (node is AudioStreamPlayer) or (node is AudioStreamPlayer2D) or \
				(node is AudioStreamPlayer3D):
			node.stream = null
			node.queue_free()

# Some boilerplate rpc function definitions
# This is necessary, because since Godot4 these methods must be declared
# on the sending side as well
@rpc("authority")
func version_callback(_proto: int, _version_string: String): pass
@rpc("authority")
func lobby_creation_failed(): pass
@rpc("authority")
func lobby_created(_lobby_name: String): pass
@rpc("authority")
func lobby_join_failed(): pass
@rpc("authority")
func lobby_joined(): pass
@rpc("authority")
func public_lobbies_callback(_lobbies: Array): pass

@rpc("any_peer") func get_version():
	version_callback.rpc_id(multiplayer.get_remote_sender_id(), Global.PROTOCOL_VERSION, Global.VERSION_STRING)

@rpc("any_peer") func get_public_lobbies():
	var lobbies := []
	for child in get_children():
		if child.is_public():
			lobbies.append([child.name, child.current_board])
	public_lobbies_callback.rpc_id(multiplayer.get_remote_sender_id(), lobbies)

@rpc("any_peer") func server_create_lobby():
	var peer := multiplayer.get_remote_sender_id()
	var lobby_name: String
	# 5 attempts to create a random 6 letter lobby name
	# If all fail, then we have probably run out of lobby names
	# We then raise an error
	for _i in range(5):
		lobby_name = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(6))
		if not has_node(lobby_name):
			break
	if lobby_name.is_empty():
		lobby_creation_failed.rpc_id(peer)
		return
	var lobby: Lobby = preload("res://server/lobby.tscn").instantiate()
	lobby.name = lobby_name
	add_child(lobby)
	if not lobby.join(Lobby.PlayerAddress.new(peer, 0)):
		# It should not fail to join an empty lobby
		lobby.delete()
		lobby_creation_failed.rpc_id(peer)
		return
	lobby_created.rpc_id(peer, lobby_name)
	lobby.update_playerlist()
	lobby.send_settings(peer)
	lobby.send_board(peer)

@rpc("any_peer") func server_join_lobby(lobby_name: String):
	var peer = multiplayer.get_remote_sender_id()
	# Prevent tree traversal
	if "." in lobby_name or "/" in lobby_name:
		return false
	var lobby = get_node_or_null(lobby_name)
	if not lobby:
		lobby_join_failed.rpc_id(peer)
		return
	if not lobby.join(Lobby.PlayerAddress.new(peer, 0)):
		lobby_join_failed.rpc_id(peer)
		return
	lobby_joined.rpc_id(peer)
	lobby.update_playerlist()
	lobby.send_settings(peer)
	lobby.send_board(peer)

func _on_peer_disconnected(id: int):
	for child in get_children():
		child.leave(id)
