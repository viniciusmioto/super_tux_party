extends Lobby

signal player_left(player_id)
signal setting_changed(setting)

class BoardOverrides:
	var cake_cost := 30
	var max_turns := 10
	# Option to choose how players are awarded after completing a mini-game.
	var award: int = Lobby.AWARD_TYPE.LINEAR

const MINIGAME_REWARD_SCREEN = preload("res://server//rewardscreens/rewardscreen.tscn")

const MinigameQueue = preload("res://server/minigame_queue.gd")

var overrides: BoardOverrides = BoardOverrides.new()
var minigame_queue: MinigameQueue = MinigameQueue.new()

var started := false
var loaded_from_savegame := false
var num_ai := 0

var wait_before_scene_change := {}

var turn := 1
var player_turn := 1

# Stores where a trap is placed and what item and player created it.
var trap_states := []

# Time window for the action of a player
# This ensures that a player cannot block the game by going AFK
# If this time window is exhausted, the player will be kicked
var timeout :=  -1 if Global.is_local_multiplayer() else 30

var settings := {}

# TODO: support savegame loading in online multiplayer
var enable_savegames := Global.is_local_multiplayer()

func _init():
	if not Global.is_local_multiplayer():
		settings["main/public"] = Settings.new_bool("MENU_SETTINGS_PUBLIC", false)
	settings["main/enable_timeout"] = Settings.new_bool("MENU_SETTINGS_ENABLE_TIMEOUT", not Global.is_local_multiplayer())
	settings["main/timeout"] = Settings.new_range("MENU_SETTINGS_TIMEOUT", 30, 10, 65535)
	settings["main/cake_cost"] = Settings.new_range("MENU_SETTINGS_CAKE_COST", 30, 10, 65535)
	settings["main/turns"] = Settings.new_range("MENU_SETTINGS_TURNS", 10, 1, 65535)
	settings["main/award_type"] = Settings.new_options("MENU_SETTINGS_AWARD_TYPE", "MENU_SETTINGS_AWARD_LINEAR", ["MENU_SETTINGS_AWARD_LINEAR", "MENU_SETTINGS_AWARD_WINNER_TAKES_ALL"])
	setting_changed.connect(_on_setting_changed)
	current_board = PluginSystem.board_loader.get_loaded_boards()[0]

func _on_setting_changed(setting: Settings):
	match setting.name:
		# Negative timeout values disable timeouts
		# We use negative values to save timeout settings
		"MENU_SETTINGS_ENABLE_TIMEOUT":
			if setting.get_value():
				timeout = settings["main/timeout"].get_value()
			else:
				timeout = -1
		"MENU_SETTINGS_TIMEOUT":
			if settings["main/enable_timeout"].get_value():
				timeout = setting.get_value()
		"MENU_SETTINGS_CAKE_COST":
			overrides.cake_cost = setting.get_value()
		"MENU_SETTINGS_TURNS":
			overrides.max_turns = setting.get_value()
		"MENU_SETTINGS_AWARD_TYPE":
			match setting.get_value():
				"MENU_SETTINGS_AWARD_LINEAR":
					overrides.award = AWARD_TYPE.LINEAR
				"MENU_SETTINGS_AWARD_WINNER_TAKES_ALL":
					overrides.award = AWARD_TYPE.WINNER_ONLY

func next_ai_addr() -> PlayerAddress:
	var idx := num_ai
	num_ai += 1
	return PlayerAddress.new(1, idx)

func add_ai_players():
	var remaining: Array = PluginSystem.character_loader.get_loaded_characters()
	for player in player_info:
		remaining.erase(player.character)
	while len(player_info) < LOBBY_SIZE:
		var idx = randi() % len(remaining)
		var character = remaining[idx]
		remaining[idx] = remaining[-1]
		remaining[-1] = character
		remaining.pop_back()
		var botname := "{0} Bot".format([character])
		player_info.append(PlayerInfo.new(self, next_ai_addr(), botname, character))


