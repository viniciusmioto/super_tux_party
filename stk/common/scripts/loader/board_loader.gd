## Responsible for the automatic discovery and loading of boards
class_name BoardLoader

## This is the entry point filename to every board.
const BOARD_FILENAME := "board.tscn"
## This directory contains boards
const BOARD_PATH := "res://plugins/boards"

# Stores the name of each subdirectory of BOARD_PATH.
var _boards: Array[String] = []

func _discover_board(filename: String):
	_boards.append(filename.split('/')[-2])

func _init() -> void:
	print("Loading boards...")
	PluginSystem.load_files_from_path(BOARD_PATH, [ BOARD_FILENAME ], _discover_board)
	print("Loading boards finished")

	print_loaded_boards()

# TODO: make output pretty.
## Prints all loaded boards
func print_loaded_boards() -> void:
	print("Loaded boards:")
	for i in _boards:
		print("\t" + i)

## Returns an array of all loaded board names
func get_loaded_boards() -> Array[String]:
	return _boards.duplicate()

## Returns the path to a board's scene file
func get_board_path(name: String) -> String:
	return BOARD_PATH + "/" + name + "/" + BOARD_FILENAME
