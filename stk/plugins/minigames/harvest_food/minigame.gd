extends Node3D

const Plant := preload("res://plugins/minigames/harvest_food/plant.gd")
const Pumpkin := preload("res://plugins/minigames/harvest_food/pumpkin.gd")
const Player := preload("res://plugins/minigames/harvest_food/player.gd")

const PUMPKIN_MASS: float = 10.0

@onready var plants: Array[Plant] = [
	$Plant1,
	$Plant2,
	$Plant3,
	$Plant4,
	$Plant5,
	$Plant6,
	$Plant7,
	$Plant8,
	$Plant9,
]
var lobby: Lobby

func _enter_tree() -> void:
	self.lobby = Lobby.get_lobby(self)

func _ready():
	var groups := [
		[$Area1, $Player1],
		[$Area2, $Player2],
	]
	plants[0].point_value = 1.0
	plants[0].active = true
	plants[1].point_value = 1.0
	plants[1].active = true
	if lobby.minigame_state.minigame_type != Lobby.MINIGAME_TYPES.DUEL:
		groups.append_array([
			[$Area3, $Player3],
			[$Area4, $Player4]
		])
		plants[2].point_value = 1.0
		plants[2].active = true
		plants[3].point_value = 1.0
		plants[3].active = true
	else:
		$Area3.queue_free()
		$Area4.queue_free()
	
	for nodes in groups:
		# Set up event handler for each plot area
		nodes[0].body_entered.connect(_on_area_body_entered.bind(nodes[1]))
		nodes[0].body_exited.connect(_on_area_body_exited.bind(nodes[1]))
		
		# Show player icon on each plot area
		var material: StandardMaterial3D = nodes[0].get_node(^"MeshInstance3D").get_surface_override_material(0)
		material.albedo_texture = PluginSystem.character_loader.load_character_icon(nodes[1].info.character)
	
	if multiplayer.is_server():
		# Start the game timer on the server
		$Timer.timeout.connect(_on_Timer_timeout)

func _on_Timer_timeout():
	match lobby.minigame_state.minigame_type:
		Lobby.MINIGAME_TYPES.FREE_FOR_ALL:
			lobby.minigame_win_by_points([$Player1.score, $Player2.score, $Player3.score, $Player4.score])
		Lobby.MINIGAME_TYPES.DUEL:
			lobby.minigame_win_by_points([$Player1.score, $Player2.score])
		Lobby.MINIGAME_TYPES.TWO_VS_TWO:
			lobby.minigame_team_win_by_points([$Player1.score + $Player2.score, $Player3.score + $Player4.score])

func _client_process(_delta):
	$Screen/Time.text = "%.1f" % $Timer.time_left

# Guarantees consistent names on the client and the server
var pumpkin_counter := 0
@rpc func _spawn_pumpkin(size: float, special: bool, pos: Vector3, forward: Vector3):
	var p: Pumpkin = preload("res://plugins/minigames/harvest_food/pumpkin.tscn").instantiate()
	add_child(p)
	p.name = "Pumpkin" + str(pumpkin_counter)
	pumpkin_counter += 1
	p.position = pos
	p.linear_velocity = forward * 5 + Vector3(0, 2, 0)
	p.mass = size * PUMPKIN_MASS
	p.point_value = size
	p.special = special

func throw(size: float, special: bool, pos: Vector3, forward: Vector3):
	lobby.broadcast(_spawn_pumpkin.bind(size, special, pos, forward))
	_spawn_pumpkin(size, special, pos, forward)

func grow_new_plant() -> void:
	var valid: Array[Plant] = []
	for plant in plants:
		if not plant.active:
			valid.append(plant)
	var target: Plant = valid.pick_random()
	var special := randf() < 0.1
	lobby.broadcast(target.activate.bind(special))
	target.activate(special)

func get_value(body: Pumpkin) -> float:
	var modifier := 2.0 if body.special else 1.0
	return body.point_value * modifier

func _on_area_body_entered(body: Pumpkin, player: Player) -> void:
	# Collision layers are set up so that only plants are registered
	if not multiplayer.is_server():
		return
	
	player.score += get_value(body)
	$Screen/ScoreOverlay.set_score(player.info.player_id, player.score)

func _on_area_body_exited(body: Pumpkin, player: Player) -> void:
	# Collision layers are set up so that only plants are registered
	if not multiplayer.is_server():
		return
	
	player.score -= get_value(body)
	$Screen/ScoreOverlay.set_score(player.info.player_id, player.score)