# Some boilerplate rpc function definitions
# This is necessary, because since Godot4 these methods must be declared
# on the sending side as well
@rpc
func add_player_failed(): pass
@rpc
func update_settings(_settings: Array): pass
@rpc
func board_select(_board: String): pass
@rpc
func lobby_joined(_players: Array): pass
@rpc
func replace_by_ai(_id: int, _addr: Array): pass
@rpc
func return_to_board(): pass
@rpc
func load_minigame(): pass
@rpc
func playerstate_updated(_players: Array): pass
@rpc
func minigame_ended(_was_try: bool, _placement, _reward): pass
@rpc
func finish_loading(): pass
@rpc
func game_started(): pass
@rpc
func game_ended(): pass

@rpc("any_peer") func server_start():
	if is_lobby_owner(multiplayer.get_remote_sender_id()):
		# Check if the preconditions to start are met
		if current_board.is_empty():
			return
		for player in player_info:
			if player.name == "" or player.character == "":
				return

		started = true
		add_ai_players()
		update_playerlist()
		broadcast(game_started)
		_assign_player_ids()
		load_board()

@rpc("any_peer") func server_select_board(board: String):
	if not board in PluginSystem.board_loader.get_loaded_boards():
		return
	if loaded_from_savegame:
		return
	if is_lobby_owner(multiplayer.get_remote_sender_id()):
		current_board = board
		var cake_cost := 30
		var max_turns := 10
		var scene: SceneState = load(PluginSystem.board_loader.get_board_path(current_board)).get_state()
		for i in range(scene.get_node_count()):
			var instance: PackedScene = scene.get_node_instance(i)
			if instance:
				var groups: PackedStringArray = instance.get_state().get_node_groups(0)
				if "Controller" in groups:
					for prop in range(scene.get_node_property_count(i)):
						match scene.get_node_property_name(i, prop):
							"COOKIES_FOR_CAKE":
								cake_cost = int(scene.get_node_property_value(i, prop))
							"MAX_TURNS":
								max_turns = int(scene.get_node_property_value(i, prop))
		settings["main/cake_cost"].update_value(cake_cost)
		settings["main/turns"].update_value(max_turns)
		send_board()
		send_settings()

@rpc("any_peer") func server_select_character(idx: int, character: String):
	if not character in PluginSystem.character_loader.get_loaded_characters():
		return
	if loaded_from_savegame:
		return
	var target = PlayerAddress.new(multiplayer.get_remote_sender_id(), idx)
	var player = get_player_by_addr(target)
	if player:
		player.character = character
		update_playerlist()

@rpc("any_peer") func server_set_player_name(idx: int, playername: String):
	var target = PlayerAddress.new(multiplayer.get_remote_sender_id(), idx)
	var player = get_player_by_addr(target)
	if player:
		player.name = playername
		update_playerlist()

func end():
	started = false
	# Remove AIs
	# Peer ID 1 is the server. The only players controlled by the server are AI
	# TODO: only leave autofill AIs?
	leave(1)
	num_ai = 0
	playerstates.clear()
	player_turn = 1
	turn = 1
	trap_states.clear()
	cake_space = NodePath()
	_current_scene.queue_free()
	_current_scene = null
	broadcast(game_ended)

func is_public() -> bool:
	if not "main/public" in settings:
		return false
	return settings["main/public"].get_value()

@rpc("any_peer") func server_add_player(idx: int):
	var peer := multiplayer.get_remote_sender_id()
	if not join(PlayerAddress.new(peer, idx)):
		add_player_failed.rpc_id(peer)
		return
	update_playerlist()

@rpc("any_peer") func server_remove_player(idx: int):
	# Only available while in the lobby
	if started:
		return
	# Is this the last player from that id?
	var peer := multiplayer.get_remote_sender_id()
	var count := 0
	for player in player_info:
		if player.addr.peer_id == peer:
			count += 1
	# For a client to participate in a lobby, there must be at least one player registered
	# If the last player from that client tries to leave, we don't let them
	# They can only leave entirely by disconnecting from the lobby
	if count == 1:
		return
	var i := 0
	for player in player_info:
		if player.addr.peer_id == peer and player.addr.idx == idx:
			player_info.remove_at(i)
			update_playerlist()
			return
		i += 1

