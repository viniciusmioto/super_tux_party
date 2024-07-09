extends Node

var lobby: Lobby

var mainmenu
var servermenu

func _ready():
	lobby.set_current_scene(mainmenu)
	lobby.board_selected.connect(_on_board_selected)
	lobby.player_info_updated.connect(_on_player_info_updated)
	lobby.changed.connect(_on_settings_changed)
	$MarginContainer/VBoxContainer/Content/VBoxContainer/Board.disabled = true
	$MarginContainer/VBoxContainer/Footer/Start.disabled = true
	$MarginContainer/VBoxContainer/Footer/HBoxContainer/Lobby.text = "Join code: " + lobby.name
	
	for board in PluginSystem.board_loader.get_loaded_boards():
		var boards := $MarginContainer/VBoxContainer/Content/VBoxContainer/Board
		boards.add_item(board)
		boards.set_item_metadata(boards.get_item_count() - 1, board)
	$MarginContainer/VBoxContainer/Footer/Start.grab_focus()

func _on_settings_changed(settings: Array):
	var root := $MarginContainer/VBoxContainer/Content/ScrollContainer/Sidebar
	for child in root.get_children():
		child.queue_free()
		root.remove_child(child)
	var label := Label.new()
	label.text = "MENU_LOBBY_SETTINGS"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.theme_type_variation = &"HeaderMedium"
	root.add_child(label)
	for entry in settings:
		var id = entry[0]
		var setting = entry[1]
		match setting.type:
			Lobby.Settings.TYPES.BOOL:
				var checkbox := CheckButton.new()
				checkbox.text = setting.name
				checkbox.button_pressed = setting.value
				checkbox.disabled = not lobby.is_lobby_owner(multiplayer.get_unique_id())
				checkbox.toggled.connect(_on_change_setting.bind(id))
				root.add_child(checkbox)
			Lobby.Settings.TYPES.INT:
				var container := HBoxContainer.new()
				var option_label := Label.new()
				var slider := SpinBox.new()
				slider.min_value = setting.value[1]
				slider.max_value = setting.value[2]
				slider.value = setting.value[0]
				slider.editable = lobby.is_lobby_owner(multiplayer.get_unique_id())
				option_label.text = setting.name
				option_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				slider.value_changed.connect(_on_setting_slider_change.bind(id))
				container.add_child(option_label)
				container.add_child(slider)
				root.add_child(container)
			Lobby.Settings.TYPES.OPTIONS:
				var container := HBoxContainer.new()
				var option_label := Label.new()
				var optionbutton := OptionButton.new()
				for option in setting.value[1]:
					optionbutton.add_item(tr(option))
				optionbutton.select(setting.value[1].find(setting.value[0]))
				optionbutton.disabled = not lobby.is_lobby_owner(multiplayer.get_unique_id())
				option_label.text = setting.name
				option_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				optionbutton.item_selected.connect(_on_setting_option_change.bind(optionbutton, id))
				container.add_child(option_label)
				container.add_child(optionbutton)
				root.add_child(container)

func _on_change_setting(value, id: String):
	lobby.update_setting(id, value)

func _on_setting_slider_change(value: float, id: String):
	lobby.update_setting(id, int(value))

func _on_setting_option_change(idx: int, node: OptionButton, id: String):
	lobby.update_setting(id, node.get_item_text(idx))

func _on_board_selected(board: String):
	$MarginContainer/VBoxContainer/Content/VBoxContainer/Board.text = board

func _on_player_info_updated(info: Array):
	var is_owner: bool = lobby.is_lobby_owner(multiplayer.get_unique_id())
	$MarginContainer/VBoxContainer/Content/VBoxContainer/Board.disabled = not is_owner
	$MarginContainer/VBoxContainer/Footer/Start.disabled = not is_owner
	
	var characters = $MarginContainer/VBoxContainer/Content/VBoxContainer/Characters
	for child in characters.get_children():
		child.queue_free()
		characters.remove_child(child)
	
	var remaining_player_indices = range(4)
	for playerinfo in info:
		if playerinfo.addr.peer_id == multiplayer.get_unique_id():
			remaining_player_indices.erase(playerinfo.addr.idx)
		var player := preload("res://client/menus/lobby/lobby_player.tscn").instantiate()
		var playername: LineEdit = player.get_node("PanelContainer/HBoxContainer/Name")
		var character: Button = player.get_node("PanelContainer/HBoxContainer/Character")
		var remove: Button = player.get_node("PanelContainer/HBoxContainer/Remove")
		playername.text = playerinfo.name
		playername.text_submitted.connect(_on_name_changed.bind(playerinfo.addr.idx))
		if playerinfo.character:
			character.icon = PluginSystem.character_loader.load_character_icon(playerinfo.character)
		character.pressed.connect(_on_character_select.bind(playerinfo.addr))
		remove.pressed.connect(_on_remove_player.bind(playerinfo.addr.idx))
		if playerinfo.addr.peer_id != multiplayer.get_unique_id():
			playername.editable = false
			character.disabled = true
			remove.disabled = true
		characters.add_child(player)

	while characters.get_child_count() < lobby.LOBBY_SIZE:
		var placeholder = preload("res://client/menus/lobby/player_join_placeholder.tscn").instantiate()
		placeholder.available = remaining_player_indices
		placeholder.add_player.connect(_on_add_player)
		characters.add_child(placeholder)

func _on_add_player(idx: int):
	lobby.add_player(idx)

func _on_remove_player(idx: int):
	lobby.remove_player(idx)

func _on_name_changed(playername: String, idx: int):
	lobby.set_player_name(idx, playername)

func _on_character_select(addr):
	$CharacterMenu.character_selected.connect(_on_CharacterMenu_character_selected.bind(addr.idx), CONNECT_ONE_SHOT)
	$CharacterMenu.select_character(lobby.get_player_by_addr(addr).character)

func _on_CharacterMenu_character_selected(character: String, idx: int) -> void:
	lobby.select_character(idx, character)

func _on_Board_item_selected(index: int) -> void:
	lobby.select_board($MarginContainer/VBoxContainer/Content/VBoxContainer/Board.get_item_metadata(index))

func _on_Leave_pressed() -> void:
	queue_free()
	if servermenu:
		servermenu.show()
		servermenu.refresh()
	else:
		Global.destroy_local_server()
		mainmenu.get_node("MainMenu").show()

func _on_Start_pressed() -> void:
	lobby.start()

func _on_lobby_code_copy() -> void:
	DisplayServer.clipboard_set(lobby.name)
