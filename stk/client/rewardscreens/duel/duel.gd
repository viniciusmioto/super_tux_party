extends "../common.gd"

func setup_scene():
	var i := 0
	var is_tie: bool = len(lobby.minigame_summary.placement) == 1
	for p in lobby.minigame_summary.placement:
		for player_id in p:
			i += 1
			var node: Marker3D = get_node("SubViewportContainer/SubViewport/Placement" + str(i))
			load_character(player_id, node, "happy" if i == 1 and not is_tie else "sad")
			
			var ui_container: Control = node.get_node("VBoxContainer")
			ui_container.get_node("ContinueCheck").player_id = player_id
			var cookie_text = ui_container.get_node("CookieText")
			match lobby.minigame_reward.duel_reward:
				lobby.MINIGAME_DUEL_REWARDS.ONE_CAKE:
					cookie_text.icon = preload("res://common/scenes/board_logic/controller/icons/cake.png")
					cookie_text.total_cookies = lobby.get_playerstate(player_id).cakes
				lobby.MINIGAME_DUEL_REWARDS.TEN_COOKIES:
					cookie_text.total_cookies = lobby.get_playerstate(player_id).cookies
				_:
					@warning_ignore("assert_always_false")
					assert(false, "Invalid duel reward: {0}".format([lobby.minigame_reward.duel_reward]))
			position_beneath(node, ui_container)
			if not is_tie:
				if i == 1:
					cookie_text.cookies = lobby.minigame_summary.reward
				else:
					cookie_text.cookies = -lobby.minigame_summary.reward
	if not is_tie:
		position_above($SubViewportContainer/SubViewport/Placement1, $SubViewportContainer/SubViewport/Placement1/WinnerText)
	else:
		$SubViewportContainer/SubViewport/Placement1/WinnerText.hide()

func _ready():
	setup_scene()
	super._ready()
