extends PopupPanel

@export var can_save_game := false

var player_id := 0
var paused := false

var was_already_paused: bool

func _ready() -> void:
	if not can_save_game:
		$Container/SaveGame.hide()
	get_tree().root.size_changed.connect(_fix_size)
	popup_window = false
	$OptionsWindow.popup_window = false
	$OptionsWindow.size = get_tree().root.size

func pause() -> void:
	UISound.stream = preload("res://assets/sounds/ui/rollover2.wav")
	UISound.play()
	popup_centered.call_deferred()
	was_already_paused = get_tree().paused
	paused = true
	if Global.is_local_multiplayer():
		get_tree().paused = true

func unpause() -> void:
	hide()
	if Global.is_local_multiplayer():
		get_tree().paused = was_already_paused
	paused = false
	was_already_paused = false

func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT and\
			Global.pause_window_unfocus and not paused:
		player_id = 1
		pause()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("player1_pause"):
		if visible:
			unpause()
		else:
			player_id = 1
			pause()
	else:
		for i in range(2, 5):
			if event.is_action_pressed("player" + var_to_str(i) + "_pause"):
				if visible:
					if player_id == i:
						unpause()
				else:
					player_id = i
					pause()

func _save_game(save_name: String) -> void:
	if save_name == "":
		return

	if Global.savegame_loader.savegames.has(save_name):
		$OverrideSave.popup_centered()
		return
	var lobby := Lobby.get_lobby(self)
	lobby.savegame_name = save_name
	lobby.save_game()

	$SavegameNameInput.hide()
	_on_Resume_pressed()

func _on_Resume_pressed() -> void:
	unpause()

func _on_ExitMenu_pressed() -> void:
	unpause()
	Global.call_deferred("shutdown_connection")
	get_tree().change_scene_to_file("res://client/menus/main_menu.tscn")

func _on_ExitDesktop_pressed() -> void:
	get_tree().quit()

func _on_SaveGame_pressed() -> void:
	var lobby := Lobby.get_lobby(self)
	if lobby.is_new_savegame:
		$SavegameNameInput.popup_centered()
		$SavegameNameInput/VBoxContainer/LineEdit.grab_focus()
	else:
		lobby.save_game()
		await lobby.savegame_saved
		_on_Resume_pressed()

func _on_Savegame_LineEdit_text_changed(new_text) -> void:
	$SavegameNameInput/VBoxContainer/Button.disabled = new_text.is_empty()

func _on_Savegame_Button_pressed() -> void:
	_save_game($SavegameNameInput/VBoxContainer/LineEdit.text)

func _on_OverrideSave_confirmed() -> void:
	var lobby := Lobby.get_lobby(self)
	lobby.save_game()
	$SavegameNameInput.hide()
	await Lobby.get_lobby(self).savegame_saved
	_on_Resume_pressed()

func _on_Options_pressed() -> void:
	$OptionsWindow.popup()

func _on_OptionsMenu_quit() -> void:
	$OptionsWindow.hide()

func _fix_size() -> void:
	$OptionsWindow.size = get_tree().root.size
	#if visible:
	#	hide()
	#	popup_centered()
