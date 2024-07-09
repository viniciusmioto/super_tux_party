extends VBoxContainer

signal canceled
signal confirmed(data: Dictionary)

func load(data):
	if data is Dictionary:
		%Name.text = data["display_name"]
		%Host.text = data["host"]
		%Port.value = data["port"]
	else:
		%Host.text = data
		%Name.text = data
	%Confirm.disabled = false

func _notification(what: int):
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			%Port.value = ProjectSettings.get("server/port")

func _ready():
	%Name.grab_focus()

func _on_confirm_pressed():
	var display_name: String = %Name.text
	var host: String = %Host.text
	var port: int = %Port.value
	
	if not display_name:
		display_name = host
	
	var data := {
		"display_name": display_name,
		"host": host,
		"port": port
	}
	confirmed.emit(data)

func _on_cancel_pressed():
	canceled.emit()

func _on_host_text_changed(new_text: String):
	%Confirm.disabled = new_text.is_empty()
