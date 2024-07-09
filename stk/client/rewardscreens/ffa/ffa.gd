extends "../common.gd"

func setup_scene():
	var i := 0
	var pos := 1
	for p in lobby.minigame_summary.placement:
		for player_id in p:
			i += 1
			var node: Marker3D = get_node("SubViewportContainer/SubViewport/Placement" + str(i))
			load_character(player_id, node, "happy" if pos < 4 else "sad")
			
			var ui_container: Control = node.get_node("VBoxContainer")
			position_beneath(node, ui_container)
			
			ui_container.get_node("ContinueCheck").player_id = player_id
			
			var cookie_text = ui_container.get_node("CookieText")
			cookie_text.total_cookies = lobby.get_playerstate(player_id).cookies
			cookie_text.cookies = lobby.minigame_summary.reward[i - 1]
		pos += len(p)

func _ready():
	setup_scene()
	super._ready()
