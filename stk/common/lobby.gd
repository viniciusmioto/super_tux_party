## Stores data relating to a game of "Super Tux Party"
## @tutorial(Network Design): https://gitlab.com/SuperTuxParty/SuperTuxParty/-/wikis/docs/For-Plugin-Authors/Network-Design
extends Node
class_name Lobby

## Emitted when all objects queued for loading have finished loading
signal loading_finished

## This class uniquely identifies a player on the network layer.
class PlayerAddress:
	## The network id of the player, see [method MultiplayerAPI.get_unique_id].
	var peer_id: int
	## There may be multiple players playing on the same machine (e.g. local multiplayer) [br]
	## The index distinguishes players with the same [member peer_id]
	var idx: int

	func _init(peer_id: int, idx: int):
		self.peer_id = peer_id
		self.idx = idx

	## Check whether this [Lobby.PlayerAddress] is equal to [param other]. [br]
	## A PlayerAddress is considered equal if the [member peer_id] and [member idx] are equal
	func eq(other: PlayerAddress) -> bool:
		return peer_id == other.peer_id and idx == other.idx

	## Encodes this object to send it over the network. [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	func encode():
		return [peer_id, idx]

	## Decodes a [Lobby.PlayerAddress] from the network representation.
	## See [method encode] [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	static func decode(data) -> PlayerAddress:
		return PlayerAddress.new(data[0], data[1])

## Information about a player
class PlayerInfo:
	## A reference to the lobby the player is in
	var lobby: Lobby
	## A unique ID identifying the player in the range from 1
	## to the maximum number of players in the game (currently: 4) [br]
	## [b] Note: Player ID's are unique in a given lobby [/b]
	var player_id: int
	## Identifies the player on the network layer
	var addr: PlayerAddress
	## Name of the player
	var name: String
	## Selected character.
	## An entry from [method CharacterLoader.get_loaded_characters]
	var character: String
	## Difficulty for the AI player. [br]
	## Usage/Implementation depends on the minigame.
	var ai_difficulty := Difficulty.NORMAL
	
	func _init(lobby: Node, addr: PlayerAddress, name: String, character: String):
		self.lobby = lobby
		self.addr = addr
		self.name = name
		self.character = character
	
	## Encodes this object to send it over the network. [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	func encode():
		return [addr.encode(), name, character, ai_difficulty]
	
	## Decodes a [Lobby.PlayerInfo] from the network representation.
	## See [method encode] [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	static func decode(lobby: Node, data) -> PlayerInfo:
		return PlayerInfo.new(lobby, PlayerAddress.decode(data[0]), data[1], data[2])
	
	## Returns whether this player is AI controlled.
	func is_ai() -> bool:
		return addr.peer_id == 1
	
	## Returns whether this player should be processed on this machine. [br]
	## Use this to determine whether you should process input for a player. [br]
	## AI players are always processed on the server. Whereas human players are
	## processed on the machine their gamepad is connected.
	func is_local() -> bool:
		return addr.peer_id == lobby.multiplayer.get_unique_id()

## Game State of a player, includes information such as cookies, cakes, etc.
class PlayerState:
	## Reference to the player data that does not change.
	var info: Lobby.PlayerInfo
	## The player's collected cookies
	var cookies := 10
	## The player's collected cakes
	var cakes := 0
	## The player's items
	var items := [ load("res://plugins/items/dice/item.gd").new().serialize() ]
	## Current Bonus or malus that affects the dice throws. [br]
	## New effects can be added via [method PlayerBoard.add_roll_modifier]
	var roll_modifiers := []
	
	func _init(info: Lobby.PlayerInfo):
		self.info = info

	## Encodes this object to send it over the network. [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	func encode():
		return [info.player_id, cookies, cakes, items, roll_modifiers]

	## Decodes a [Lobby.PlayerState] from the network representation.
	## See [method encode] [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	static func decode(lobby: Lobby, data) -> PlayerState:
		var info := lobby.get_player_by_id(data[0])
		if not info:
			return null
		var state = PlayerState.new(info)
		state.cookies = data[1]
		state.cakes = data[2]
		state.items = data[3]
		state.roll_modifiers = data[4]
		return state

	## Which space on the board the player is standing on.
	var space: NodePath

