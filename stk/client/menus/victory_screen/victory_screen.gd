extends Node3D

signal return_to_menu

func _input(event):
	if event.is_action_pressed("player1_ok"):
		return_to_menu.emit()

func _ready():
	var lobby := Lobby.get_lobby(self)
	for player in lobby.playerstates:
		var new_model = PluginSystem.character_loader.load_character(player.info.character)
		new_model.name = "Model"
		
		var i = player.info.player_id
		get_node("Player" + str(i)).add_child(new_model)
		
		$Summary/Stats/Names/Entries.get_node("Player" + str(i)).text = player.info.name
		$Summary/Stats/Cakes/Entries.get_node("Player" + str(i)).text = str(player.cakes)
		$Summary/Stats/Cookies/Entries.get_node("Player" + str(i)).text = str(player.cookies)
	
	$Player1/Model.play_animation("happy")
	$Player2/Model.play_animation("happy")
	$Player3/Model.play_animation("happy")
	$Player4/Model.play_animation("happy")
	
	var winner = []
	for player in lobby.playerstates:
		if not winner or (winner[0].cakes < player.cakes or (winner[0].cakes == player.cakes and winner[0].cookies < player.cookies)):
			winner = [player]
		elif winner and winner[0].cakes == player.cakes and winner[0].cookies == player.cookies:
			winner.append(player)
	
	var winner_names = []
	for w in winner:
		winner_names.append(w.info.name)
	
	await get_tree().create_timer(1).timeout
	
	$Scene/AnimationPlayer.play("KeyAction")
	
	await get_tree().create_timer(2).timeout
	
	var sara_tex = "res://common/scenes/board_logic/controller/icons/sara.png"
	$SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, "CONTEXT_WINNER_ANNOUNCEMENT", 1)
	await $SpeechDialog.dialog_finished
	
	$AudioStreamPlayer2/AnimationPlayer.play("fade_out")
	await get_tree().create_timer(1).timeout
	$AudioStreamPlayer.play()
	
	var pos = Vector3(-(len(winner) - 1) / 2.0, 0, 2)
	for w in winner:
		var player = get_node("Player" + str(w.info.player_id))
		player.destination = pos
		player.get_node("Model").play_animation("run")
		pos.x += 1.0
	
	match len(winner):
		1: $SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, "CONTEXT_WINNER_REVEAL_ONE_PLAYER", 1, winner_names)
		2: $SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, "CONTEXT_WINNER_REVEAL_TWO_PLAYER", 1, winner_names)
		3: $SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, "CONTEXT_WINNER_REVEAL_THREE_PLAYER", 1, winner_names)
		4: $SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, "CONTEXT_WINNER_REVEAL_FOUR_PLAYER", 1, winner_names)
	$CameraMovement.play("closeup")
	
	await $SpeechDialog.dialog_finished
	$Summary.show()
	
	await self.return_to_menu
	
	lobby.end()
