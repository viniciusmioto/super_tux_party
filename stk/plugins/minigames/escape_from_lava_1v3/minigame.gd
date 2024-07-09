extends "res://plugins/minigames/escape_from_lava/minigame.gd"

var num_players_alive = 4

@onready var stages = [$Stage1, $Stage2, $Stage3]
var current_stage = -1
var has_chosen = false

func _ready():
	if multiplayer.is_server():
		enter_stage($Player1, 0)

func _do_server_setup():
	# Prevent door locking in parent
	pass

func close_door(index):
	if current_stage < stages.size() and not has_chosen and index < stages[current_stage].get_child_count() and index >= 0:
		stages[current_stage].get_child(index).can_be_opened = false
		has_chosen = true
		lobby.broadcast(door_closed.bind(index))

@rpc func door_closed(index):
	if current_stage < stages.size() and not has_chosen and index < stages[current_stage].get_child_count() and index >= 0:
		stages[current_stage].get_child(index).can_be_opened = false
		$Screen/ControlView2D.clear_display()
		$Screen/ControlView2D2.clear_display()
		$Screen/ControlView2D3.clear_display()

func enter_stage(body, new_stage):
	if not body.is_in_group("players") or not multiplayer.is_server():
		return
	
	if new_stage > current_stage:
		current_stage = new_stage
		has_chosen = false
		
		if current_stage < stages.size():
			if $Player4.info.is_local():
				$Player4.process_next_stage()
			
			$Screen/ControlView2D.display_action("player%d_action1" % $Player4.info.player_id)
			$Screen/ControlView2D2.display_action("player%d_action2" % $Player4.info.player_id)
			$Screen/ControlView2D3.display_action("player%d_action3" % $Player4.info.player_id)

func _on_Lava_body_entered(body):
	if not is_multiplayer_authority():
		return
	if body.is_in_group("players"):
		if not body.is_dead():
			body.die()
			num_players_alive -= 1
			
			if num_players_alive == 1:
				$EndTimer.start()
				lobby.broadcast(end_game)
	elif body.is_in_group("door"):
		body.destroy()

func _on_Finish_body_entered(body):
	if not is_multiplayer_authority():
		return
	if body.is_in_group("players"):
		body.die()
		winners.append(body)
		
		$EndTimer.start()
		lobby.broadcast(end_game)

@rpc func end_game():
	$Screen/Label.show()

func _on_EndTimer_timeout():
	if not winners.is_empty():
		lobby.minigame_1v3_win_team_players()
	else:
		lobby.minigame_1v3_win_solo_player()
