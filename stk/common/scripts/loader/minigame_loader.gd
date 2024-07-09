## Responsible for the automatic discovery and loading of [MinigameLoader.MinigameConfigFile] [br]
class_name MinigameLoader

## Spec for minigame config files. [br]
## Minigame config files are best created from within the editor with
## Project > Tools > Open Minigame Config
class MinigameConfigFile:
	## Path to the file this config was loaded from
	var filename := ""

	## Name of the minigame
	var name := ""
	## Path to the main scene file
	var scene_path := ""
	## Path to the preview image
	var image_path: String
	## Path to a directory containing localization files
	## (either [code].pot[/code] or [code].translation[/code] files)
	var translation_directory := ""

	## BBCode (or anything that works in RichTextLabel)
	var description = ""
	## Contains Dictionaries with { "actions" : [... list of actions ...], "text": "Description" }.
	var controls := []
	## The valid [enum Lobby.MINIGAME_TYPES] for this minigame
	var type := []

## This is the entry point filename to every minigame.
const MINIGAME_CONFIG_FILENAME := [ "minigame.json" ]
## This directory contains minigames
const MINIGAME_PATH := "res://plugins/minigames"

const _ACTIONS := ["up", "left", "down", "right", "action1", "action2", "action3", "action4", "spacer"]

# all minigames in the current rotation that weren't played yet
var _minigames: Array[MinigameConfigFile] = []
# all minigames in the current rotation that were already played
var _played: Array[MinigameConfigFile] = []

# contains all minigames
# mapping file_path -> MinigameConfigFile
var _all_minigames: Dictionary

# Load a minigame from disk and add it to the list of minigames
func _discover_minigame(complete_filename: String):
	var config = MinigameLoader.parse_file(complete_filename)
	if not config:
		return
	
	_minigames.push_back(config)
	_all_minigames[complete_filename] = config

## Returns the [MinigameLoader.MinigameConfigFile] associated with [param filename]. [br]
## The [MinigameLoader.MinigameConfigFile] must have been discovered on startup.
func get_config_by_path(filename: String) -> MinigameConfigFile:
	return _all_minigames.get(filename)

## Returns all loaded minigames
func get_minigames() -> Array[MinigameConfigFile]:
	# helper to cast to the correct type
	var result: Array[MinigameConfigFile] = []
	result.assign(_all_minigames.values())
	return result

func _init() -> void:
	print("Loading minigames...")
	PluginSystem.load_files_from_path(MINIGAME_PATH, MINIGAME_CONFIG_FILENAME, _discover_minigame)

	print("Loading minigames finished")
	print_loaded_minigames()
	_minigames.shuffle()

## Print all minigames that are currently loaded
func print_loaded_minigames() -> void:
	print("Loaded minigames:")
	print("\t1v3:")
	for minigame in _minigames:
		if "1v3" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\t2v2:")
	for minigame in _minigames:
		if "2v2" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tDuel:")
	for minigame in _minigames:
		if "Duel" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tFFA:")
	for minigame in _minigames:
		if "FFA" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tNolok Solo:")
	for minigame in _minigames:
		if "NolokSolo" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tNolok Coop:")
	for minigame in _minigames:
		if "NolokCoop" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tGnu Solo:")
	for minigame in _minigames:
		if "GnuSolo" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tGnu Coop:")
	for minigame in _minigames:
		if "GnuCoop" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])

