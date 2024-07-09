extends Control

signal item_selected(idx)

func select_item(player) -> void:
	var i := 0
	while i < len(player.items):
		var node := get_node("Item%d" % (i + 1))
		var item: Item = player.items[i]
		node.texture_normal = item.icon

		if node.focus_entered.is_connected(_on_focus_entered):
			node.focus_entered.disconnect(_on_focus_entered)
		if node.focus_exited.is_connected(_on_focus_exited):
			node.focus_exited.disconnect(_on_focus_exited)
		if node.mouse_entered.is_connected(_on_mouse_entered):
			node.mouse_entered.disconnect(_on_mouse_entered)
		if node.mouse_exited.is_connected(_on_mouse_exited):
			node.mouse_exited.disconnect(_on_mouse_exited)
		if node.pressed.is_connected(_on_item_select):
			node.pressed.disconnect(_on_item_select)

		node.focus_entered.connect(_on_focus_entered.bind(node))
		node.focus_exited.connect(_on_focus_exited.bind(node))
		node.mouse_entered.connect(_on_mouse_entered.bind(node))
		node.mouse_exited.connect(_on_mouse_exited.bind(node))
		node.pressed.connect(_on_item_select.bind(i))

		node.material.set_shader_parameter("enable_shader", false)

		i += 1

	# Clear all remaining item slots.
	while i < player.MAX_ITEMS:
		var node = get_node("Item%d" % (i + 1))
		node.texture_normal = null

		if node.focus_entered.is_connected(_on_focus_entered):
			node.focus_entered.disconnect(_on_focus_entered)
		if node.focus_exited.is_connected(_on_focus_exited):
			node.focus_exited.disconnect(_on_focus_exited)
		if node.mouse_entered.is_connected(_on_mouse_entered):
			node.mouse_entered.disconnect(_on_mouse_entered)
		if node.mouse_exited.is_connected(_on_mouse_exited):
			node.mouse_exited.disconnect(_on_mouse_exited)
		if node.pressed.is_connected(_on_item_select):
			node.pressed.disconnect(_on_item_select)

		node.material.set_shader_parameter("enable_shader", false)

		i += 1

	show()
	$Item1.grab_focus()

func _on_item_select(idx) -> void:
	# Reset the state.
	hide()

	# Continue execution.
	item_selected.emit(idx)

func _on_focus_entered(button) -> void:
	button.material.set_shader_parameter("enable_shader", true)

func _on_focus_exited(button) -> void:
	button.material.set_shader_parameter("enable_shader", false)

func _on_mouse_entered(button) -> void:
	button.material.set_shader_parameter("enable_shader", true)

func _on_mouse_exited(button) -> void:
	if not button.has_focus():
		button.material.set_shader_parameter("enable_shader", false)
