extends Control

signal character_selected(character)

func _ready():
	hide()
	for character in PluginSystem.character_loader.get_loaded_characters():
		var button := Button.new()
		button.expand_icon = true
		button.custom_minimum_size = Vector2(64, 64)
		button.icon = PluginSystem.character_loader.load_character_icon(character)
		button.pressed.connect(_on_character_selected.bind(character))
		$VBoxContainer/GridContainer.add_child(button)

func select_character(character: String):
	var idx := PluginSystem.character_loader.get_loaded_characters().find(character)
	if idx != -1:
		$VBoxContainer/GridContainer.get_child(idx).grab_focus()
	else:
		# This should only happen if the character is not set
		assert(character == "", "Couldn't find character in character selection: {0}".format([character]))
		$VBoxContainer/GridContainer.get_child(0).grab_focus()
	show()

func _on_character_selected(character: String):
	character_selected.emit(character)
	hide()
