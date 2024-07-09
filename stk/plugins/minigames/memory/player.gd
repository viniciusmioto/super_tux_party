extends Node3D

const TEAM_COLORS = [Color.LIGHT_BLUE, Color.LIGHT_CORAL]

var info: Lobby.PlayerInfo
var ai_difficulty: int

@export var idx := 0
@export var row := 1
@export var column := 1
@onready var right_side := column > 4

@export var ally: NodePath

# If the player is currently flipping up a card
# Is true for the entire duration, the card is held open
var blocked := false
# The duration the card has been held open
var holding_card := 0.0

var points := 0: set = set_points

var ai_target_row := -1
var ai_target_column := -1

# Small penalty when flipping up nonmatching pairs
# Includes the time for the flip down animation to complete
var cooldown := 0.0
@onready var team := 0 if info.player_id in info.lobby.minigame_state.minigame_teams[0] else 1

func set_points(num: int):
	points = num

	get_parent().get_node("ScoreOverlay").set_score(info.player_id, num)

func card_at(row: int, column: int) -> Node:
	if row < 0 or column < 0:
		return null

	return get_parent().get_node("Row{0}/{1}".format([row, column]))

func current_card():
	return card_at(row, column)

func random_card(variant: int) -> Array:
	var rand_value
	match ai_difficulty:
		Lobby.Difficulty.EASY:
			rand_value = 6
		Lobby.Difficulty.NORMAL:
			rand_value = 4
		Lobby.Difficulty.HARD:
			rand_value = 1
	# Make the AI fail some times (probability depends on the difficulty)
	if randi() % rand_value != 0:
		variant = -1
	var places = []
	var beginning := 1
	var end := 8
	if right_side:
		beginning = 5
	else:
		end = 4
	for row in range(1, 5):
		for column in range(beginning, end):
			var card = card_at(row, column)
			if not card.faceup and (variant < 0 or card.variant == variant):
				places.push_back([row, column])
	if places.is_empty():
		return [-1, -1]
	return places[randi() % len(places)]

func _ready():
	current_card().show_player(self.idx)

@rpc func card_flipped():
	$Flip.play()

@rpc func point_scored():
	$Point.play()

@rpc("any_peer", "call_local") func activate():
	if blocked or cooldown or multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	if current_card().faceup:
		return

	info.lobby.broadcast(card_flipped)
	blocked = true
	holding_card = 0.0
	var ally_node = get_node(ally)
	# Make the other player choose a new card (when it's an AI)
	ally_node.ai_target_row = -1
	ally_node.ai_target_column = -1
	await current_card().flip_up(TEAM_COLORS[self.team]).animation_finished
	await get_tree().create_timer(0.25).timeout

	if ally_node.blocked:
		var ally_card = ally_node.current_card()
		if ally_card.is_animation_running():
			await ally_card.animation_player().animation_finished
		if ally_card.variant == current_card().variant:
			info.lobby.broadcast(point_scored)
			self.points += 1
		else:
			# wait for the animation to complete
			ally_node.cooldown = 0.5
			cooldown = 0.5
			ally_card.flip_down()
			current_card().flip_down()
		blocked = false
		ally_node.blocked = false
	cooldown = 0.25

func _server_process(delta):
	cooldown = max(0, cooldown - delta)

	# Flip the card facedown when holding for > 5 seconds
	# Prevents deadlock when flipping up the last card pair
	if blocked and not get_node(ally).blocked and holding_card > 5.0:
		blocked = false
		cooldown = 1.0
		current_card().flip_down()
		ai_target_column = -1
		ai_target_row = -1
		return

	if blocked:
		holding_card += delta
		return

	if info.is_ai():
		_process_ai()

func _process_ai():
	if cooldown or blocked:
		return
	info.lobby.broadcast(current_card().hide_player.bind(self.idx))
	var card = card_at(ai_target_row, ai_target_column)
	var ally_node = get_node(ally)
	var variant = -1
	var ally_card = null
	if ally_node.blocked:
		ally_card = ally_node.current_card()
		variant = ally_card.variant
	if not card or card.faceup:
		var random_pos = random_card(variant)
		ai_target_row = random_pos[0]
		ai_target_column = random_pos[1]
	if ai_target_row >= 0 and ai_target_row < row:
		row -= 1
	elif ai_target_row >= 0 and ai_target_row > row:
		row += 1
	elif ai_target_column >= 0 and ai_target_column < column:
		column -= 1
	elif ai_target_column >= 0 and ai_target_column > column:
		column += 1
	else:
		info.lobby.broadcast(current_card().show_player.bind(self.idx))
		activate.rpc_id(1)
		return
	info.lobby.broadcast(current_card().show_player.bind(self.idx))
	cooldown = 0.25

func move(dx: int, dy: int):
	var player = info.lobby.get_player_by_id(info.player_id)
	if multiplayer.get_remote_sender_id() != player.addr.peer_id:
		return
	if cooldown or blocked:
		return
	var beginning := 1
	var end := 7
	if right_side:
		beginning = 5
	else:
		end = 3
	if dx < 0 and column == beginning:
		return
	if dx > 0 and column == end:
		return
	if dy < 0 and row == 1:
		return
	if dy > 0 and row == 4:
		return
	info.lobby.broadcast(current_card().hide_player.bind(self.idx))
	column += dx
	row += dy
	cooldown = 0.1
	info.lobby.broadcast(current_card().show_player.bind(self.idx))

@rpc("any_peer") func move_left():
	if multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	move(-1, 0)

@rpc("any_peer") func move_right():
	if multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	move(1, 0)

@rpc("any_peer") func move_up():
	if multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	move(0, -1)

@rpc("any_peer") func move_down():
	if multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	move(0, 1)

func _input(event: InputEvent):
	if not info.is_local():
		return
	if event.is_action_pressed("player{0}_left".format([info.player_id])):
		move_left.rpc_id(1)
	if event.is_action_pressed("player{0}_right".format([info.player_id])):
		move_right.rpc_id(1)
	if event.is_action_pressed("player{0}_up".format([info.player_id])):
		move_up.rpc_id(1)
	if event.is_action_pressed("player{0}_down".format([info.player_id])):
		move_down.rpc_id(1)
	if event.is_action_pressed("player{0}_action1".format([info.player_id])):
		activate.rpc_id(1)
