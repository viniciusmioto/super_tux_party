extends Control

@onready var lobby := Lobby.get_lobby(self)

func _ready():
	clear_display()

@rpc func _client_display_action(action):
	_client_clear_display()
	var conf = InputMap.action_get_events(action)[0]
	
	var control = ControlHelper.get_from_event(conf)
	if control is Texture2D:
		$TextureRect.texture = control
		$Label.text = ""
	else:
		if conf is InputEventKey:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/key_blank.png")
		else:
			$TextureRect.texture = null
		$Label.text = control

func display_action(action):
	# Replicate the state to the clients if applicable
	if lobby and is_multiplayer_authority():
		lobby.broadcast(_client_display_action.bind(action))
	_client_display_action(action)

@rpc func _client_clear_display():
	$Label.text = ""
	$TextureRect.texture = null

func clear_display():
	# Replicate the state to the clients if applicable
	if lobby and is_multiplayer_authority():
		lobby.broadcast(_client_clear_display)
	_client_clear_display()
