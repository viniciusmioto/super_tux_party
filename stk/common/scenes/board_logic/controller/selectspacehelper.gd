extends Node3D

signal space_selected(space)

@onready var controller: Controller = get_parent()

var current_player: PlayerBoard
var selected_space: NodeBoard
var selected_space_distance: int
var select_space_max_distance: int

func _ready():
	set_as_top_level(true)

func get_next_spaces(space: NodeBoard):
	var result = []

	for p in space.next:
		var node: NodeBoard = space.get_node(p)
		if node.is_visible_space():
			result.append(node)
		else:
			result += get_next_spaces(node)

	return result

func get_prev_spaces(space: NodeBoard):
	var result = []

	for p in space.prev:
		var node: NodeBoard = space.get_node(p)
		if node.is_visible_space():
			result.append(node)
		else:
			result += get_prev_spaces(node)

	return result

func select_random_space(space: NodeBoard, max_distance: int) -> NodeBoard:
	# Select random space in front of or behind player
	# Can be the same space as well
	var distance: int = (randi() % (2*max_distance + 1)) - max_distance

	if distance > 0:
		while distance > 0:
			var possible_spaces = get_next_spaces(space)
			if possible_spaces.size() == 0:
				break

			space = possible_spaces[randi() % possible_spaces.size()]
			distance -= 1
	else:
		while distance < 0:
			var possible_spaces = get_prev_spaces(space)
			if possible_spaces.size() == 0:
				break

			space = possible_spaces[randi() % possible_spaces.size()]
			distance += 1
	return space

func select_space(player: PlayerBoard, max_distance: int) -> void:
	if player.info.is_ai():
		var space := select_random_space(player.space, max_distance)

		await get_tree().create_timer(1).timeout
		space_selected.emit(space)
	else:
		current_player = player
		selected_space = player.space
		select_space_max_distance = max_distance
		_client_select_space.rpc_id(player.info.addr.peer_id, player.info.player_id, max_distance)

func get_reachable(space: NodeBoard, distance: int):
	var nodes := []
	var prev := [space]
	var next := [space]
	for i in range(distance):
		var nprev = []
		var nnext = []
		for node in prev:
			nodes.append(node)
			nprev += get_prev_spaces(node)
		for node in next:
			nodes.append(node)
			nnext += get_prev_spaces(node)
		prev = nprev
		next = nnext
	return nodes + prev + next

# Called when player disconnects while waiting for space selection
func end_selection():
	current_player = null
	space_selected.emit(selected_space)

@rpc func _client_select_space(player_id: int, max_distance: int):
		selected_space_distance = 0
		select_space_max_distance = max_distance

		selected_space = controller.players[player_id - 1].space
		show_select_space_arrows()

@rpc("any_peer") func _client_space_selected(path: NodePath):
	if not current_player or multiplayer.get_remote_sender_id() != current_player.info.addr.peer_id:
		return
	var space = get_node(path)
	if not space is NodeBoard or not controller.lobby.is_ancestor_of(space):
		controller.lobby.kick(multiplayer.get_remote_sender_id(), "Misbehaving Client")
		return
	if not space in get_reachable(selected_space, select_space_max_distance):
		controller.lobby.kick(multiplayer.get_remote_sender_id(), "Misbehaving Client")
		return
	current_player = null
	space_selected.emit(space)

func show_select_space_arrows() -> void:
	var keep_arrow = preload(\
			"res://common/scenes/board_logic/node/arrow/arrow_keep.tscn").instantiate()

	keep_arrow.next_node = selected_space
	keep_arrow.position = selected_space.position

	keep_arrow.arrow_activated.connect(_on_select_space_arrow_activated.bind(keep_arrow, 0))

	var arrows := [keep_arrow]
	add_child(keep_arrow)

	var previous = keep_arrow

	if selected_space_distance < select_space_max_distance:
		for node in get_next_spaces(selected_space):
			var arrow = preload("res://common/scenes/board_logic/node/arrow/" +\
					"arrow.tscn").instantiate()
			var dir: Vector3 = node.position - selected_space.position

			dir = dir.normalized()

			arrow.previous_arrow = previous
			previous.next_arrow = arrow

			arrow.next_node = node
			arrow.position = selected_space.position
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)

			arrow.arrow_activated.connect(_on_select_space_arrow_activated.bind(arrow, 1))

			add_child(arrow)
			previous = arrow
			arrows.append(arrow)

	if selected_space_distance > -select_space_max_distance:
		for node in get_prev_spaces(selected_space):
			var arrow = preload("res://common/scenes/board_logic/node/arrow/" +\
					"arrow.tscn").instantiate()
			var dir: Vector3 = node.position - selected_space.position

			dir = dir.normalized()

			arrow.previous_arrow = previous
			previous.next_arrow = arrow

			arrow.next_node = node
			arrow.position = selected_space.position
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)

			arrow.arrow_activated.connect(_on_select_space_arrow_activated.bind(arrow, -1))

			add_child(arrow)
			previous = arrow
			arrows.append(arrow)

	previous.next_arrow = keep_arrow
	keep_arrow.previous_arrow = previous

	keep_arrow.selected = true

	controller.camera_focus = selected_space

func _on_select_space_arrow_activated(arrow, distance: int) -> void:
	if arrow.next_node == selected_space:
		_client_space_selected.rpc_id(1, get_path_to(selected_space))
		return

	selected_space = arrow.next_node
	selected_space_distance += distance

	show_select_space_arrows()