## Describes which minigame is about to be played
class MinigameState:
	## Parsed minigame configuration from the [MinigameLoader]
	var minigame_config: MinigameLoader.MinigameConfigFile
	## Information about teams. Depends on the [member minigame_type]. [br]
	## It is an array with 2 elements. Each element is an array with the
	## player ids of that team [br] [br]
	## For FFA: All players are on Team1,
	## e.g. [code]minigame_teams = [[1, 2, 3, 4], []][/code] [br]
	## For Duel: The players are on different teams,
	## e.g. [code]minigame_teams = [[3], [1]][/code] [br]
	## For 2v2: Each team has 2 players,
	## e.g. [code]minigame_teams = [[1, 4], [2, 3]][/code] [br]
	## For 1v3: The solo player is in Team2, all other players in Team1,
	## e.g. [code]minigame_teams =  [[1, 3, 4], [2]][/code] [br]
	## For GnuSolo and NolokSolo: The first team has exactly one player,
	## e.g. [code]minigame_temas = [[1], []][/code] [br]
	## For GnuCoop and NolokCoop: All players are on Team1,
	## e.g. [code]minigame_teams = [[1, 2, 3, 4], []][/code]
	var minigame_teams: Array = []
	## The type of minigame
	var minigame_type := MINIGAME_TYPES.INVALID

	## Whether the current minigame was meant to be tried only [br]
	## The result of a minigame that is tried only will not have any impact
	## on the game. [br]
	## Plugin Authors should ignore this property as it is handled transparently
	## by the game
	var is_try: bool = false
	
	## Encodes this object to send it over the network. [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	func encode():
		return [minigame_config.filename, minigame_teams, minigame_type]
	
	## Decodes a [Lobby.MinigameState] from the network representation.
	## See [method encode] [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	static func decode(data) -> MinigameState:
		var state := MinigameState.new()
		state.minigame_config = PluginSystem.minigame_loader.get_config_by_path(data[0])
		if not state.minigame_config:
			return null
		state.minigame_teams = data[1]
		state.minigame_type = data[2]
		return state

class MinigameSummary:
	var state: Lobby.MinigameState
	var placement
	var reward

## Represents the special rewards for some minigame types. [br]
## Used only by duel minigames and gnu solo minigames.
class MinigameReward:
	## The reward type in a duel minigame
	var duel_reward := MINIGAME_DUEL_REWARDS.INVALID
	## The (possibly) rewarded item in a gnu solo minigame
	var gnu_solo_item_reward: Item = null

## Represents a setting value in a game lobby. [br]
## A setting value has a few types: [br]
##   - An integer type (with upper/lower limits) [br]
##   - A boolean (on/off) [br]
##   - A selection from a handful of options
class Settings:
	enum TYPES {
		INT,
		BOOL,
		OPTIONS
	}
	## User visible name of the setting (may be a translation string)
	var name := ""
	## the type of this setting
	var type: TYPES
	## The value of this setting (including metadata)
	## Depends on the concrete type
	var value = null

	## Create a new integer setting ranging from [param start] to [param end]
	## with the default value [param value] and name [param name].
	static func new_range(name: String, value: int, start: int, end: int) -> Settings:
		assert (start <= value && value <= end, "Value not in range")
		var obj := Settings.new()
		obj.name = name
		obj.type = Settings.TYPES.INT
		obj.value = [value, start, end]
		return obj

	## Create a new boolean setting with name [param name] and default
	## value [param value]
	static func new_bool(name: String, value: bool) -> Settings:
		var obj := Settings.new()
		obj.name = name
		obj.type = Settings.TYPES.BOOL
		obj.value = value
		return obj

	## Create a new setting with name [param name] and a set of valid
	## [param options]. [br]
	## The default [param value] must be part of the options
	static func new_options(name: String, value: String, options: Array[String]) -> Settings:
		assert(value in options, "The default value must be part of all possible values")
		var obj := Settings.new()
		obj.name = name
		obj.type = Settings.TYPES.OPTIONS
		obj.value = [value, options]
		return obj

	## Encodes this object to send it over the network. [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	func encode() -> Array:
		return [name, type, value]

	## Returns the value of this setting. The return type depends on
	## the setting's [member type]
	func get_value():
		match type:
			Settings.TYPES.INT:
				return value[0]
			Settings.TYPES.BOOL:
				return value
			Settings.TYPES.OPTIONS:
				return value[0]

	## Change the value of this setting. [br]
	## Note that this only changes this data structure and does not update
	## this data on the remote machines.
	func update_value(new_value) -> bool:
		match type:
			Settings.TYPES.INT:
				if not new_value is int:
					return false
				if not (value[1] <= new_value and new_value <= value[2]):
					return false
				value[0] = new_value
				return true
			Settings.TYPES.BOOL:
				if not new_value is bool:
					return false
				value = new_value
				return true
			Settings.TYPES.OPTIONS:
				if not new_value is String:
					return false
				if not new_value in value[1]:
					return false
				value[0] = new_value
				return true
			_:
				@warning_ignore("assert_always_false")
				assert (false, "Invalid Settings type")
				return false

	static func _check_type(type: int, value) -> bool:
		match type:
			Settings.TYPES.INT:
				if not value is Array:
					return false
				if len(value) != 3:
					return false
				var v = value[0]
				var start = value[1]
				var end = value[2]
				if not (v is int and start is int and end is int):
					return false
				return start <= v && v <= end
			Settings.TYPES.BOOL:
				return value is bool
			Settings.TYPES.OPTIONS:
				if not value is Array:
					return false
				if len(value) != 2:
					return false
				if not value[0] is String:
					return false
				if not value[1] is Array:
					return false
				for v in value[1]:
					if not v is String:
						return false
				return true
			_:
				return false

	## Decodes a [Lobby.Settings] from the network representation.
	## See [method encode] [br]
	## Format is internal and subject to change! [br]
	## [b] Only use this in the network layer and not in plugin code! [/b]
	static func decode(data: Array) -> Settings:
		var obj := Settings.new()
		obj.name = data[0]
		obj.type = data[1]
		obj.value = data[2]
		if not obj.name is String:
			return null
		if not obj.type in [Settings.TYPES.INT, Settings.TYPES.BOOL, Settings.TYPES.OPTIONS]:
			return null
		if not _check_type(obj.type, obj.value):
			return null
		return obj

