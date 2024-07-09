extends Lobby

signal player_info_updated(player_info)
signal changed(settings)
signal board_selected(board)
signal game_start
signal savegame_saved

const MINIGAME_TEAM_COLORS = [Color(1, 0, 0), Color(0, 0, 1)]

const MINIGAME_REWARD_SCREEN_FFA =\
		preload("res://client/rewardscreens/ffa/ffa.tscn")
const MINIGAME_REWARD_SCREEN_DUEL =\
		preload("res://client/rewardscreens/duel/duel.tscn")
const MINIGAME_REWARD_SCREEN_1V3 =\
		preload("res://client/rewardscreens/1v3/1v3.tscn")
const MINIGAME_REWARD_SCREEN_2V2 =\
		preload("res://client/rewardscreens/2v2/2v2.tscn")
const MINIGAME_REWARD_SCREEN_NOLOK_SOLO =\
		preload("res://client/rewardscreens/nolok_solo/nolok_solo.tscn")
const MINIGAME_REWARD_SCREEN_NOLOK_COOP =\
		preload("res://client/rewardscreens/nolok_coop/nolok_coop.tscn")
const MINIGAME_REWARD_SCREEN_GNU_SOLO =\
		preload("res://client/rewardscreens/gnu_solo/gnu_solo.tscn")
const MINIGAME_REWARD_SCREEN_GNU_COOP =\
		preload("res://client/rewardscreens/gnu_coop/gnu_coop.tscn")

var _board_loaded_translations := []
var _minigame_loaded_translations := []

var started := false

var current_savegame := SaveGameLoader.SaveGame.new()
var savegame_name := ""
var is_new_savegame := true

func leave():
	get_tree().change_scene_to_file("res://client/menus/main_menu.tscn")
	Global.shutdown_connection()

@rpc func game_started():
	started = true
	_assign_player_ids()
	game_start.emit()
	load_board()

@rpc func board_select(board: String):
	if not board in PluginSystem.board_loader.get_loaded_boards():
		push_error("Unknown board: " + board)
		leave()
		return
	current_board = PluginSystem.board_loader.get_board_path(board)
	
	board_selected.emit(board)

@rpc func replace_by_ai(player_id: int, new_addr: Array):
	# This does only make sense when the game has already started
	if not started:
		return
	var addr = PlayerAddress.decode(new_addr)
	for player in player_info:
		if player.player_id == player_id:
			player.addr = addr

@rpc func lobby_joined(playerlist: Array):
	if started:
		return
	var decoded: Array[PlayerInfo] = []
	for player in playerlist:
		var obj := PlayerInfo.decode(self, player)
		var valid: bool = obj.character == "" or obj.character in PluginSystem.character_loader.get_loaded_characters()
		if not valid:
			push_error("Unknown character: " + obj.character)
			leave()
			return
		decoded.append(obj)
	player_info = decoded
	player_info_updated.emit(player_info)

@rpc func update_settings(settings: Array):
	var decoded := []
	for entry in settings:
		var obj := Lobby.Settings.decode(entry[1])
		if not obj:
			push_error("Invalid settings received: " + str(entry))
			leave()
			return
		decoded.append([entry[0], obj])
	changed.emit(decoded)

@rpc func playerstate_updated(data: Array):
	var decoded: Array[PlayerState] = []
	for player in data:
		var obj := PlayerState.decode(self, player)
		decoded.append(obj)
	playerstates = decoded

@rpc func add_player_failed():
	# TODO: error reporting
	pass


# Some boilerplate rpc function definitions
# This is necessary, because since Godot4 these methods must be declared
# on the sending side as well
@rpc
func server_update_setting(_id: int, _value): pass
@rpc
func server_add_player(_idx: int): pass
@rpc
func server_remove_player(_idx: int): pass
@rpc
func server_start(): pass
@rpc
func server_select_board(_board: String): pass
@rpc
func server_select_character(_idx: int, _char: String): pass
@rpc
func server_set_player_name(_idx: int, _name: String): pass
@rpc
func server_refresh(): pass
@rpc
func client_ready(): pass
@rpc
func _goto_minigame(_try: bool): pass

func update_setting(id: String, value):
	server_update_setting.rpc_id(1, id, value)

func add_player(idx: int):
	server_add_player.rpc_id(1, idx)

func remove_player(idx: int):
	server_remove_player.rpc_id(1, idx)

func start():
	server_start.rpc_id(1)

func end():
	playerstates = []
	_current_scene.queue_free()
	_current_scene = null
	get_tree().change_scene_to_packed(load("res://client/menus/main_menu.tscn"))

func refresh():
	server_refresh.rpc_id(1)

func select_board(board: String):
	server_select_board.rpc_id(1, board)

func select_character(idx: int, character: String):
	server_select_character.rpc_id(1, idx, character)

