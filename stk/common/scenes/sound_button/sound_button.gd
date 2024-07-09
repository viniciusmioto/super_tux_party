extends Control

@export_file var custom_click

var _click_sound = preload("res://assets/sounds/ui/rollover2.wav")
var _select_sound = preload("res://assets/sounds/ui/click1.wav")

func _ready():
	if custom_click:
		_click_sound = load(custom_click)

func _click():
	UISound.stream = _click_sound
	UISound.play()

func _click_with_arg(_arg):
	_click()

func _select():
	UISound.stream = _select_sound
	UISound.play()

func _select_with_arg(_arg):
	_select()

func _cancel_sound():
	UISound.stop()