enum MINIGAME_TYPES {
	## Invalid minigame type [br]
	## Used as default value to detect uninitialized data
	INVALID = -1,
	DUEL,
	ONE_VS_THREE,
	TWO_VS_TWO,
	FREE_FOR_ALL,
	NOLOK_SOLO,
	NOLOK_COOP,
	GNU_SOLO,
	GNU_COOP,
}

enum NOLOK_ACTION_TYPES {
	SOLO_MINIGAME,
	COOP_MINIGAME,
	BOARD_EFFECT
}

enum GNU_ACTION_TYPES {
	SOLO_MINIGAME,
	COOP_MINIGAME
}

enum MINIGAME_DUEL_REWARDS {
	## Invalid duel reward [br]
	## Used as default value to detect uninitialized data
	INVALID = -1,
	TEN_COOKIES,
	ONE_CAKE
}

enum Difficulty {
	EASY,
	NORMAL,
	HARD
}

# linear, 1st: 15, 2nd: 10, 3rd: 5, 4th: 0
# winner_only, 1st: 10, 2nd-4th: 0
enum AWARD_TYPE {
	LINEAR,
	WINNER_ONLY
}

## The maximum number of players in the lobby
const LOBBY_SIZE := 4

## The players in the lobby described by a [PlayerInfo].
var player_info: Array[PlayerInfo] = []
## The game state of each player described by a [PlayerState].
var playerstates: Array[PlayerState] = []

# Pointer to top-level node in current scene.
var _current_scene: Node = null

## Resource location of the current board.
var current_board: String

## The minigame that is currently being played. [br]
## If we're returning to the game and this is not null, then
## we've been in the "try minigame" mode. [br]
## Therefore we need to show the minigame screen again to
## do the actual minigame
var minigame_state: MinigameState = null

## Holds information regarding the last played minigame
var minigame_summary: MinigameSummary = null

## Holds the reward type for the current minigame:
## Only used in Duel and Gnu Solo minigames
var minigame_reward: MinigameReward = null

## Node on the board that currently offers to buy a cake
var cake_space := NodePath()

var _loaded_scene: Node = null

## Find the [Lobby] the given [param caller] belongs to. [br]
## It does so by traversing the Scene Tree upwards until the [Lobby] node
## is found. Therefore to work properly, the given node must have already
## been added to the SceneTree.
static func get_lobby(caller: Node) -> Lobby:
	# The scripts for each lobby (if present)
	var client_lobby: GDScript
	var server_lobby: GDScript
	if ResourceLoader.exists("res://client/lobby.gd"):
		client_lobby = load("res://client/lobby.gd")
	if ResourceLoader.exists("res://server/lobby.gd"):
		server_lobby = load("res://server/lobby.gd")
	while caller != null:
		if client_lobby and client_lobby.instance_has(caller):
			return caller as Lobby
		if server_lobby and server_lobby.instance_has(caller):
			return caller as Lobby
		caller = caller.get_parent()
	# Couldn't find a lobby
	return null

