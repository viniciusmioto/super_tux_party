## Responsible for the automatic discovery and loading of [Item]
class_name ItemLoader

## This is the file name that every item needs. ([code].gdc[/code] paths are
## compiled scripts)
const NEEDED_FILES := ["item.gd", "item.gdc"]
## This directory contains items
const ITEM_PATH := "res://plugins/items"

# Stores the path to each item.gd file of each subdirectory of ITEM_PATH.
var _items := {}

var _buyable_items := {}

func _discover_item(filename: String) -> void:
	_items[filename] = true
	if filename.ends_with(".gdc"):
		_items[filename.substr(0, len(filename) - 1)] = true
	
	if load(filename).new().can_be_bought:
		_buyable_items[filename] = true

func _init() -> void:
	print("Loading items...")
	PluginSystem.load_files_from_path(ITEM_PATH, NEEDED_FILES, _discover_item)
	print("Loading items finished")

	print_loaded_items()

## Print all loaded items
func print_loaded_items() -> void:
	print("Loaded items:")
	for i in _items:
		print("\t" + i)

## Check whether a given item exists. [br]
## [param path] is the path to the item script
func has_item(path: String) -> bool:
	return path in _items

## Returns an array of all loaded item paths
func get_loaded_items() -> Array[String]:
	return Array(_items.keys(), TYPE_STRING, &"", null)

## Returns an array of all buyable item paths
func get_buyable_items() -> Array[String]:
	return Array(_buyable_items.keys(), TYPE_STRING, &"", null)