func join(addr: PlayerAddress) -> bool:
	# Game has already started?
	if started:
		return false
	# Lobby full?
	var player_count := len(player_info)
	if player_count == LOBBY_SIZE:
		return false
	# No duplicate players
	for player in player_info:
		if player.addr.eq(addr):
			return false
	# Prevent race condition with lobby deletion when last player leaves
	if is_queued_for_deletion():
		return false
	player_info.append(PlayerInfo.new(self, addr, "Player" + str(player_count + 1), ""))
	return true

@rpc("any_peer") func server_update_setting(id: String, value):
	if not is_lobby_owner(multiplayer.get_remote_sender_id()):
		return
	if change_setting(id, value):
		send_settings()

func change_setting(id: String, value) -> bool:
	if id in settings and settings[id].update_value(value):
		setting_changed.emit(settings[id])
		return true
	return false

func send_settings(peer := -1):
	# Send players the updated list
	var encoded := []
	for id in settings:
		encoded.append([id, settings[id].encode()])
	if peer == -1:
		broadcast(update_settings.bind(encoded))
	else:
		update_settings.rpc_id(peer, encoded)

func send_board(peer := -1):
	if peer == -1:
		broadcast(board_select.bind(current_board))
	else:
		board_select.rpc_id(peer, current_board)

func update_playerlist(peer := -1):
	# Send players the updated list
	var encoded := []
	for player in player_info:
		encoded.append(player.encode())
	if peer == -1:
		broadcast(lobby_joined.bind(encoded))
	else:
		lobby_joined.rpc_id(peer, encoded)

@rpc("any_peer") func server_refresh():
	var peer := multiplayer.get_remote_sender_id()
	if has_peer(peer):
		update_playerlist(peer)
		send_settings(peer)
		send_board(peer)

func leave(id: int):
	var keep := []
	var human_players := 0
	for player in player_info:
		if player.addr.peer_id != id:
			keep.append(player)
			if not player.is_ai():
				human_players += 1
		elif started:
			# Replace players leaving mid-game by AI
			# The PlayerInfo struct is referenced by the board and minigame code
			# Updating this will update other code as well
			player.addr = next_ai_addr()
			keep.append(player)
			broadcast(replace_by_ai.bind(player.player_id, player.addr.encode()))
			player_left.emit(player.player_id)
	player_info = keep
	update_playerlist()
	if human_players == 0:
		queue_free()

func kick(id: int, reason: String):
	print("Kicking Player {0} ({1})".format([id, reason]))
	multiplayer.multiplayer_peer.disconnect_peer(id)

func delete():
	queue_free()

# ----- Scene changing code ----- #

# Internal function for actually changing scene without saving any game state.
func _goto_scene(path: String) -> void:
	_interactive_load_scene(path, Callable())

# Goto a specific scene without saving player states.
func goto_scene(path: String) -> void:
	call_deferred("_goto_scene", path)

# Internal function for changing scene to a minigame while handling player objects.
func _goto_scene_minigame(path: String) -> void:
	_interactive_load_scene(path, _goto_scene_minigame_callback)

# Internal function for changing scene to a board while handling player objects.
func _goto_scene_board() -> void:
	if turn > overrides.max_turns:
		# The game has ended, prepare the lobby for another round
		end()
		return
	broadcast(return_to_board)
	_interactive_load_scene(PluginSystem.board_loader.get_board_path(current_board), _goto_scene_board_callback)

func _goto_scene_minigame_callback(scene: Node):
	var i := 1
	for team_id in minigame_state.minigame_teams.size():
		var team = minigame_state.minigame_teams[team_id]
		for player_id in team:
			var player = scene.get_node("Player" + str(i))
			_load_player(player, player_info[player_id - 1])

			i += 1

	# Remove unnecessary players.
	while i <= LOBBY_SIZE:
		var player = scene.get_node_or_null("Player" + str(i))
		if player:
			scene.remove_child(player)
			player.queue_free()
		i += 1

func _goto_scene_board_callback(scene: Node):
	for i in range(LOBBY_SIZE):
		var player = scene.get_node("Player" + str(i + 1))
		_load_player(player, player_info[i])

