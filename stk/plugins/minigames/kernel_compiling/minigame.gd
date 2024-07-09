extends Node3D

@onready var num_players = Utility.get_nodes_in_group(self, "players").size()

var lobby: Lobby
var game_ended := false

func _enter_tree() -> void:
	lobby = Lobby.get_lobby(self)

func get_player(i):
	return get_node("Player" + str(i))

func update_progress():
	# In 2v2 mode, players share the same score, therefore we only have to take a look at one Player of each team
	# This is called by player.update_progress() when we're in 2v2 mode
	$Team1Progress/Sprite3D.material_override.set_shader_parameter("percentage", $Player1.get_percentage())
	$Team2Progress/Sprite3D.material_override.set_shader_parameter("percentage", $Player3.get_percentage())

func stop_game():
	game_ended = true
	for i in range(num_players):
		var player = get_player(i + 1)
		player.clear_action()

	$Timer.start()

func _ready():
	match lobby.minigame_state.minigame_type:
		Lobby.MINIGAME_TYPES.DUEL:
			$Player1.position = Vector3(0.3, 0, -1)
			$Player1.rotation_degrees = Vector3(0, -85, 0)
			$Player2.position = Vector3(0.3, 0, 1)
			$Player2.rotation_degrees = Vector3(0, -95, 0)
		Lobby.MINIGAME_TYPES.TWO_VS_TWO:
			$Player1.teammate = $Player2
			$Player2.teammate = $Player1
			$Player3.teammate = $Player4
			$Player4.teammate = $Player3
			$Team1Progress.show()
			$Team2Progress.show()

func _on_Timer_timeout():
	match lobby.minigame_state.minigame_type:
		Lobby.MINIGAME_TYPES.FREE_FOR_ALL, Lobby.MINIGAME_TYPES.DUEL:
			var points = []
			
			for p in Utility.get_nodes_in_group(self, "players"):
				points.append(p.presses)
			
			lobby.minigame_win_by_points(points)
		Lobby.MINIGAME_TYPES.TWO_VS_TWO:
			# Each player in the teams share a score, therefore:
			# $Player1.presses == $Player2.presses and $Player3.presses == $Player4.presses
			# So we only have to check one player per team to determine the winning team
			if $Player1.presses == $Player1.NEEDED_BUTTON_PRESSES:
				lobby.minigame_team_win(0)
			else:
				lobby.minigame_team_win(1)

func _on_Countdown_finish():
	if not multiplayer.is_server():
		return
	for i in range(num_players):
		get_player(i + 1).generate_next_action()
