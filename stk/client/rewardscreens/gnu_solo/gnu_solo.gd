extends "../common.gd"

func setup_scene():
	var node = $SubViewportContainer/SubViewport/Placement
	var player_id = lobby.minigame_summary.state.minigame_teams[0][0]
	var ui_container: Control = node.get_node("VBoxContainer")
	ui_container.get_node("ContinueCheck").player_id = player_id
	if lobby.minigame_summary.placement:
		load_character(player_id, node, "happy")
		ui_container.get_node("Item/Icon").texture = Item.deserialize(lobby.minigame_summary.reward).icon
		ui_container.get_node("Item/Label").show()
		ui_container.get_node("Item/Icon").show()
	else:
		load_character(player_id, node, "sad")
		$SubViewportContainer/SubViewport/Placement/WinnerText.hide()
	
	# We need to wait for a frame update so that the size change reflects our changes
	position_beneath.call_deferred(node, ui_container)
	position_above(node, $SubViewportContainer/SubViewport/Placement/WinnerText)

func _ready():
	setup_scene()
	super._ready()
	if not lobby.minigame_summary.placement and not multiplayer.is_server():
		$Background/AudioStreamPlayer.stream = preload("res://assets/sounds/minigame_end_screen/stuxparty_lossjingle.ogg")