@rpc("any_peer") func _goto_minigame(is_try: bool):
	if not minigame_state:
		return
	# TODO: wait for all players to accept?
	if not is_lobby_owner(multiplayer.get_remote_sender_id()):
		return
	minigame_state.is_try = is_try
	broadcast(load_minigame)
	goto_minigame()

# Change scene to one of the mini-games.
func goto_minigame() -> void:
	# Current player nodes.
	var r_players = Utility.get_nodes_in_group(self, "players")

	player_turn = Utility.get_nodes_in_group(self, "Controller")[0].player_turn

	trap_states.clear()
	for trap in Utility.get_nodes_in_group(self, "trap"):
		var state := {
			node = get_path_to(trap),
			item = trap.trap,
			player = get_path_to(trap.trap_player)
		}

		trap_states.push_back(state)

	# Save player states in the array 'players'.
	for i in r_players.size():
		playerstates[i].cookies = r_players[i].cookies
		playerstates[i].cakes = r_players[i].cakes
		playerstates[i].space = get_path_to(r_players[i].space)

		playerstates[i].roll_modifiers = r_players[i].roll_modifiers

		playerstates[i].items = duplicate_items(r_players[i].items)

	var encoded := []
	for state in playerstates:
		encoded.append(state.encode())
	broadcast(playerstate_updated.bind(encoded))
	call_deferred("_goto_scene_minigame", minigame_state.minigame_config.scene_path)

func duplicate_items(items: Array) -> Array:
	var list := []
	for item in items:
		list.append(item.serialize())

	return list

func deduplicate_items(items: Array) -> Array:
	var list := []
	for item in items:
		var deserialized := Item.deserialize(item)
		assert(deserialized, "Failed to load item")
		list.append(deserialized)

	return list

func get_ffa_reward(pos: int):
	assert(1 <= pos and pos <= 4, "Invalid position for FFA reward")
	match overrides.award:
		AWARD_TYPE.LINEAR:
			return 20 - pos * 5
		AWARD_TYPE.WINNER_ONLY:
			if pos == 1:
				return 10
			else:
				return 0