func set_player_name(idx: int, playername: String):
	server_set_player_name.rpc_id(1, idx, playername)

func _input(event: InputEvent) -> void:
	# Convert local input events to their respective player_id
	# Why is this necessary?
	# Local coop looks like this:
	# Player1(Peer(net_id, 0)), Player2(Peer(net_id, 1)), ...
	# The players input is named "player1_{action}" to "player4_{action}"
	# A lot of code uses this system to handle player inputs
	# In online multiplayer however, the players are sitting on multiple devices
	# Player3 may be the only player on their device and would want to use the input mappings
	# of Player1 (they are the first player on their machine after all)
	# In order to not break stuff, we have to convert these input events from the local player index to the (global) player_id
	
	# If this event is generated by the game, we do not need to convert it
	# This prevents an endless loop arising from event conversion and generated events are already consistent with the player_id naming
	# InputEventAction cannot be naturally generated by user input!
	if event is InputEventAction:
		return
	
	# If we're not in the game already, remapping makes no sense
	if not started:
		return
	var actions = ["up", "down", "left", "right", "action1", "action2", "action3", "action4", "ok", "pause"]
	for player in player_info:
		if player.is_local():
			for action in actions:
				var action_source := "player{id}_{action}".format({"id": player.addr.idx + 1, "action": action})
				var pressed := event.is_action_pressed(action_source)
				var released := event.is_action_released(action_source)
				if pressed or released:
					# Now build an InputEventAction with
					var converted := InputEventAction.new()
					converted.action = "player{id}_{action}".format({"id": player.player_id, "action": action})
					converted.pressed = pressed
					converted.strength = event.get_action_strength(action_source)
					get_viewport().set_input_as_handled()
					Input.parse_input_event(converted)
					# Do not break/return here as an optimization!
					# There may be multiple events mapped to the same key

# ----- Scene changing code ----- #

# Internal function for actually changing scene without saving any game state.
func _goto_scene(path: String, wait=true) -> void:
	_interactive_load_scene(path, func(_arg): pass, wait)

func _goto_scene_board():
	_interactive_load_scene(current_board, _goto_scene_board_callback)

func _goto_scene_board_callback(scene: Node):
	for t in _minigame_loaded_translations:
		TranslationServer.remove_translation(t)
	_minigame_loaded_translations.clear()

	for i in range(len(player_info)):
		var player = scene.get_node("Player" + str(i + 1))
		_load_player(player, player_info[i])

# Internal function for changing scene to a minigame while handling player objects.
func _goto_scene_minigame(path: String, minigame_state) -> void:
	_interactive_load_scene(path, _goto_scene_minigame_callback.bind(minigame_state))

func _goto_scene_minigame_callback(scene: Node, minigame_state):
	scene.add_child(preload("res://client/menus/pause_menu.tscn").instantiate())

	var i := 1
	for team_id in range(len(minigame_state.minigame_teams)):
		var team = minigame_state.minigame_teams[team_id]
		for player_id in team:
			var player = scene.get_node("Player" + str(i))
			_load_player(player, player_info[player_id - 1])
			if minigame_state.minigame_type == MINIGAME_TYPES.TWO_VS_TWO:
				_load_team_indicator(player, player_info[player_id - 1], team_id)

			i += 1

	# Remove unnecessary players.
	while i <= get_player_count():
		var player = scene.get_node_or_null("Player" + str(i))
		if player:
			scene.remove_child(player)
			player.queue_free()
		i += 1

func _load_team_indicator(player: Node, info: PlayerInfo, team: int):
	if not player.has_node("Model"):
		# We do not have a character model loaded, maybe this minigame is not 3D?
		# Subsequently, we do not need to add a team indicator
		return
	# Loading the character here again shouldn't do any actual loading. It should already be cached
	var model: Node3D = PluginSystem.character_loader.load_character(info.character)
	var shape: CollisionShape3D = model.get_node_or_null(model.collision_shape)
	if shape:
		# global_transform only works when the node is in the scene tree
		# Therefore, we have to compute it ourselves
		var transform := shape.transform
		var parent := shape.get_parent()
		while parent != null:
			if parent is Node3D:
				transform = parent.transform * transform
			parent = parent.get_parent()
		var bbox := Utility.get_aabb_from_shape(shape.shape, transform)
		var indicator: Sprite3D = preload(\
				"res://client/team_indicator/team_indicator.tscn"\
				).instantiate()
		indicator.modulate = MINIGAME_TEAM_COLORS[team]
		indicator.position.y = bbox.size.y / 2 + shape.position.y + 0.1
		player.get_node("Model").add_child(indicator)

