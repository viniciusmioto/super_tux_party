extends "res://common/scenes/sound_button/sound_button.gd"

# The eventname that is remapped through this button
@export var action: String: set = set_action

var is_active := false

func set_action(action_name: String):
	action = action_name
	if action:
		ControlHelper.set_button_to_event(self as Control, InputMap.action_get_events(action)[0])

func _on_control_remap_pressed():
	self.is_active = true
	self.text = "MENU_LABEL_PRESS_ANY_KEY"

# The min value of the axis to get chosen during remap
# prevents choosing the axis with a little value over one with a large value
const JOYPAD_DEADZONE_REMAP = 0.5

func _input(event: InputEvent):
	var valid_type := event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadMotion or event is InputEventJoypadButton
	var mousebutton_pressed_check := ((not event is InputEventMouseButton) or (event as InputEventMouseButton).pressed)
	var joypad_deadzone_check: bool = ((not event is InputEventJoypadMotion) or abs(event.axis_value) >= JOYPAD_DEADZONE_REMAP)
	
	if valid_type and is_active and mousebutton_pressed_check and joypad_deadzone_check:
		get_viewport().set_input_as_handled()
		ControlHelper.set_button_to_event(self as Control, event)
		
		# Remove old keybindings
		for old_event in InputMap.action_get_events(action):
			InputMap.action_erase_event(action, old_event)
		# Add the new key binding
		InputMap.action_add_event(action, event)
		
		ControlHelper.save_controls()
		
		is_active = false