# Go back to board from mini-game, placement is an array with the players' ids.
func _goto_board(placement) -> void:
	# Only award if the players were not trying the minigame out
	if minigame_state.is_try:
		_goto_scene_board.call_deferred()
		broadcast(minigame_ended.bind(true, null, null))
		return

	var minigame_type = minigame_state.minigame_type
	var minigame_teams= minigame_state.minigame_teams

	minigame_summary = MinigameSummary.new()
	minigame_summary.state = minigame_state
	minigame_summary.placement = placement
	minigame_state = null

	match minigame_type:
		MINIGAME_TYPES.FREE_FOR_ALL:
			var place = 1
			minigame_summary.reward = []
			for position in placement:
				for player_id in position:
					minigame_summary.reward.append(get_ffa_reward(place))
					playerstates[player_id - 1].cookies += get_ffa_reward(place)
				place += len(position)
			_goto_scene_instant.call_deferred(MINIGAME_REWARD_SCREEN)
		MINIGAME_TYPES.TWO_VS_TWO:
			if placement != -1:
				minigame_summary.reward = [10, 10, 0, 0]
				for player_id in minigame_teams[placement]:
					playerstates[player_id - 1].cookies += 10
			else:
				minigame_summary.reward = [0, 0, 0, 0]
			_goto_scene_instant.call_deferred(MINIGAME_REWARD_SCREEN)
		MINIGAME_TYPES.ONE_VS_THREE:
			if placement == 1: # Solo player won
				minigame_summary.reward = [0, 0, 0, 10]
			elif placement == 0:
				minigame_summary.reward = [5, 5, 5, 0]
			else:
				minigame_summary.reward = [0, 0, 0, 0]

			for i in range(len(minigame_teams[0])):
				playerstates[minigame_teams[0][i] - 1].cookies += minigame_summary.reward[i]
			playerstates[minigame_teams[1][0] - 1].cookies += minigame_summary.reward[3]

			_goto_scene_instant.call_deferred(MINIGAME_REWARD_SCREEN)
		MINIGAME_TYPES.DUEL:
			if len(placement) == 2:
				var winning_player = playerstates[placement[0][0] - 1]
				var losing_player = playerstates[placement[1][0] - 1]
				match minigame_reward.duel_reward:
					MINIGAME_DUEL_REWARDS.TEN_COOKIES:
						var cookies := int(min(losing_player.cookies, 10))
						winning_player.cookies += cookies
						losing_player.cookies -= cookies
						minigame_summary.reward = cookies
					MINIGAME_DUEL_REWARDS.ONE_CAKE:
						var cakes := int(min(losing_player.cakes, 1))
						winning_player.cakes += cakes
						losing_player.cakes -= cakes
						minigame_summary.reward = cakes
			else:
				# No cookies were transferred between players
				minigame_summary.reward = 0

			_goto_scene_instant.call_deferred(MINIGAME_REWARD_SCREEN)
		MINIGAME_TYPES.NOLOK_SOLO:
			if not placement:
				var player = playerstates[minigame_teams[0][0] - 1]
				minigame_summary.reward = min(player.cakes, 1)
				player.cakes -= minigame_summary.reward
			else:
				minigame_summary.reward = 0

			_goto_scene_instant.call_deferred(MINIGAME_REWARD_SCREEN)
		MINIGAME_TYPES.NOLOK_COOP:
			minigame_summary.reward = [0, 0, 0, 0]
			if not placement:
				for i in range(len(playerstates)):
					minigame_summary.reward[i] = min(playerstates[i].cookies, 10)
					playerstates[i].cookies -= minigame_summary.reward[i]
			_goto_scene_instant.call_deferred(MINIGAME_REWARD_SCREEN)
		MINIGAME_TYPES.GNU_SOLO:
			minigame_summary.reward = minigame_reward.gnu_solo_item_reward.serialize()
			_goto_scene_instant.call_deferred(MINIGAME_REWARD_SCREEN)
		MINIGAME_TYPES.GNU_COOP:
			if placement == true:
				minigame_summary.reward = [10, 10, 10, 10]
			elif placement == false:
				minigame_summary.reward = [0, 0, 0, 0]
			else:
				minigame_summary.reward = placement
			for i in range(len(playerstates)):
				playerstates[i].cookies += minigame_summary.reward[i]

			_goto_scene_instant.call_deferred(MINIGAME_REWARD_SCREEN)
	var encoded := []
	for state in playerstates:
		encoded.append(state.encode())
	broadcast(playerstate_updated.bind(encoded))
	broadcast(minigame_ended.bind(false, placement, minigame_summary.reward))

func minigame_win_by_points(points: Array) -> void:
	var players := []
	var p := []

	# Sort into the array players while grouping players with the same amount
	# of points together.
	for i in points.size():
		var insert_index: int = p.bsearch(points[i])
		# Does the current entry differ (if it's not out of range).
		# If yes we need to insert a new entry.
		if insert_index == p.size() or p[insert_index] != points[i]:
			p.insert(insert_index, points[i])
			if minigame_state.minigame_type == MINIGAME_TYPES.FREE_FOR_ALL:
				players.insert(insert_index, [minigame_state.minigame_teams[0][i]])
			else:
				players.insert(insert_index, [minigame_state.minigame_teams[i][0]])
		else:
			if minigame_state.minigame_type == MINIGAME_TYPES.FREE_FOR_ALL:
				players[insert_index].append(minigame_state.minigame_teams[0][i])
			else:
				players[insert_index].append(minigame_state.minigame_teams[i][0])

	# We need to sort from high to low.
	players.reverse()
	_goto_board(players)

func minigame_win_by_position(players: Array) -> void:
	var placement := []

	# We're expecting an array with multiple possible players per placement in
	# _goto_board.
	for p in players:
		placement.append([p])

	_goto_board(placement)

func minigame_duel_draw() -> void:
	_goto_board([[minigame_state.minigame_teams[0][0], minigame_state.minigame_teams[1][0]]])

