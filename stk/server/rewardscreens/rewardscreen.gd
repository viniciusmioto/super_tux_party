extends Node

@onready var lobby := Lobby.get_lobby(self)

var time := 0.0
var needed := []

func _ready():
	match lobby.minigame_summary.state.minigame_type:
		Lobby.MINIGAME_TYPES.GNU_SOLO, Lobby.MINIGAME_TYPES.NOLOK_SOLO:
			needed = [lobby.minigame_summary.state.minigame_teams[0][0]]
		Lobby.MINIGAME_TYPES.DUEL:
			needed = [
				lobby.minigame_summary.state.minigame_teams[0][0], 
				lobby.minigame_summary.state.minigame_teams[1][0]
				]
		Lobby.MINIGAME_TYPES.FREE_FOR_ALL, Lobby.MINIGAME_TYPES.GNU_COOP, \
		Lobby.MINIGAME_TYPES.NOLOK_COOP, Lobby.MINIGAME_TYPES.ONE_VS_THREE, \
		Lobby.MINIGAME_TYPES.TWO_VS_TWO:
			# All players
			needed = [1, 2, 3, 4]
		_:
			@warning_ignore("assert_always_false")
			assert(false, "Missing minigame type")

func _server_process(delta: float):
	time += delta
	for info in lobby.player_info:
		if info and info.is_ai() and time >= 5 + 0.1 * info.player_id:
			_accept_internal(info.player_id)
		if lobby.timeout >= 0 and time >= lobby.timeout:
			_accept_internal(info.player_id)

@rpc("any_peer") func accept(player_id: int):
	var info := lobby.get_player_by_id(player_id)
	if info.addr.peer_id != multiplayer.get_remote_sender_id():
		return
	_accept_internal(player_id)

# Some boilerplate rpc function definitions
# This is necessary, because since Godot4 these methods must be declared
# on the sending side as well
@rpc func client_accepted(_player_id: int): pass

func _accept_internal(player_id):
	if not player_id in needed:
		return
	needed.erase(player_id)
	# We don't want to continue before the cookie adding animation has finished
	# However we still want the players be able to press ready before that
	# Therefore we wait until there've been 6 seconds elapsed in the reward screen
	# In any case, we wait for at least half a second before we return to the board
	var delay := maxf(6 - time, 0) + 0.5
	if needed.is_empty():
		get_tree().create_timer(delay).timeout.connect(lobby._goto_scene_board)
	lobby.broadcast(client_accepted.bind(player_id))
