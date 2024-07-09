extends Node

const USER_CONFIG_FILE := "user://controls.cfg"

func _init():
	load_controls()

func valid(action_name: String) -> bool:
	return action_name.begins_with("player") or action_name == "debug" or action_name == "screenshot"

# Taken and adapted from the Godot demos
func load_controls():
	var config = ConfigFile.new()
	var err = config.load(USER_CONFIG_FILE)
	if err: # ConfigFile probably not present, create it
		save_controls()
	else: # ConfigFile was properly loaded, initialize InputMap
		for action_name in InputMap.get_actions():
			if not valid(action_name) or not config.has_section_key("input", action_name):
				continue
			
			# Get the key scancode corresponding to the saved human-readable string
			var entry = config.get_value("input", action_name)
			
			entry = entry.split(" ", false)
			var event: InputEvent
			# Each entry is as follows [0: "device (int)", 1: "type (string)", ...]
			match entry[1]:
				"Keyboard":
					event = InputEventKey.new()
					event.keycode = int(entry[2])
					event.pressed = true
				"Mouse":
					event = InputEventMouseButton.new()
					event.button_index = int(entry[2])
					event.pressed = true
				"JoypadAxis":
					event = InputEventJoypadMotion.new()
					event.axis = int(entry[2])
					event.axis_value = sign(float(entry[3]))
				"JoypadButton":
					event = InputEventJoypadButton.new()
					event.button_index = int(entry[2])
					event.pressed = true
				_:
					# Skip invalid action
					push_warning("Invalid control mapping for {0}: {1}".format([action_name, event]))
					continue
			
			event.device = int(entry[0])
			
			# Replace old action (key) events by the new one
			for old_event in InputMap.action_get_events(action_name):
				InputMap.action_erase_event(action_name, old_event)
			InputMap.action_add_event(action_name, event)

# Taken and adapted from the godot demos
func save_controls():
	var config = ConfigFile.new()

	for action_name in InputMap.get_actions():
		if action_name.substr(0, 3) == "ui_":
			continue
		
		var event = InputMap.action_get_events(action_name)[0]
		
		# Each entry is as follows [0: "device (int)", 1: "type (string)", ...]
		var value = str(event.device)
		if event is InputEventKey:
			value += " Keyboard " + str(event.keycode)
		elif event is InputEventMouseButton:
			value += " Mouse " + str(event.button_index)
		elif event is InputEventJoypadMotion:
			value += " JoypadAxis " + str(event.axis) + " " + str(sign(event.axis_value))
		elif event is InputEventJoypadButton:
			value += " JoypadButton " + str(event.button_index)
		
		config.set_value("input", action_name, value)
	config.save(USER_CONFIG_FILE)

func get_from_key(event: InputEventKey):
	match event.keycode:
		KEY_UP:
			return load("res://assets/textures/controls/keyboard/up.png")
		KEY_LEFT:
			return load("res://assets/textures/controls/keyboard/left.png")
		KEY_DOWN:
			return load("res://assets/textures/controls/keyboard/down.png")
		KEY_RIGHT:
			return load("res://assets/textures/controls/keyboard/right.png")
		KEY_ALT:
			return load("res://assets/textures/controls/keyboard/alt.png")
		KEY_CAPSLOCK:
			return load("res://assets/textures/controls/keyboard/caps.png")
		KEY_CTRL:
			return load("res://assets/textures/controls/keyboard/control.png")
		KEY_ENTER:
			return load("res://assets/textures/controls/keyboard/enter.png")
		KEY_ESCAPE:
			return load("res://assets/textures/controls/keyboard/escape.png")
		KEY_KP_0:
			return load("res://assets/textures/controls/keyboard/kp_0.png")
		KEY_KP_1:
			return load("res://assets/textures/controls/keyboard/kp_1.png")
		KEY_KP_2:
			return load("res://assets/textures/controls/keyboard/kp_2.png")
		KEY_KP_3:
			return load("res://assets/textures/controls/keyboard/kp_3.png")
		KEY_KP_4:
			return load("res://assets/textures/controls/keyboard/kp_4.png")
		KEY_KP_5:
			return load("res://assets/textures/controls/keyboard/kp_5.png")
		KEY_KP_6:
			return load("res://assets/textures/controls/keyboard/kp_6.png")
		KEY_KP_7:
			return load("res://assets/textures/controls/keyboard/kp_7.png")
		KEY_KP_8:
			return load("res://assets/textures/controls/keyboard/kp_8.png")
		KEY_KP_9:
			return load("res://assets/textures/controls/keyboard/kp_9.png")
		KEY_KP_MULTIPLY:
			return load("res://assets/textures/controls/keyboard/kp_asterisk.png")
		KEY_KP_ENTER:
			return load("res://assets/textures/controls/keyboard/kp_enter.png")
		KEY_KP_SUBTRACT:
			return load("res://assets/textures/controls/keyboard/kp_minus.png")
		KEY_KP_PERIOD:
			return load("res://assets/textures/controls/keyboard/kp_period.png")
		KEY_KP_ADD:
			return load("res://assets/textures/controls/keyboard/kp_plus.png")
		KEY_KP_DIVIDE:
			return load("res://assets/textures/controls/keyboard/kp_slash.png")
		KEY_NUMLOCK:
			return load("res://assets/textures/controls/keyboard/numlock.png")
		KEY_SHIFT:
			return load("res://assets/textures/controls/keyboard/shift.png")
		KEY_SPACE:
			return load("res://assets/textures/controls/keyboard/space.png")
		KEY_TAB:
			return load("res://assets/textures/controls/keyboard/tab.png")
	if event.keycode < 127 and event.keycode != KEY_SPACE:
		# Scancodes < 127 are actually ASCII
		return char(event.keycode)
	else:
		# TODO: Display non-ascii keys with their respective chars instead
		# of their name
		return OS.get_keycode_string(event.keycode)