func minigame_team_win(team) -> void:
	_goto_board(team)

func minigame_team_win_by_points(points: Array) -> void:
	if points[0] == points[1]:
		_goto_board(-1)
	elif points[0] > points[1]:
		_goto_board(0)
	else:
		_goto_board(1)

func minigame_team_win_by_player(player) -> void:
	for i in minigame_state.minigame_teams.size():
		if minigame_state.minigame_teams[i].has(player):
			_goto_board(i)

			return

func minigame_team_draw() -> void:
	_goto_board(-1)

func minigame_1v3_draw() -> void:
	_goto_board(-1)

func minigame_1v3_win_team_players() -> void:
	_goto_board(0)

func minigame_1v3_win_solo_player() -> void:
	_goto_board(1)

func minigame_nolok_win() -> void:
	_goto_board(true)

func minigame_nolok_loose() -> void:
	_goto_board(false)

func minigame_gnu_win() -> void:
	_goto_board(true)

func minigame_gnu_loose() -> void:
	_goto_board(false)

func load_board_state(controller: Node3D) -> void:
	controller.COOKIES_FOR_CAKE = overrides.cake_cost
	controller.MAX_TURNS = overrides.max_turns

	if cake_space:
		var cake_node: Node3D = controller.get_node(cake_space)
		cake_node.cake = true

	controller.player_turn = player_turn

	# Replace traps.
	for trap in trap_states:
		var node = get_node(trap.node)
		node.trap = trap.item
		node.trap_player = get_node(trap.player)

	# Current player nodes.
	var r_players: Array = Utility.get_nodes_in_group(self, "players")

	# Load player states from the array 'players'.
	for i in range(r_players.size()):
		r_players[i].cookies = playerstates[i].cookies
		r_players[i].cakes = playerstates[i].cakes
		if playerstates[i].space:
			r_players[i].space = get_node(playerstates[i].space)
		r_players[i].roll_modifiers = playerstates[i].roll_modifiers

		r_players[i].items = deduplicate_items(playerstates[i].items)

func load_board() -> void:
	if not loaded_from_savegame:
		for i in range(LOBBY_SIZE):
			playerstates.append(PlayerState.new(player_info[i]))
			if player_info[i].is_ai():
				# TODO: adjust difficulty per AI?
				player_info[i].ai_difficulty = Difficulty.NORMAL
	var encoded := []
	for state in playerstates:
		encoded.append(state.encode())
	broadcast(playerstate_updated.bind(encoded))
	_goto_scene_board()

func _interactive_load_scene(path: String, callable: Callable):
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = null
	loading_finished.connect(func(): self.client_ready.rpc_id(1), CONNECT_ONE_SHOT)
	_load_interactive(path, _scene_loaded.bind(callable))
	wait_before_scene_change = {}
	for player in player_info:
		wait_before_scene_change[player.addr.peer_id] = true

@rpc("any_peer", "call_local") func client_ready():
	if wait_before_scene_change.is_empty():
		return
	var id := multiplayer.get_remote_sender_id()
	wait_before_scene_change.erase(id)
	
	if wait_before_scene_change.is_empty():
		broadcast(finish_loading)
		_change_scene_to_file()

func _scene_loaded(s: PackedScene, callable: Callable):
	_loaded_scene = s.instantiate()
	callable.call(_loaded_scene)

# ----- Savegame code ----- #

@rpc func save_game_callback(_data: Dictionary, _err: String): pass

