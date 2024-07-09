## Prefab implementation to query players about confirmation or input
extends Control
class_name SpeechDialog

signal dialog_finished
signal dialog_option_taken(accepted)

const CLICK_SOUND = preload("res://assets/sounds/ui/rollover2.wav")
const SELECT_SOUND = preload("res://assets/sounds/ui/click1.wav")

enum TYPES {
	INVALID = -1,
	DIALOG,
	YESNO,
	RANGE
}

@onready var lobby := Lobby.get_lobby(self)

var player_id := -1

var type: TYPES = TYPES.INVALID
var _local := false

func _ready() -> void:
	hide()

var current_timer: SceneTreeTimer = null
func player_timeout():
	_internal_accept(false)

func start_timer_for_player(player_id: int):
	if lobby.timeout <= 0:
		return
	assert(current_timer == null, "A previous timer was not stopped")
	var addr := lobby.get_player_by_id(player_id).addr
	current_timer = get_tree().create_timer(lobby.timeout)
	current_timer.timeout.connect(player_timeout.bind(addr))

func cancel_timer():
	if not current_timer:
		return
	current_timer.timeout.disconnect(player_timeout)
	current_timer = null

@rpc func _accept_dialog():
	hide()
	$HBoxContainer/NinePatchRect/Buttons.hide()
	$HBoxContainer/NinePatchRect/Range.hide()
	type = TYPES.INVALID
	player_id = -1
	UISound.stream = CLICK_SOUND
	UISound.play()

func _ok_event():
	if has_focus() and type == TYPES.DIALOG:
		var scrollbar = $HBoxContainer/NinePatchRect/MarginContainer/Text.get_v_scroll_bar()
		var height = $HBoxContainer/NinePatchRect/MarginContainer/Text.size.y
		if scrollbar.value < scrollbar.max_value - height:
			scrollbar.value += height
		else:
			if _local:
				_internal_accept(null)
				_accept_dialog()
			else:
				accept.rpc_id(1, null)
	elif $HBoxContainer/NinePatchRect/Buttons/Yes.has_focus():
			if _local:
				_internal_accept(true)
				_accept_dialog()
			else:
				accept.rpc_id(1, true)
	elif $HBoxContainer/NinePatchRect/Buttons/No.has_focus():
			if _local:
				_internal_accept(false)
				_accept_dialog()
			else:
				accept.rpc_id(1, false)
	elif $HBoxContainer/NinePatchRect/Range.visible:
			if _local:
				_internal_accept(null)
				_accept_dialog()
			else:
				accept.rpc_id(1, null)

func _input(event: InputEvent) -> void:
	if player_id == -1:
		return
	var is_action: bool = event.is_action_pressed("player%d_ok" % player_id)
	if is_action:
		get_viewport().set_input_as_handled()
		_ok_event()
		return
	var is_up: bool = event.is_action_pressed("player%d_up" % player_id)
	var is_down: bool = event.is_action_pressed("player%d_down" % player_id)
	if is_up or is_down:
		if $HBoxContainer/NinePatchRect/Range.visible:
			get_viewport().set_input_as_handled()
			if is_up:
				$HBoxContainer/NinePatchRect/Range.value += 1
			else:
				$HBoxContainer/NinePatchRect/Range.value -= 1
			if not _local:
				query_value_changed.rpc_id(1, $HBoxContainer/NinePatchRect/Range.value)

func _setup(speaker: String, texture: Texture2D, text: String, format_args, player_id: int):
	_local = false
	$HBoxContainer/TextureRect.texture = texture
	self.player_id = player_id
	show()
	$HBoxContainer/NinePatchRect/Name.text = speaker
	$HBoxContainer/NinePatchRect/MarginContainer/Text.text = tr(text).format(format_args)

@rpc("any_peer", "call_local") func accept(arg):
	if player_id == -1:
		return
	if lobby.get_player_by_id(player_id).addr.peer_id != multiplayer.get_remote_sender_id():
		return
	cancel_timer()
	lobby.broadcast(_accept_dialog)
	_internal_accept(arg)

func _internal_accept(arg):
	match type:
		TYPES.DIALOG:
			dialog_finished.emit()
		TYPES.YESNO:
			dialog_option_taken.emit(arg as bool)
		TYPES.RANGE:
			dialog_option_taken.emit($HBoxContainer/NinePatchRect/Range.value)
		_:
			return
	type = TYPES.INVALID
	player_id = -1

