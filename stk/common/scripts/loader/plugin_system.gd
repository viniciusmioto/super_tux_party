extends Node

# The directory from which plugins are loaded. Plugins have to be either in
# .zip or .pck file format.
const PLUGIN_DIRECTORY := "plugins"

@onready var board_loader := BoardLoader.new()
@onready var minigame_loader := MinigameLoader.new()
@onready var character_loader := CharacterLoader.new()
@onready var item_loader := ItemLoader.new()

func load_files_from_path(path: String, filename: Array, callback: Callable):
	var dir := DirAccess.open(path)
	if not dir:
		print("Unable to open directory '{0}'. Reason: {1}".format([path,
			error_string(DirAccess.get_open_error())]))
		return

	dir.include_hidden = true
	dir.include_navigational = false
	dir.list_dir_begin()

	while true:
		var entry: String = dir.get_next()

		if entry == "":
			break
		elif dir.current_is_dir():
			for file in filename:
				if dir.file_exists(entry + "/" + file) or dir.file_exists(entry + "/" + file + ".remap"):
					callback.call(path + "/" + entry + "/" + file)

	dir.list_dir_end()

# Loads all .pck and .zip files into the res:// file system.
func read_content_packs() -> void:
	var dir := DirAccess.open(PLUGIN_DIRECTORY)
	if not dir:
		print("Unable to open directory '{0}'. Reason: {1}".format([
				PLUGIN_DIRECTORY, error_string(DirAccess.get_open_error())]))
		return
	dir.list_dir_begin()  # Parameter indicates to skip "." and "..".# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file: String = dir.get_next()

		if file == "":
			break
		elif not dir.current_is_dir() and (file.ends_with(".pck") or\
				file.ends_with(".zip")):
			if ProjectSettings.load_resource_pack(
					PLUGIN_DIRECTORY + "/" + file, false):
				print("Successfully loaded plugin: " + file)
			else:
				print("Error while loading plugin: " + file)
		elif not dir.current_is_dir():
			print("Failed to load plugin: '{0}' is neither a super.pck" + \
					" nor a super.zip file".format([file]))
	dir.list_dir_end()

func _init() -> void:
	# Only use files present in the project, no external files.
	# Useful for testing.
	if not OS.is_debug_build() or ProjectSettings.get("plugins/load_plugins"):
		print("Loading plugins...")
		read_content_packs()
		print("Loading plugins finished")