## Returns whether the given network ID owns this lobby and is therefore
## authorized to change settings, select the board, etc.
func is_lobby_owner(id: int) -> bool:
	return player_info and id == player_info[0].addr.peer_id

## Check whether a player with the given network ID exists in this lobby.
func has_peer(id: int):
	for player in player_info:
		if player.addr.peer_id == id:
			return true
	return false

func _assign_player_ids():
	var player_id := 1
	for player in player_info:
		player.player_id = player_id
		player_id += 1

## Returns the number of players. [br]
## If called before the game has been started, this does not include AI players
func get_player_count():
	return len(player_info)

## Returns the [PlayerInfo] associated with the given [param player_id]
func get_player_by_id(player_id: int) -> PlayerInfo:
	if player_id - 1 > len(player_info):
		return null
	return player_info[player_id - 1]

## Returns the [PlayerInfo] associated with the given [param player_address]
func get_player_by_addr(player_address: PlayerAddress) -> PlayerInfo:
	for player in player_info:
		if player.addr.eq(player_address):
			return player
	return null

## Return all [PlayerInfo] that belong to the given network [param id]. [br]
## This returns all players playing on the same machine.
func get_players_by_network_id(id: int) -> Array[PlayerInfo]:
	var res := []
	for player in player_info:
		if player.addr.peer_id == id:
			res.append(player)
	return res

## Returns the [PlayerState] for a given [param player_id]
func get_playerstate(player_id: int) -> PlayerState:
	return playerstates[player_id - 1]

# ----- Network helper ----- #

## Call the rpc function [param method] on all machines in this lobby
## except on ourselves. [br]
## To change the properties of this rpc call (such as reliable/unreliable),
## configure them via [annotation @GDScript.@rpc]. [br]
## To pass parameters, [method Callable.bind] them first. [br]
## Note: This method ignores the [code]"call_local"[/code] option
## from [annotation @GDScript.@rpc].
func broadcast(method: Callable):
	# Don't send message to self
	var messaged := [ multiplayer.get_unique_id() ]
	for player in player_info:
		if player.addr.peer_id in messaged:
			continue
		messaged.append(player.addr.peer_id)
		method.rpc_id(player.addr.peer_id)

# ----- Scene instantiation ----- #

# Internal function for loading a character's model and other data
# into the nodes used by the loaded scene
func _load_player(player: Node, info: PlayerInfo):
	var character := info.character
	var wants_model := player.has_node("Model")
	var wants_shape := player.has_node("Shape3D")

	if wants_model:
		var model: Node3D = PluginSystem.character_loader.load_character(character)
		model.name = "Model"

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
			shape.get_parent().remove_child(shape)
			shape.transform = transform
			shape.name = "Shape3D"
		else:
			push_warning("Character `{0}` has no shape".format([character]))

		var placeholder: Node3D = player.get_node("Model")
		# The model should be at the place, the placeholder was originally
		model.transform = placeholder.transform * model.transform
		# The shape should be at the same position as the model
		if shape:
			shape.transform = model.transform * shape.transform

		placeholder.replace_by(model, true)
		if wants_shape:
			# shape must be a direct child of kinematicBody and similar
			# Therefore we need to move it one up in the scene tree
			player.get_node("Shape3D").replace_by(shape)
	elif wants_shape:
		push_warning(
			"`{0}` in scene `{1}`".format([player.name, player.owner.filename])
			+ " has a `Shape3D` child, but no `Model` child.\n"
			+ "This is not allowed. Ignoring `Shape3D`")

	player.info = info

# ----- Scene changing code ----- #

## Sets the current main scene of this lobby [br]
## The current main scene is unloaded, when a new scene (such as a board or
## minigame) is loaded.
func set_current_scene(scene: Node):
	_current_scene = scene

func _goto_scene_instant(scene: PackedScene) -> void:
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = scene.instantiate()
	add_child(_current_scene)

func _change_scene_to_file():
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = _loaded_scene
	_loaded_scene = null

	add_child(_current_scene)

var _objects_to_load := 0
func _load_interactive(path: String, method: Callable):
	_objects_to_load += 1
	Global._load_interactive(path, _object_loaded.bind(method))

func _object_loaded(resource: Resource, callback: Callable):
	_objects_to_load -= 1
	callback.call(resource)
	if _objects_to_load == 0:
		loading_finished.emit()
