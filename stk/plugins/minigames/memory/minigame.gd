extends Node3D

var started := false
var finished := false

var lobby: Lobby

func _enter_tree() -> void:
	lobby = Lobby.get_lobby(self)

func card_at(row: int, column: int) -> Node:
	return get_node("Row{0}/{1}".format([row, column]))

func _ready():
	if not is_multiplayer_authority():
		return
	$Player1.blocked = true
	$Player2.blocked = true
	$Player3.blocked = true
	$Player4.blocked = true

	var variants := [1, 2, 3, 4]

	var places_left := [
		$"Row1/1",
		$"Row1/2",
		$"Row1/3",
		$"Row2/1",
		$"Row2/2",
		$"Row2/3",
		$"Row3/1",
		$"Row3/2",
		$"Row3/3",
		$"Row4/1",
		$"Row4/2",
		$"Row4/3",
	]
	var places_right := [
		$"Row1/5",
		$"Row1/6",
		$"Row1/7",
		$"Row2/5",
		$"Row2/6",
		$"Row2/7",
		$"Row3/5",
		$"Row3/6",
		$"Row3/7",
		$"Row4/5",
		$"Row4/6",
		$"Row4/7",
	]
	places_left.shuffle()
	places_right.shuffle()

	while not places_left.is_empty() and not places_right.is_empty():
		var variant = variants[randi() % len(variants)]
		places_left.pop_back().variant = variant
		places_right.pop_back().variant = variant
	
	var data = [[], [], [], []]
	for i in range(6):
		data[0].append($Row1.get_child(i).variant)
		data[1].append($Row2.get_child(i).variant)
		data[2].append($Row3.get_child(i).variant)
		data[3].append($Row4.get_child(i).variant)
	lobby.broadcast(load_cards.bind(data))

	for i in range(6):
		$Row1.get_child(i).flip_up()
		$Row2.get_child(i).flip_up()
		$Row3.get_child(i).flip_up()
		$Row4.get_child(i).flip_up()
		await get_tree().create_timer(0.1).timeout

	await get_tree().create_timer(2).timeout
	for i in range(6):
		$Row1.get_child(i).flip_down()
		$Row2.get_child(i).flip_down()
		$Row3.get_child(i).flip_down()
		$Row4.get_child(i).flip_down()
		await get_tree().create_timer(0.1).timeout

	await get_tree().create_timer(0.5).timeout

	$Player1.blocked = false
	$Player2.blocked = false
	$Player3.blocked = false
	$Player4.blocked = false
	started = true

@rpc func load_cards(data):
	for i in range(6):
		if not is_multiplayer_authority():
			$Row1.get_child(i).variant = data[0][i]
			$Row2.get_child(i).variant = data[1][i]
			$Row3.get_child(i).variant = data[2][i]
			$Row4.get_child(i).variant = data[3][i]

func _process(_delta):
	if not started:
		return
	
	var unmatched := 0
	var players = [$Player1, $Player2, $Player3, $Player4]
	for player in players:
		# If the player is holding a card open, then it's not yet matched
		# But it also isn't facedown anymore
		if player.blocked:
			unmatched += 1
	for row in range(1, 5):
		for column in range(1, 8):
			if column == 4:
				continue
			var card = card_at(row, column)
			if not card.faceup or card.is_animation_running():
				unmatched += 1
	if not unmatched and not finished:
		$Timer.start()
		finished = true

func _on_Timer_timeout():
	var team1 = $Player1.points + $Player2.points
	var team2 = $Player3.points + $Player4.points
	lobby.minigame_team_win_by_points([team1, team2])
