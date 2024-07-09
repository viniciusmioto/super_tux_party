extends Node3D

const ACTIONS := ["up", "down", "left", "right", "action1", "action2", "action3", "action4"]

var info: Lobby.PlayerInfo

var ai_wait_time: float

var next_action: String

var disabled_input = false

var teammate: Node

var presses := 0
@onready var NEEDED_BUTTON_PRESSES := 25 if info.lobby.minigame_state.minigame_type != Lobby.MINIGAME_TYPES.TWO_VS_TWO else 50

var AI_MIN_WAIT_TIME: float
var AI_MAX_WAIT_TIME: float

func get_percentage():
	return float(presses) / NEEDED_BUTTON_PRESSES

func disable_input():
	$Wrong.play()
	disabled_input = true
	$PenaltyTimer.start()

func generate_next_action():
	if get_parent().game_ended:
		return
	var action = ACTIONS[randi() % ACTIONS.size()]
	next_action = "player" + str(info.player_id) + "_" + action
	info.lobby.broadcast(set_action.bind(action))

@rpc func set_action(action: String):
	if action == "":
		next_action = ""
		$Screen/ControlView.clear_display()
		return
	if not action in ACTIONS:
		return
	next_action = "player" + str(info.player_id) + "_" + action
	$Screen/ControlView.display_action(next_action)

func clear_action():
	next_action = ""
	info.lobby.broadcast(set_action.bind(""))

func update_progress():
	# If each player has their own progress bar (every mode exect 2v2), then do it locally
	# Otherwise, let the minigame root node handle the combined progress bars for each team
	if info.lobby.minigame_state.minigame_type != Lobby.MINIGAME_TYPES.TWO_VS_TWO:
		$Progress/Sprite3D.material_override.set_shader_parameter("percentage", get_percentage())
	else:
		get_parent().update_progress()

func _ready():
	$Model.jump_to_animation("sit")
	
	if info.lobby.minigame_state.minigame_type == Lobby.MINIGAME_TYPES.TWO_VS_TWO:
		$Screen.position.y -= 0.15
		$Progress.hide()
	
	if info.is_ai():
		match info.ai_difficulty:
			Lobby.Difficulty.EASY:
				AI_MIN_WAIT_TIME = 0.8
				AI_MAX_WAIT_TIME = 1.0
			Lobby.Difficulty.HARD:
				AI_MIN_WAIT_TIME = 0.4
				AI_MAX_WAIT_TIME = 0.6
			_:
				AI_MIN_WAIT_TIME = 0.6
				AI_MAX_WAIT_TIME = 0.8
		
		ai_wait_time = randf_range(AI_MIN_WAIT_TIME, AI_MAX_WAIT_TIME)

func press():
	pressed.rpc_id(1)

@rpc("any_peer", "call_local") func pressed():
	if info.addr.peer_id != multiplayer.get_remote_sender_id():
		return
	if next_action == "":
		return
	presses += 1
	if teammate:
		teammate.presses += 1
	info.lobby.broadcast(_client_pressed)
	clear_action()
	if presses < NEEDED_BUTTON_PRESSES:
		get_tree().create_timer(0.25).timeout.connect(generate_next_action)
	else:
		get_parent().stop_game()

@rpc func _client_pressed():
	presses += 1
	if teammate:
		teammate.presses += 1
	$Correct.play()
	update_progress()

func _server_process(delta):
	if info.is_ai() and next_action and not disabled_input:
		ai_wait_time -= delta
		if ai_wait_time <= 0:
			press()
			ai_wait_time = randf_range(AI_MIN_WAIT_TIME, AI_MAX_WAIT_TIME)

func _input(event):
	if not info.is_local() or info.is_ai():
		return
	if next_action and not disabled_input:
		if event.is_action_pressed(next_action):
			press()
		else:
			# Check if it was another action by that player
			for action in ACTIONS:
				if event.is_action_pressed("player" + str(info.player_id) + "_" + action):
					disable_input()
					$Screen/ControlView.hide()
					$Screen/PenaltySplash.show()
					return

func _on_PenaltyTimer_timeout():
	disabled_input = false
	$Screen/PenaltySplash.hide()
	$Screen/ControlView.show()
