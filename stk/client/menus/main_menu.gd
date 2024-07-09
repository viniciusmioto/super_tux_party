extends Control

@onready var server_list := $ServerList/VBoxContainer/ScrollContainer/List
var add_server_button := Button.new()

var lobby: Node

func _ready() -> void:
	# Wait with main menu music until audio options have been loaded
	$AudioStreamPlayer.play()
	$MainMenu/Buttons/Play.grab_focus()
	
	var servers: Array = get_servers()
	for server in servers:
		create_server_entry(server)
	add_server_button.text = "+"
	add_server_button.pressed.connect(_on_ServerList_server_add)
	server_list.add_child(add_server_button)
	
	var current_server := Global.get_current_server()
	if current_server and Global.is_local_multiplayer():
		open_lobby(current_server.current_lobby)
		current_server.current_lobby.refresh()
	elif current_server:
		_on_connection_succeeded(current_server)
		$MainMenu.hide()

#*** Options menu ***#

func _on_Options_pressed() -> void:
	$Animation.play_backwards("MainMenu")
	await $Animation.animation_finished
	$MainMenu/Buttons.hide()
	$MainMenu/SubViewportContainer.hide()
	$OptionsMenu.show()
	$Animation.play("OptionsMenu")
	$OptionsMenu/OptionsMenu/Menu/Back.grab_focus()

func _on_OptionsMenu_quit() -> void:
	$OptionsMenu/OptionsMenu/Menu/Back.disabled = true
	$Animation.play_backwards("OptionsMenu")
	await $Animation.animation_finished
	$OptionsMenu.hide()
	$MainMenu/Buttons.show()
	$OptionsMenu/OptionsMenu/Menu/Back.disabled = false
	$MainMenu/SubViewportContainer.show()
	$Animation.play("MainMenu")
	$MainMenu/Buttons/Options.grab_focus()

#*** Amount of players menu ***#

func _on_Play_pressed() -> void:
	var game := Global.create_local_server()
	await game.multiplayer.connected_to_server
	lobby = await game.create_lobby()
	if not lobby:
		Global.destroy_local_server()
		return
	open_lobby(lobby)

func open_lobby(lobby: Lobby) -> void:
	var lobby_menu = preload("res://client/menus/lobby/lobby_menu.tscn").instantiate()
	lobby_menu.lobby = lobby
	lobby_menu.mainmenu = self
	add_child(lobby_menu)
	$MainMenu.hide()

func _on_Play2_pressed() -> void:
	$MainMenu.hide()
	$ServerList.show()
	$ServerList/VBoxContainer/Footer/Leave.grab_focus()

#*** Load game menu ***#

func _on_Load_pressed() -> void:
	Global.savegame_loader.read_savegames()
	var savegame_template: PackedScene =\
			preload("res://client/savegames/savegame_entry.tscn")
	for i in Global.savegame_loader.get_num_savegames():
		var savegame_entry := savegame_template.instantiate() as Control
		var savegame := Global.savegame_loader.get_savegame(i)
		var filename := Global.savegame_loader.get_filename(i)
		savegame_entry.get_node("Load").text = filename

		savegame_entry.get_node("Load").pressed.connect(_on_SaveGame_Load_pressed.bind(filename, savegame))
		savegame_entry.get_node("Delete").pressed.connect(_on_SaveGame_Delete_pressed.bind(filename, savegame_entry))

		$LoadGameMenu/ScrollContainer/Saves.add_child(savegame_entry)

	$Animation.play_backwards("MainMenu")
	await $Animation.animation_finished
	$MainMenu/Buttons.hide()
	$LoadGameMenu.show()
	$Animation.play("LoadGameMenu")
	if $LoadGameMenu/ScrollContainer/Saves.get_child_count() > 0:
			$LoadGameMenu/ScrollContainer/Saves.\
					get_child(0).get_child(0).grab_focus()
	else:
		$LoadGameMenu/Back.grab_focus()

func _on_SaveGame_Load_pressed(filename: String, savegame: SaveGameLoader.SaveGame) -> void:
	var game := Global.create_local_server()
	await get_tree().network_peer.connection_succeeded
	lobby = await game.create_lobby()
	if not lobby:
		Global.destroy_local_server()
		return
	open_lobby(lobby)
	lobby.load_savegame(filename, savegame)
	$LoadGameMenu.hide()

func _on_SaveGame_Delete_pressed(filename: String, node: Control) -> void:
	var index: int = node.get_index()
	node.queue_free()
	$LoadGameMenu/ScrollContainer/Saves.remove_child(node)

	var num_children: int =\
			$LoadGameMenu/ScrollContainer/Saves.get_child_count()
	if num_children > 0:
		# warning-ignore:narrowing_conversion
		$LoadGameMenu/ScrollContainer/Saves.get_child(
				min(index, num_children - 1)).get_child(0).grab_focus()
	else:
		$LoadGameMenu/Back.grab_focus()

	Global.savegame_loader.delete_savegame(filename)

func _on_LoadGame_Back_pressed() -> void:
	for i in $LoadGameMenu/ScrollContainer/Saves.get_children():
		i.queue_free()

	$LoadGameMenu/Back.disabled = true
	$Animation.play_backwards("LoadGameMenu")
	await $Animation.animation_finished
	$LoadGameMenu.hide()
	$MainMenu/Buttons.show()
	$LoadGameMenu/Back.disabled = false
	$Animation.play("MainMenu")
	$MainMenu/Buttons/Load.grab_focus()

func _on_Quit_pressed() -> void:
	get_tree().quit()

func _on_Screenshots_pressed():
	OS.shell_open("file://{0}/screenshots".format([OS.get_user_data_dir()]))