func show_dialog(speaker: String, texture: String, text: String, player_id: int, format_args = {}) -> void:
	if multiplayer.is_server():
		_local = false
		self.player_id = player_id
		type = TYPES.DIALOG
		start_timer_for_player(player_id)
		lobby.broadcast(_client_show_dialog.bind(speaker, texture, text, format_args, player_id))
		if lobby.get_player_by_id(player_id).is_ai():
			get_tree().create_timer(1.0).timeout.connect(func (): self.accept.rpc_id(1, null))
	else:
		_client_show_dialog(speaker, texture, text, format_args, player_id)
		_local = true

@rpc func _client_show_dialog(speaker: String, texture: String, text: String, format_args, player_id: int) -> void:
	type = TYPES.DIALOG
	_setup(speaker, load(texture), text, format_args, player_id)
	grab_focus()

func show_accept_dialog(speaker: String, texture: String, text: String, player_id: int, format_args = {}) -> void:
	if multiplayer.is_server():
		_local = false
		self.player_id = player_id
		type = TYPES.YESNO
		start_timer_for_player(player_id)
		lobby.broadcast(_client_show_accept_dialog.bind(speaker, texture, text, format_args, player_id))
		if lobby.get_player_by_id(player_id).is_ai():
			get_tree().create_timer(1.0).timeout.connect(func (): self.accept.rpc_id(1, true))
	else:
		_client_show_accept_dialog(speaker, texture, text, format_args, player_id)
		_local = true

@rpc func _client_show_accept_dialog(speaker: String, texture: String, text: String, format_args, player_id: int):
	_setup(speaker, load(texture), text, format_args, player_id)
	type = TYPES.YESNO
	if lobby.get_player_by_id(player_id).is_local():
		$HBoxContainer/NinePatchRect/Buttons.show()
		$HBoxContainer/NinePatchRect/Buttons/Yes.grab_focus()

func show_query_dialog(speaker: String, texture: String, text: String, player_id: int, minimum: int, maximum: int, start_value: int, format_args = {}) -> void:
	if multiplayer.is_server():
		_local = false
		self.player_id = player_id
		type = TYPES.RANGE
		start_timer_for_player(player_id)
		$HBoxContainer/NinePatchRect/Range.min_value = minimum
		$HBoxContainer/NinePatchRect/Range.max_value = maximum
		$HBoxContainer/NinePatchRect/Range.value = start_value
		lobby.broadcast(_client_show_query_dialog.bind(speaker, texture, text, format_args, player_id, minimum, maximum, start_value))
		if lobby.get_player_by_id(player_id).is_ai():
			get_tree().create_timer(1.0).timeout.connect(func (): self.accept.rpc_id(1, null))
	else:
		_client_show_query_dialog(speaker, texture, text, format_args, player_id, minimum, maximum, start_value)
		_local = true

func _client_show_query_dialog(speaker: String, texture: String, text: String, format_args, player_id: int, minimum: int, maximum: int, start_value: int):
	type = TYPES.RANGE
	_setup(speaker, load(texture), text, format_args, player_id)
	$HBoxContainer/NinePatchRect/Range.min_value = minimum
	$HBoxContainer/NinePatchRect/Range.max_value = maximum
	$HBoxContainer/NinePatchRect/Range.value = start_value
	$HBoxContainer/NinePatchRect/Range.disabled = not lobby.get_player_by_id(player_id).is_local()
	$HBoxContainer/NinePatchRect/Range.show()

@rpc("any_peer") func query_value_changed(new: int):
	if lobby.get_player_by_id(player_id).addr.peer_id != multiplayer.get_remote_sender_id():
		return
	$HBoxContainer/NinePatchRect/Range.value = new
	# The Range node will do the bounds check for us
	var sanitized = $HBoxContainer/NinePatchRect/Range.value
	lobby.broadcast(_client_query_value_changed.bind(sanitized))

@rpc func _client_query_value_changed(new: int):
	$HBoxContainer/NinePatchRect/Range.value = new

func _on_focus_entered(node: String) -> void:
	(get_node(node) as NinePatchRect).texture = load("res://common/scenes/speech_dialog/dialog_box_focus.png")

func _on_focus_exited(node: String) -> void:
	(get_node(node) as NinePatchRect).texture = load("res://common/scenes/speech_dialog/dialog_box.png")
	UISound.stream = SELECT_SOUND
	UISound.play()

func _on_mouse_entered(node: String) -> void:
	_on_focus_entered(node)

func _on_mouse_exited(node: String) -> void:
	if not get_node(node).has_focus():
		_on_focus_exited(node + "/MarginContainer/NinePatchRect")

func _click_input(event: InputEvent):
	if event.is_action_pressed("left_mouse_pressed"):
		accept_event()
		_ok_event()
