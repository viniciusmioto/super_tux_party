class_name SaveGameLoader

const SAVEGAME_DIRECTORY = "user://saves/"

# Versioned savegame data
# Will make it easier to load old savegame formats in the future (if necessary)
class SaveGamePlayerStateV1:
	var player_name := ""
	var is_ai := false
	var ai_difficulty := Lobby.Difficulty.NORMAL
	var space: NodePath
	var character := ""
	var cookies := 0
	var cakes := 0

	var items := []
	var roll_modifiers := []

class SaveGameBoardStateV1:
	var board_path := ""
	var cake_space := NodePath()
	var player_turn := 1
	var turn := 1
	var trap_states := []

class SaveGameMinigameStateV1:
	var minigame_config: String
	var minigame_type := Lobby.MINIGAME_TYPES.INVALID
	var minigame_teams := []
	var has_reward := false
	var duel_reward := Lobby.MINIGAME_DUEL_REWARDS.INVALID
	var item_reward: Dictionary = {}

class SaveGame:
	# Version of the savegame format
	var version := 1

	var players: Array[SaveGamePlayerStateV1] = []
	var board_state := SaveGameBoardStateV1.new()
	var minigame_state := SaveGameMinigameStateV1.new()
	var settings := {}

	func add_player() -> SaveGamePlayerStateV1:
		var playerstate := SaveGamePlayerStateV1.new()
		self.players.append(playerstate)
		return playerstate

	func serialize() -> Dictionary:
		var save_dict: Dictionary = inst_to_dict(self)
		
		# 'inst2dict()' is not recursive. Serialize nested objects.
		var players_serialized := []
		for player in self.players:
			players_serialized.append(inst_to_dict(player))
		save_dict["players"] = players_serialized
		save_dict["board_state"] = inst_to_dict(self.board_state)
		save_dict["minigame_state"] = inst_to_dict(self.minigame_state)
		
		return save_dict
	
	static func from_data(data: Dictionary) -> SaveGame:
		var savegame: SaveGame = dict_to_inst(data)
		if not savegame:
			return null
		if not "players" in data:
			return null
		for i in data["players"].size():
			savegame.players[i] = dict_to_inst(data["players"][i])
			if not savegame.players[i]:
				return null
		for property in ["board_state", "minigame_state"]:
			if not property in data:
				return null
			savegame.set(property, dict_to_inst(data[property]))
			if not savegame.get(property):
				return null
		return savegame

var savegames: Dictionary

func read_savegames() -> void:
	savegames.clear()

	var dir := DirAccess.open(SAVEGAME_DIRECTORY)
	if not dir:
		return

	dir.include_hidden = true
	dir.list_dir_begin()

	while true:
		var filename: String = dir.get_next()

		if filename == "":
			break

		var path := SAVEGAME_DIRECTORY + filename
		var file := FileAccess.open(path, FileAccess.READ)
		if not file:
			print("Couldn't open file '%s': %s" % [path, error_string(FileAccess.get_open_error())])
			continue

		var savegame_var = file.get_var()
		if typeof(savegame_var) != TYPE_DICTIONARY:
			print("File '%s' is not a valid save" % path)
			continue

		file.close()

		var savegame = SaveGame.from_data(savegame_var)
		if not savegame:
			print("File '%s' is not a valid save" % path)
			continue
		savegames[filename] = savegame

	dir.list_dir_end()

func _init():
	read_savegames()

func get_num_savegames() -> int:
	return savegames.size()

func get_filename(i) -> String:
	return savegames.keys()[i]

func get_savegame(i) -> SaveGame:
	return savegames.values()[i]

# Returns true on success.
func save(filename: String, savegame: SaveGame) -> bool:
	# insert new savegame or overwrite previous savegame of that name
	savegames[filename] = savegame

	if not DirAccess.dir_exists_absolute(SAVEGAME_DIRECTORY):
		var err: int = DirAccess.make_dir_recursive_absolute(SAVEGAME_DIRECTORY)
		if err != OK:
			print("Failed to create directory '%s'" % SAVEGAME_DIRECTORY)
			return false

	var path: String = SAVEGAME_DIRECTORY + filename
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("Failed to open file '%s': %s" % [path, error_string(FileAccess.get_open_error())])
		return false

	file.store_var(savegame.serialize())
	file.close()
	return true

func delete_savegame(filename: String) -> void:
	if not savegames.has(filename):
		return

	savegames.erase(filename)

	var dir := DirAccess.open(SAVEGAME_DIRECTORY)
	var err := dir.remove(filename)
	if err != OK:
		print("Failed to delete file '%s'" % [SAVEGAME_DIRECTORY + filename, error_string(err)])