func _on_AnimationPlayer_animation_finished(_anim_name: String) -> void:
	await get_tree().create_timer(5).timeout
	$MainMenu/SubViewportContainer/SubViewport/tux/AnimationPlayer.play("ArmatureAction")
	$MainMenu/SubViewportContainer/SubViewport/tux/AnimationPlayer2.play("CylinderAction")

#*** Server List Menu ***#

func _on_ServerList_Leave_pressed() -> void:
	$ServerList.hide()
	$MainMenu.show()
	$MainMenu/Buttons/Play2.grab_focus()

func _on_ServerList_server_add():
	var form := preload("res://client/menus/server_list_add_entry.tscn").instantiate()
	form.confirmed.connect(_on_ServerList_server_added.bind(form))
	form.canceled.connect(form.queue_free)
	server_list.add_child(form)
	# Make the "+" button the last child again
	add_server_button.move_to_front()

func get_servers() -> Array:
	return Global.storage.get_value("ServerList", "servers", [])

func save_servers(servers: Array):
	Global.storage.set_value("ServerList", "servers", servers)
	Global.save_storage()

func _on_ServerList_server_added(data: Dictionary, form: Node):
	form.queue_free()
	# Save to disk
	var servers: Array = get_servers()
	servers.append(data)
	save_servers(servers)
	# Add to menu
	var entry := create_server_entry(data)
	entry.get_child(0).grab_focus()
	# Make the "+" button the last child again
	add_server_button.move_to_front()

func _on_ServerList_server_edit(entry: Node):
	var form := preload("res://client/menus/server_list_add_entry.tscn").instantiate()
	form.load(get_servers()[entry.get_index()])
	form.confirmed.connect(_on_ServerList_server_replace.bind(form, entry))
	form.canceled.connect(func():
		form.add_sibling(entry)
		form.queue_free())
	entry.add_sibling(form)
	entry.get_parent().remove_child(entry)

func _on_ServerList_server_replace(data: Dictionary, form: Node, old_entry: Node):
	old_entry.free()
	var servers: Array = get_servers()
	servers[form.get_index()] = data
	save_servers(servers)
	var entry := create_server_entry(data)
	entry.get_parent().move_child(entry, form.get_index())
	entry.get_child(0).grab_focus()
	form.queue_free()

func _on_ServerList_server_delete(entry: Node):
	var idx := entry.get_index()
	entry.get_parent().remove_child(entry)
	entry.queue_free()
	if idx < server_list.get_child_count() - 1:
		server_list.get_child(idx).get_child(0).grab_focus()
	else:
		add_server_button.grab_focus()
	var servers: Array = get_servers()
	servers.remove_at(idx)
	save_servers(servers)

func create_server_entry(data) -> Container:
	var container := HBoxContainer.new()
	var edit := Button.new()
	edit.icon = preload("res://assets/icons/edit.png")
	var delete := Button.new()
	delete.icon = preload("res://assets/icons/delete.png")
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if data is Dictionary:
		button.text = data["display_name"]
		button.pressed.connect(remote_server.bind(data["host"], data["port"]))
	else:
		button.text = data
		button.pressed.connect(remote_server.bind(data, ProjectSettings.get("server/port")))
	edit.pressed.connect(_on_ServerList_server_edit.bind(container))
	delete.pressed.connect(_on_ServerList_server_delete.bind(container))
	container.add_child(button)
	container.add_child(edit)
	container.add_child(delete)
	server_list.add_child(container)
	return container

func remote_server(host: String, port: int) -> void:
	var server := Global.connect_remote_server(host, port)
	if server == null:
		$AcceptDialog.title = "MENU_LABEL_CONNECTION_ERROR"
		$AcceptDialog.dialog_text = "MENU_LABEL_CONNECTION_TIMEOUT"
		$AcceptDialog.popup_centered()
		return
	var conn := server.multiplayer
	conn.connection_failed.connect(_on_connection_failed, CONNECT_DEFERRED)
	conn.connected_to_server.connect(_on_connection_succeeded.bind(server), CONNECT_DEFERRED)
	$LoadAnimation.show()
	$LoadAnimation/Cancel.grab_focus()

func _on_connection_failed():
	$LoadAnimation.hide()
	$AcceptDialog.title = "MENU_LABEL_CONNECTION_ERROR"
	$AcceptDialog.dialog_text = "MENU_LABEL_CONNECTION_TIMEOUT"
	$AcceptDialog.popup_centered()
	get_tree().network_peer.connection_failed.disconnect(_on_connection_failed)
	get_tree().network_peer.connection_succeeded.disconnect(_on_connection_succeeded)
	get_tree().network_peer = null
	Global.shutdown_connection()

func _on_connection_succeeded(server):
	var version = await server.get_version()
	$LoadAnimation.hide()
	if version == null:
		$AcceptDialog.title = "MENU_LABEL_CONNECTION_ERROR_TITLE"
		$AcceptDialog.dialog_text = "MENU_LABEL_NO_SERVER_VERSION"
		$AcceptDialog.popup_centered()
		get_tree().set_multiplayer(null)
		Global.shutdown_connection()
		return
	elif version[0] != Global.PROTOCOL_VERSION:
		$AcceptDialog.title = "MENU_LABEL_VERSION_MISMATCH_TITLE"
		$AcceptDialog.dialog_text = tr("MENU_LABEL_VERSION_MISMATCH").format(
			{
				'local': Global.VERSION_STRING,
				'remote': version[1]
			})
		$AcceptDialog.popup_centered()
		get_tree().set_multiplayer(null)
		Global.shutdown_connection()
		return
	var servermenu = preload("res://client/menus/lobby/servermenu.tscn").instantiate()
	servermenu.server = server
	servermenu.mainmenu = self
	add_child(servermenu)
	$ServerList.hide()
