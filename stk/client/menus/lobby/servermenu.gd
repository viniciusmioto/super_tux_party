extends Control

var lobby_menu
var server
var mainmenu

func _ready():
	server.public_lobbies.connect(_on_public_lobbies_updated)
	$VBoxContainer/Footer/Create.grab_focus()
	refresh()
	
	if server.current_lobby:
		lobby_joined(server.current_lobby)
		server.current_lobby.refresh()

func refresh() -> void:
	if is_instance_valid(server):
		server.update_lobbies()
	else:
		mainmenu.get_node("MainMenu").show()
		if lobby_menu:
			lobby_menu.queue_free()
		queue_free()

func _on_public_lobbies_updated(list):
	for child in $VBoxContainer/ScrollContainer/List.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	for entry in list:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(self._on_join_lobby.bind(entry[0]))
		$VBoxContainer/ScrollContainer/List.add_child(button)

func _on_join_lobby(id: String) -> void:
	var lobby = await server.join_lobby(id)
	lobby_joined(lobby)

func lobby_joined(lobby: Lobby):
	lobby_menu = preload("res://client/menus/lobby/lobby_menu.tscn").instantiate()
	lobby_menu.lobby = lobby
	lobby_menu.mainmenu = mainmenu
	lobby_menu.servermenu = self
	get_parent().add_child(lobby_menu)
	hide()

func _on_lobby_create() -> void:
	var lobby = await server.create_lobby()
	if lobby:
		lobby_menu = preload("res://client/menus/lobby/lobby_menu.tscn").instantiate()
		lobby_menu.lobby = lobby
		lobby_menu.mainmenu = mainmenu
		lobby_menu.servermenu = self
		get_parent().add_child(lobby_menu)
		hide()

func _on_Leave_pressed() -> void:
	mainmenu.get_node("MainMenu").show()
	queue_free()

func _on_Join_pressed() -> void:
	var lobby = await server.join_lobby($VBoxContainer/Footer/HBoxContainer/LineEdit.text)
	if lobby:
		lobby_menu = preload("res://client/menus/lobby/lobby_menu.tscn").instantiate()
		lobby_menu.lobby = lobby
		lobby_menu.mainmenu = mainmenu
		lobby_menu.servermenu = self
		get_parent().add_child(lobby_menu)
		hide()
