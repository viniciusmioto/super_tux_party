extends "res://plugins/minigames/escape_from_lava/player.gd"

@export var is_solo_player: bool

func _ready():
	super._ready()
	if is_solo_player:
		remove_from_group("players")

func _process(delta):
	if not info.is_local() or state == STATE.DEAD:
		return
	if not is_solo_player:
		# Call the process implementation from the superclass
		# This takes care of stuff like moving around and AI pathfinding
		super._process(delta)

func process_next_stage():
	if info.is_ai():
		$Timer.start()

func _unhandled_input(event):
	if not info.is_local():
		return
	if is_solo_player:
		if event.is_action_pressed("player%d_action1" % info.player_id):
			rpc_id(1, "close_door", 0)
		elif event.is_action_pressed("player%d_action2" % info.player_id):
			rpc_id(1, "close_door", 1)
		elif event.is_action_pressed("player%d_action3" % info.player_id):
			rpc_id(1, "close_door", 2)

@rpc("any_peer", "call_local") func close_door(idx: int):
	# only relevant for the server
	if multiplayer.get_unique_id() != 1:
		return
	if multiplayer.get_remote_sender_id() != info.addr.peer_id:
		return
	
	get_parent().close_door(idx)

func _on_Timer_timeout():
	close_door.rpc_id(1, randi() % 3)
