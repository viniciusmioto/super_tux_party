extends "../common.gd"

func setup_scene():
	var node = $SubViewportContainer/SubViewport/Placement
	var player_id = lobby.minigame_summary.state.minigame_teams[0][0]
	var cakes = lobby.minigame_summary.reward
	if lobby.minigame_summary.placement:
		load_character(player_id, node, "happy")
	else:
		load_character(player_id, node, "sad")
		$SubViewportContainer/SubViewport/Placement/WinnerText.hide()
	
	var ui_container: Control = node.get_node("VBoxContainer")
	ui_container.get_node("ContinueCheck").player_id = player_id
	var cookie_text = ui_container.get_node("CookieText")
	cookie_text.total_cookies = lobby.get_playerstate(player_id).cakes
	cookie_text.cookies = -cakes
	
	# We need to wait for a frame update so that the size change reflects our changes
	position_beneath.call_deferred(node, ui_container)
	position_above(node, $SubViewportContainer/SubViewport/Placement/WinnerText)

func _ready():
	setup_scene()
	super._ready()
	if not lobby.minigame_summary.placement and not multiplayer.is_server():
		$Background/AudioStreamPlayer.stream = preload("res://assets/sounds/minigame_end_screen/stuxparty_lossjingle.ogg")
