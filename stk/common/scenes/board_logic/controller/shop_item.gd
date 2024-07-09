extends VBoxContainer

signal item_bought(player, idx, item)
signal show_description(text)

const CANT_BUY_COLOR := Color(1, 0, 0)
const CAN_BUY_COLOR := Color(1, 1, 1)

var player: PlayerBoard
var idx: int
var item: String: set = set_item
var instance: Item

func set_item(i: String):
	item = i
	if not i.is_empty():
		instance = load(i).new()

		$Image.texture_normal = instance.icon
		$Cost/Amount.text = str(instance.item_cost)
		if player.cookies < instance.item_cost:
			$Cost/Amount.add_theme_color_override("font_color", CANT_BUY_COLOR)
		else:
			$Cost/Amount.add_theme_color_override("font_color", CAN_BUY_COLOR)
	else:
		$Image.texture_normal = null
		$Cost/Amount.text = ""
	$Image.material.set_shader_parameter("enable_shader", false)

func select():
	$Image.grab_focus()

func update_description():
	show_description.emit(instance.get_description())

func _on_pressed():
	item_bought.emit(player, self.idx, instance)

func _on_focus_entered() -> void:
	$Image.material.set_shader_parameter("enable_shader", true)
	show_description.emit(instance.get_description())
	get_parent().get_parent().selected_item = self

func _on_focus_exited() -> void:
	$Image.material.set_shader_parameter("enable_shader", false)

func _on_mouse_entered() -> void:
	$Image.material.set_shader_parameter("enable_shader", true)
	select()

func _on_mouse_exited() -> void:
	if not $Image.has_focus():
		$Image.material.set_shader_parameter("enable_shader", false)
