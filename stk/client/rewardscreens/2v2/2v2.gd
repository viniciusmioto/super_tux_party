extends "../common.gd"

func setup_ui(node: Marker3D, player_id: int, pos: int, winner: bool):
	var ui_container = node.get_node("VBoxContainer")
	
	var cookie_text = ui_container.get_node("CookieText")
	var player := lobby.get_playerstate(player_id)
	cookie_text.cookies = lobby.minigame_summary.reward[pos - 1]
	cookie_text.total_cookies = player.cookies
	
	ui_container.get_node("ContinueCheck").player_id = player_id
	
	position_beneath(node, ui_container)
	if winner:
		var winner_text = node.get_node("WinnerText")
		position_above(node, winner_text)
		winner_text.show()

func setup_scene():
	var i := 1
	var placement := 0
	var tie: bool = lobby.minigame_summary.placement == -1
	if not tie:
		placement = lobby.minigame_summary.placement
	# Winning team
	for player_id in lobby.minigame_summary.state.minigame_teams[placement]:
		var node: Marker3D = get_node("SubViewportContainer/SubViewport/Placement" + str(i))
		load_character(player_id, node, "happy" if not tie else "sad")
		
		setup_ui(node, player_id, i, not tie)
		i += 1

	# Loosing team
	for player_id in lobby.minigame_summary.state.minigame_teams[1 - placement]:
		var node: Marker3D = get_node("SubViewportContainer/SubViewport/Placement" + str(i))
		load_character(player_id, node, "sad")
		
		setup_ui(node, player_id, i, false)
		i += 1

func _ready():
	setup_scene()
	super._ready()