func get_from_mouse_button(event: InputEventMouseButton):
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			return load("res://assets/textures/controls/mouse/left_mouse.png")
		MOUSE_BUTTON_RIGHT:
			return load("res://assets/textures/controls/mouse/right_mouse.png")
		MOUSE_BUTTON_MIDDLE:
			return load("res://assets/textures/controls/mouse/middle_mouse.png")
		MOUSE_BUTTON_WHEEL_UP:
			return tr("MENU_CONTROLS_MOUSE_WHEEL_UP")
		MOUSE_BUTTON_WHEEL_DOWN:
			return tr("MENU_CONTROLS_MOUSE_WHEEL_DOWN")
		MOUSE_BUTTON_WHEEL_LEFT:
			return tr("MENU_CONTROLS_MOUSE_WHEEL_LEFT")
		MOUSE_BUTTON_WHEEL_RIGHT:
			return tr("MENU_CONTROLS_MOUSE_WHEEL_RIGHT")
		_:
			return tr("MENU_CONTROLS_MOUSE_BUTTON").format({"button": event.button_index})

func get_from_joypad_axis(event: InputEventJoypadMotion):
	match event.axis:
		JOY_AXIS_LEFT_X:
			if event.axis_value > 0:
				return load("res://assets/textures/controls/gamepad/arrowRight.png")
			else:
				return load("res://assets/textures/controls/gamepad/arrowLeft.png")
		JOY_AXIS_LEFT_Y:
			if event.axis_value > 0:
				return load("res://assets/textures/controls/gamepad/arrowDown.png")
			else:
				return load("res://assets/textures/controls/gamepad/arrowUp.png")
		JOY_AXIS_RIGHT_X:
			if event.axis_value > 0:
				return load("res://assets/textures/controls/gamepad/arrowRight.png")
			else:
				return load("res://assets/textures/controls/gamepad/arrowLeft.png")
		JOY_AXIS_RIGHT_Y:
			if event.axis_value > 0:
				return load("res://assets/textures/controls/gamepad/arrowDown.png")
			else:
				return load("res://assets/textures/controls/gamepad/arrowUp.png")
		JOY_AXIS_TRIGGER_LEFT:
			return load("res://assets/textures/controls/gamepad/buttonL.png")
		JOY_AXIS_TRIGGER_RIGHT:
			return load("res://assets/textures/controls/gamepad/buttonL.png")
		_:
			return tr("MENU_CONTROLS_UNKNOWN_GAMEPAD_AXIS").format({"axis": event.axis, "sign": "-" if event.axis_value < 0 else "+"})

func get_from_joypad_button(event: InputEventJoypadButton):
	match event.button_index:
		JOY_BUTTON_A:
			return load("res://assets/textures/controls/gamepad/button_down.png")
		JOY_BUTTON_B:
			return load("res://assets/textures/controls/gamepad/button_right.png")
		JOY_BUTTON_X:
			return load("res://assets/textures/controls/gamepad/button_left.png")
		JOY_BUTTON_Y:
			return load("res://assets/textures/controls/gamepad/button_up.png")
		JOY_BUTTON_DPAD_LEFT:
			return load("res://assets/textures/controls/gamepad/dpad_left.png")
		JOY_BUTTON_DPAD_RIGHT:
			return load("res://assets/textures/controls/gamepad/dpad_right.png")
		JOY_BUTTON_DPAD_DOWN:
			return load("res://assets/textures/controls/gamepad/dpad_down.png")
		JOY_BUTTON_DPAD_UP:
			return load("res://assets/textures/controls/gamepad/dpad_up.png")
		JOY_BUTTON_BACK:
			return load("res://assets/textures/controls/gamepad/buttonSelect.png")
		JOY_BUTTON_START:
			return load("res://assets/textures/controls/gamepad/buttonStart.png")
		JOY_BUTTON_LEFT_SHOULDER:
			return load("res://assets/textures/controls/gamepad/buttonL.png")
		JOY_BUTTON_RIGHT_SHOULDER:
			return load("res://assets/textures/controls/gamepad/buttonR.png")
		_:
			return tr("MENU_CONTROLS_GENERIC_GAMEPAD_BUTTON").format({"button": event.button_index})

func get_from_event(event: InputEvent):
	if event is InputEventKey:
		return get_from_key(event)
	elif event is InputEventMouseButton:
		return get_from_mouse_button(event)
	elif event is InputEventJoypadMotion:
		return get_from_joypad_axis(event)
	elif event is InputEventJoypadButton:
		return get_from_joypad_button(event)

func set_button(button: Button, value):
	if value is String:
		button.text = value
		button.icon = null
	elif value is Texture2D:
		button.icon = value
		button.text = ""

func set_button_to_event(button: Button, event: InputEvent):
	set_button(button, get_from_event(event))

func ui_from_event(event: InputEvent) -> Control:
	var control = get_from_event(event)
	if control is Texture2D:
		var texture = preload("res://common/scenes/board_logic/controller/templates/control_image.tscn").instantiate()
		texture.texture = control
		return texture
	elif control is String:
		if event is InputEventKey:
			# There isn't a special image for all keys.
			# For ones such as 'a' we generally impose the character
			# over a blank texture.
			var img = preload("res://common/scenes/board_logic/controller/templates/control_image.tscn").instantiate()
			img.get_node("Label").text = control
			return img
		else:
			var text := Label.new()
			text.text = control
			return text
	else:
		push_error("get_from_event() returned neither a texture nor a string")
		return null
