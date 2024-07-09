extends Control

@export var countdown_time: float = 3
@export var autostart: bool = true

signal finish

@onready var lobby := Lobby.get_lobby(self)
var time_left: float
var timer_finished: bool

func _force_animation_update(node):
	if node is AnimationPlayer and node.is_playing():
		node.seek(node.current_animation_position, true)
	if node is AnimationTree and node.active:
		node.advance(0)

	for child in node.get_children():
		_force_animation_update(child)

func _ready():
	if autostart:
		start()

func start():
	# Force update all animations or they won't be shown properly if they were just started
	_force_animation_update(lobby)

	timer_finished = false
	time_left = countdown_time
	lobby.process_mode = PROCESS_MODE_DISABLED
	$Label.modulate = Color(1, 1, 1, 1)
	$AudioStreamPlayer.play()

#func _is_paused():
	## Check if the pause menu is open
	#for node in Utility.get_nodes_in_group(lobby, "pausemenu"):
		#if node.paused:
			#return true
	#return false

func _process(delta):
	# Only let the timer run if the pause menu is not open
	if not timer_finished:# and not _is_paused():
		$Label.text = str(int(time_left) + 1)

		time_left = max(time_left - delta, 0)
		if time_left == 0:
			_on_Timer_timeout()

func _on_Timer_timeout():
	timer_finished = true
	$Label.text = tr("CONTEXT_LABEL_GO")
	$AnimationPlayer.play("fadeout")
	lobby.process_mode = Node.PROCESS_MODE_INHERIT

	finish.emit()
