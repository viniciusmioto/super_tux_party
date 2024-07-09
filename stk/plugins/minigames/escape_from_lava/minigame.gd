extends Node3D

const LAVA_RISE_SPEED = 0.25

# Player Ids that reached the finish line
var winners = []
# Player Ids that got knocked out by the lava
var dead = []

@onready var player_count := len(Utility.get_nodes_in_group(self, "players"))
@onready var lobby := Lobby.get_lobby(self)

func process_stage(stage):
	var index = (randi() % stage.get_child_count())
	stage.get_child(index).can_be_opened = false

func _ready():
	if multiplayer.is_server():
		_do_server_setup()

func _do_server_setup():
	process_stage($Stage1)
	process_stage($Stage2)
	process_stage($Stage3)

func _client_process(delta):
	var min_progress = null
	
	for player in Utility.get_nodes_in_group(self, "players"):
		if not player.is_dead() and (min_progress == null or player.position.z < min_progress.z):
			min_progress = player.position
	
	if min_progress != null:
		$Camera3D.position +=  (Vector3(0, min_progress.y, min_progress.z) + Vector3(0, 3, -4) - $Camera3D.position) * delta

func _server_process(delta):
	$Lava.position += Vector3(0, 1, 0) * delta * LAVA_RISE_SPEED
	lobby.broadcast(set_lava_height.bind($Lava.position.y))

@rpc func set_lava_height(height: float):
	$Lava.position.y = height

func _on_Lava_body_entered(body):
	if not is_multiplayer_authority():
		return
	
	if body.is_in_group("players"):
		if not body.is_dead():
			body.die()
			
			dead.push_front(body.info.player_id)
			
			check_game_over()
	elif body.is_in_group("door"):
		body.destroy()


func _on_Finish_body_entered(body):
	if not is_multiplayer_authority():
		return
	
	if body.is_in_group("players") and not body.is_dead():
		winners.push_back(body.info.player_id)
		body.die()
		check_game_over()

func check_game_over():
	# There is at most one surviving player
	if len(winners) + len(dead) >= player_count - 1:
		var count = 0
		# Find the remaining player if any and declare them as winner
		for node in Utility.get_nodes_in_group(self, "players"):
			if not node.is_dead():
				winners.push_back(node.info.player_id)
				count += 1
				node.die()
		# Assert that we did not fuck up somewhere
		assert(count <= 1)
		lobby.broadcast(end_game)
		$EndTimer.start()

@rpc func end_game():
	$Screen/Label.show()

func _on_EndTimer_timeout():
	if lobby.minigame_state.minigame_type == lobby.MINIGAME_TYPES.DUEL or lobby.minigame_state.minigame_type == lobby.MINIGAME_TYPES.FREE_FOR_ALL:
		lobby.minigame_win_by_position(winners + dead)
	else:
		lobby.minigame_team_win_by_player((winners + dead)[0])