@rpc func load_savegame(data: Dictionary) -> void:
	if not enable_savegames or not is_lobby_owner(multiplayer.get_remote_sender_id()):
		return

	var savegame := SaveGameLoader.SaveGame.from_data(data)
	current_board = savegame.board_state.board_path
	player_info = []
	playerstates = []
	for i in len(savegame.players):
		# TODO: what should we do here to add support for multiplayer savegames?
		var addr := PlayerAddress.new(multiplayer.get_network_connected_peers()[0], i)
		if savegame.players[i].is_ai:
			addr = next_ai_addr()
		var player_name: String = savegame.players[i].player_name
		var character: String = savegame.players[i].character
		var info := PlayerInfo.new(self, addr, player_name, character)
		info.player_id = i + 1
		info.ai_difficulty = savegame.players[i].ai_difficulty
		
		var playerstate := PlayerState.new(info)
		playerstate.space = savegame.players[i].space
		playerstate.cookies = savegame.players[i].cookies
		playerstate.cakes = savegame.players[i].cakes
		playerstate.items = savegame.players[i].items
		playerstate.roll_modifiers = savegame.players[i].roll_modifiers
		player_info.append(info)
		playerstates.append(playerstate)

	cake_space = savegame.board_state.cake_space
	if savegame.minigame_state.minigame_config:
		minigame_state = MinigameState.new()
		minigame_state.minigame_config = MinigameLoader.parse_file(savegame.minigame_state.minigame_config)
		minigame_state.minigame_type = savegame.minigame_state.minigame_type
		minigame_state.minigame_teams = savegame.minigame_state.minigame_teams
		minigame_reward = MinigameReward.new()
		if savegame.minigame_state.has_reward:
			minigame_reward.duel_reward = savegame.minigame_state.duel_reward
			if savegame.minigame_state.item_reward:
				minigame_reward.gnu_solo_item_reward = dict_to_inst(savegame.minigame_state.item_reward)
	else:
		minigame_state = null
	player_turn = savegame.board_state.player_turn
	turn = savegame.board_state.turn
	for id in settings:
		change_setting(id, savegame.settings.get(id))

	trap_states = savegame.board_state.trap_states.duplicate()
	loaded_from_savegame = true
	update_playerlist()
	send_settings()
	send_board()

@rpc func save_game() -> void:
	if not enable_savegames:
		save_game_callback.rpc_id(multiplayer.get_remote_sender_id(), {}, "SAVE_GAME_DISABLED")
		return
	
	var controller_nodes: Array = Utility.get_nodes_in_group(self, "Controller")
	# Check whether the board is currently loaded
	# We cannot save the game during a minigame
	if not controller_nodes:
		save_game_callback.rpc_id(multiplayer.get_remote_sender_id(), {}, "SAVE_GAME_CANNOT_SAVE")
		return
	
	var controller: Controller = controller_nodes[0]
	var r_players: Array = Utility.get_nodes_in_group(self, "players")

	var savegame := SaveGameLoader.SaveGame.new()
	savegame.board_state.board_path = current_board;
	for i in len(player_info):
			var player := savegame.add_player()
			player.player_name = player_info[i].name
			player.is_ai = player_info[i].is_ai()
			player.ai_difficulty = player_info[i].ai_difficulty
			player.space = get_path_to(r_players[i].space)
			player.character = player_info[i].character
			player.cookies = r_players[i].cookies
			player.cakes = r_players[i].cakes
			player.items = duplicate_items(r_players[i].items)
			player.roll_modifiers = r_players[i].roll_modifiers

	savegame.board_state.cake_space = cake_space
	if minigame_state:
			savegame.minigame_state.minigame_config = minigame_state.minigame_config.filename
			savegame.minigame_state.minigame_type = minigame_state.minigame_type
			savegame.minigame_state.minigame_teams = minigame_state.minigame_teams.duplicate()
			if minigame_reward:
				savegame.minigame_state.has_reward = true
				savegame.minigame_state.duel_reward = minigame_reward.duel_reward
				if minigame_reward.gnu_solo_item_reward:
					savegame.minigame_state.item_reward = inst_to_dict(minigame_reward.gnu_solo_item_reward)
	savegame.board_state.player_turn = controller.player_turn
	savegame.board_state.turn = turn

	savegame.board_state.trap_states = []

	for trap in Utility.get_nodes_in_group(self, "trap"):
			var state := {
					node = get_path_to(trap),
					item = inst_to_dict(trap.trap),
					player = get_path_to(trap.trap_player)
			}

			savegame.board_state.trap_states.push_back(state)
	
	for id in settings:
		savegame.settings[id] = settings[id].get_value();
	save_game_callback.rpc_id(multiplayer.get_remote_sender_id(), savegame.serialize(), "")
