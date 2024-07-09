extends "../common.gd"

func setup_scene():
	var i := 1
	var placement: int = lobby.minigame_summary.placement
	for team_id in range(len(lobby.minigame_summary.state.minigame_teams)):
		for player_id in lobby.minigame_summary.state.minigame_teams[team_id]:
			var node: Marker3D = get_node("SubViewportContainer/SubViewport/Placement" + str(i))
			load_character(player_id, node, "happy" if placement == team_id else "sad")
			
			var ui_container = node.get_node("VBoxContainer")
			ui_container.get_node("ContinueCheck").player_id = player_id
			var cookie_text = ui_container.get_node("CookieText")
			cookie_text.total_cookies = lobby.get_playerstate(player_id).cookies
			if placement == team_id:
				cookie_text.cookies = 10 if placement == 1 else 5
				var winner_text = node.get_node("WinnerText")
				position_above(node, winner_text)
				winner_text.show()
			position_beneath(node, ui_container)
			i += 1

func _ready():
	setup_scene()
	super._ready()
