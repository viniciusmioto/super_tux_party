extends Control

signal add_player(idx)

var available: Array

func _ready():
	for i in available:
		var node := get_node("HBoxContainer/Player" + str(i + 1))
		node.display_action("player{0}_action1".format([i + 1]))
		node.show()
	for child in get_children():
		if not child.visible:
			child.queue_free()

func _unhandled_input(event: InputEvent):
	for i in range(4):
		if event.is_action_pressed("player{0}_action1".format([i + 1])):
			add_player.emit(i)