func load_board():
	var dir = DirAccess.open(current_board.get_base_dir() + "/translations")
	if dir:
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break

			if file_name.ends_with(".translation") or file_name.ends_with(".po"):
				_load_interactive(dir.get_current_dir() + "/" + file_name, _install_translation_board.bind(file_name))

		dir.list_dir_end()

func goto_minigame(is_try: bool):
	_goto_minigame.rpc_id(1, is_try)

@rpc func return_to_board():
	_goto_scene_board()

@rpc func game_ended():
	_goto_scene("res://client/menus/victory_screen/victory_screen.tscn", false)
	started = false

@rpc func load_minigame():
	_goto_scene_minigame(minigame_state.minigame_config.scene_path, minigame_state)

@rpc func minigame_ended(was_try: bool, placement, reward):
	if not minigame_state:
		return
	if was_try:
		_goto_scene_board()
		return
	minigame_summary = MinigameSummary.new()
	minigame_summary.state = minigame_state
	minigame_summary.placement = placement
	minigame_summary.reward = reward
	minigame_state = null
	match minigame_summary.state.minigame_type:
		MINIGAME_TYPES.FREE_FOR_ALL:
			call_deferred("_goto_scene_instant", MINIGAME_REWARD_SCREEN_FFA)
		MINIGAME_TYPES.TWO_VS_TWO:
			call_deferred("_goto_scene_instant", MINIGAME_REWARD_SCREEN_2V2)
		MINIGAME_TYPES.ONE_VS_THREE:
			call_deferred("_goto_scene_instant", MINIGAME_REWARD_SCREEN_1V3)
		MINIGAME_TYPES.DUEL:
			call_deferred("_goto_scene_instant", MINIGAME_REWARD_SCREEN_DUEL)
		MINIGAME_TYPES.NOLOK_SOLO:
			call_deferred("_goto_scene_instant", MINIGAME_REWARD_SCREEN_NOLOK_SOLO)
		MINIGAME_TYPES.NOLOK_COOP:
			call_deferred("_goto_scene_instant", MINIGAME_REWARD_SCREEN_NOLOK_COOP)
		MINIGAME_TYPES.GNU_SOLO:
			call_deferred("_goto_scene_instant", MINIGAME_REWARD_SCREEN_GNU_SOLO)
		MINIGAME_TYPES.GNU_COOP:
			call_deferred("_goto_scene_instant", MINIGAME_REWARD_SCREEN_GNU_COOP)

func _install_translation_board(translation, file_name: String):
	if not translation is Translation:
		push_warning("Error: file " + file_name + " is not a valid translation")
		return

	TranslationServer.add_translation(translation)
	_board_loaded_translations.push_back(translation)

func load_minigame_translations(minigame_config: MinigameLoader.MinigameConfigFile) -> void:
	var dir := DirAccess.open(minigame_config.translation_directory)
	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break

		if file_name.ends_with(".translation") or file_name.ends_with(".po"):
			_install_translation_minigame(load(dir.get_current_dir() + "/" + file_name), file_name)

	dir.list_dir_end()

func _install_translation_minigame(translation, file_name: String):
	if not translation is Translation:
		push_warning("Error: file " + file_name + " is not a valid translation")
		return

	TranslationServer.add_translation(translation)
	_minigame_loaded_translations.push_back(translation)

const LOADING_SCREEN = preload("res://client/menus/loading_screen.tscn")
func _interactive_load_scene(path: String, callable: Callable, wait := true):
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = LOADING_SCREEN.instantiate()
	add_child(_current_scene)
	if wait:
		loading_finished.connect(func(): self.client_ready.rpc_id(1), CONNECT_ONE_SHOT)
	else:
		loading_finished.connect(finish_loading, CONNECT_ONE_SHOT)
	assert(callable.is_valid())
	_load_interactive(path, _scene_loaded.bind(callable))

@rpc func finish_loading():
	if _objects_to_load == 0:
		_change_scene_to_file()
	else:
		# Server is misbehaving
		leave()

func _scene_loaded(s: PackedScene, callable: Callable):
	_loaded_scene = s.instantiate()
	callable.call(_loaded_scene)

# ----- Save game code ----- #

@rpc func load_savegame(filename: String, savegame: SaveGameLoader.SaveGame):
	is_new_savegame = false
	current_savegame = savegame
	savegame_name = filename
	load_savegame.rpc_id(1, savegame.serialize())

var sent_savegame_request := false

@rpc func save_game_callback(data: Dictionary, error: String):
	if error:
		push_warning(error)
		Global.show_error(error)
	elif sent_savegame_request:
		current_savegame = SaveGameLoader.SaveGame.from_data(data)
		
		Global.savegame_loader.save(savegame_name, current_savegame)
		savegame_saved.emit()
		sent_savegame_request = false

@rpc func save_game() -> void:
	sent_savegame_request = true
	save_game.rpc_id(1)
