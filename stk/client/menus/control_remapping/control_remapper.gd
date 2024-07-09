extends Control

const ACTIONS := ["up", "left", "down", "right", "ok", "pause",
		"action1", "action2", "action3", "action4"]

signal quit

var player_id : set = set_player_id

func set_player_id(id: int):
	player_id = id
	
	for action in ACTIONS:
		var node := $PanelContainer/VBoxContainer/Grid/Column1.get_node_or_null(action)
		if not node:
			node = $PanelContainer/VBoxContainer/Grid/Column2.get_node_or_null(action)
		var button := node.get_node("Button")
		button.action = "player{num}_{action}".format({"num": player_id, "action": action})
	
	$Back.grab_focus()

func _on_Back_pressed():
	hide()
	quit.emit()
