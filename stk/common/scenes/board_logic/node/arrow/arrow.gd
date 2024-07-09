extends Node3D
class_name Arrow

signal arrow_activated

var next_node: NodeBoard

var next_arrow: Arrow = null
var previous_arrow: Arrow = null

var selected := false: set = set_selected

func set_selected(enable):
	selected = enable
	
	if selected:
		$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
		add_to_group("selected_arrow")
	else:
		$Sprite2D.modulate = Color(1.0, 0.5, 0.5, 0.3)
		remove_from_group("selected_arrow")

func _on_Arrow_mouse_entered():
	# Unselect the current selected arrow
	var arrow := next_arrow
	while arrow != self:
		arrow.selected = false
		arrow = arrow.next_arrow
	
	self.selected = true

func _on_Arrow_input_event(_camera, event, _click_position, _click_normal, _shape_idx):
	if event.is_action_pressed("left_mouse_pressed"):
		pressed()

func _unhandled_input(event):
	if selected:
		if event.is_action_pressed("ui_accept"):
			pressed()
			# Prevents duplicate activation 
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			self.selected = false
			previous_arrow.selected = true
			# Prevents the next arrow from acting on this input too
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			self.selected = false
			next_arrow.selected = true
			# Prevents the next arrow from acting on this input too
			get_viewport().set_input_as_handled()

func pressed():
	var next := next_arrow
	while next != self:
		next.queue_free()
		next = next.next_arrow
	queue_free()
	
	arrow_activated.emit()
