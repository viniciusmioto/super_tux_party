@tool
extends PopupPanel

signal selected(item)

func set_options(list: Array):
	list.sort()
	for child in $ScrollContainer/VBoxContainer.get_children():
		$ScrollContainer/VBoxContainer.remove_child(child)
		child.queue_free()
	for item in list:
		var button := Button.new()
		button.text = item
		button.pressed.connect(_on_selected.bind(item))
		$ScrollContainer/VBoxContainer.add_child(button)

func _on_selected(item):
	selected.emit(item)
	hide()

func _on_Close_pressed():
	selected.emit(null)