## Loads a [MinigameLoader.MinigameConfigFile] from the given [param path]
static func parse_file(path: String) -> MinigameConfigFile:
	var f := FileAccess.open(path, FileAccess.READ)
	var test_json_conv = JSON.new()
	var err := test_json_conv.parse(f.get_as_text())
	f.close()

	if err != OK:
		push_error("Error in file '{0}': {1} on line {2}".format([
			path,
			test_json_conv.get_error_message(),
			test_json_conv.get_error_line()
		]))
		return null

	var result = test_json_conv.get_data()
	if not result is Dictionary:
		push_error("Error in file '{0}': content type is not a dictionary".format([path]))
		return null

	var config := MinigameConfigFile.new()
	config.filename = path

	if not result.has("name"):
		push_error("Error in file '{0}': entry 'name' missing".format([path]))
		return null
	
	if not result.name is String:
		push_error("Error in file '{0}': entry 'name' is not a string".format([
					path]))
		return null

	config.name = result.name

	if not result.has("scene_path"):
		push_error("Error in file '{0}': entry 'scene_path' missing".format([
					path]))
		return null

	if not result.scene_path is String:
		push_error("Error in file '{0}': entry 'scene_path' is not a string".format([
					path]))
		return null
	config.scene_path = result.scene_path

	if not result.has("type"):
		push_error("Error in file '{0}': entry 'type' missing".format([path]))
		return null

	config.type = result.type

	if result.has("image_path"):
		if result.image_path is String:
			config.image_path = result.image_path
		else:
			push_error("Error in file '{0}': entry 'image_path' is not a string".format([
						path]))

	if result.has("translation_directory"):
		var translation_directory = result.translation_directory
		if translation_directory is String:
			config.translation_directory = translation_directory
		else:
			push_error("Error in file '{0}': entry 'translation_directory' is not a string. Ignoring".format([
				path]))

	if result.has("description"):
		var description = result.description
		if description is String:
			config.description = description
		else:
			push_error("Error in file '{0}': entry 'description' is not a string. Ignoring".format([
						path]))

	if result.has("controls"):
		var controls = result.controls
		if controls is Array:
			var validated_controls := []
			for dict in controls:
				if not "actions" in dict:
					push_error("Error in file '{0}' in entry 'controls': Control is missing the 'actions' entry".format([
								path]))
					continue
				if not "text" in dict:
					push_error("Error in file '{0}' in entry 'controls': Control is missing the 'text' entry".format([
								path]))
					continue
				if not dict["actions"] is Array:
					push_error("Error in file '{0}' in entry 'controls': 'actions' entry is not an array".format([
								path]))
					continue
				if not dict["text"] is String:
					push_error("Error in file '{0}' in entry 'controls': 'text' entry is not a string".format([
								path]))
					continue
				if "team" in dict:
					dict["team"] = int(dict["team"])
				if "team" in dict and not dict["team"] in [0, 1]:
					push_error("Error in file '{0}' in entry 'controls': 'team' entry is neither 0 nor 1".format([
								path]))
					continue
				var valid = true
				for action in dict["actions"]:
					if not action in _ACTIONS:
						valid = false
						push_error("Error in file '{0}' in entry 'controls': 'actions' entry contains an invalid action: {1}".format([
									path, str(action)]))
						break
				if valid:
					validated_controls.append(dict)
			config.controls = validated_controls
		else:
			push_error("Error in file '{0}': entry 'controls' is not an array".format([path]))
	return config

# Utility function that should not be called use
# get_random_1v3/get_random_2v2/get_random_duel/get_random_ffa/get_random_nolok/get_random_gnu.
func _get_random_minigame(type: String) -> MinigameConfigFile:
	for i in range(len(_minigames)):
		if type in _minigames[i].type:
			var minigame := _minigames[i]
			_minigames.remove_at(i)
			_played.append(minigame)
			return minigame
	# There's no minigame that has the needed type
	# If we're at the start of the queue, then there's no minigame of that type,
	# because we just looked at all of them
	assert(len(_played) > 0, "No minigame for type: " + type)
	# Rebuild a new queue, but keep the unused elements at the start
	_played.shuffle()
	_minigames += _played
	_played = []
	return _get_random_minigame(type)

## Returns a random minigame that can be played in 1v3 mode
func get_random_1v3() -> MinigameConfigFile:
	return _get_random_minigame("1v3")

## Returns a random minigame that can be played in 2v2 mode
func get_random_2v2() -> MinigameConfigFile:
	return _get_random_minigame("2v2")

## Returns a random minigame that can be played in duel mode
func get_random_duel() -> MinigameConfigFile:
	return _get_random_minigame("Duel")

## Returns a random minigame that can be played in ffa mode
func get_random_ffa() -> MinigameConfigFile:
	return _get_random_minigame("FFA")

## Returns a random minigame that can be played in nolok solo mode
func get_random_nolok_solo() -> MinigameConfigFile:
	return _get_random_minigame("NolokSolo")

## Returns a random minigame that can be played in nolok coop mode
func get_random_nolok_coop() -> MinigameConfigFile:
	return _get_random_minigame("NolokCoop")

## Returns a random minigame that can be played in gnu solo mode
func get_random_gnu_solo() -> MinigameConfigFile:
	return _get_random_minigame("GnuSolo")

## Returns a random minigame that can be played in gnu coop mode
func get_random_gnu_coop() -> MinigameConfigFile:
	return _get_random_minigame("GnuCoop")
