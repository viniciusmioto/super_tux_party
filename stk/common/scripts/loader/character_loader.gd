## Responsible for the automatic discovery and loading of characters
class_name CharacterLoader

## The filename for a character scene.
const CHARACTER_FILENAME := "character.tscn"
## The filename for a character splash art.
const CHARACTER_SPLASHNAME := "splash.png"
## The filename for a character icon.
const CHARACTER_ICONNAME := "icon.png"

const _NEEDED_FILES := [ CHARACTER_FILENAME ]

## This directory contains characters
const CHARACTER_PATH := "res://plugins/characters"

var _CHARACTER_SCRIPT: GDScript = preload("res://common/scripts/character.gd")

# Stores the name of each subdirectory of CHARACTER_PATH
var _characters: Array[String] = []

func _discover_character(filename: String) -> void:
	var scene = load(filename).instantiate()
	
	# Check if the character has the necessary script attached
	if _CHARACTER_SCRIPT.instance_has(scene):
		# Get the second last path entry
		# e.g. res://plugins/characters/Tux/character.tscn -> Tux
		_characters.append(filename.split('/')[-2])
	else:
		var msg = "Character `{0}` does not have the script " + \
				"`res://scripts/character.gd` attached. " + \
				"The character will not be loaded"
		push_warning(msg.format([filename]))
	scene.free()

func _init():
	print("Loading characters...")
	PluginSystem.load_files_from_path(CHARACTER_PATH, _NEEDED_FILES, _discover_character)
	print("Loading characters finished")
	
	print_loaded_characters()

## Print all loaded characters
func print_loaded_characters() -> void:
	print("Loaded characters:")
	for i in _characters:
		print("\t" + i)

## Returns a list of character names
func get_loaded_characters() -> Array[String]:
	return _characters.duplicate()

## Load a character's scene
func load_character(name: String) -> Node3D:
	return load(CHARACTER_PATH + "/" + name + "/" + CHARACTER_FILENAME).instantiate()

## Load a character's splash art
func load_character_splash(name: String) -> Texture2D:
	return load(CHARACTER_PATH + "/" + name + "/" + CHARACTER_SPLASHNAME) as Texture2D

## Load a character's icon
func load_character_icon(name: String) -> Texture2D:
	return load(CHARACTER_PATH + "/" + name + "/" + CHARACTER_ICONNAME) as Texture2D
