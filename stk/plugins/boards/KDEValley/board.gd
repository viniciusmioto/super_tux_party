extends Node3D

signal animation_finished
signal walking_finished

enum State {
	None,
	Fly_out,
	Fly_in,
	WALK_DRAGON
}

var player_to_animate: Node3D
var next_space: NodeBoard
var state: int = State.None
var destination: Vector3

var dragon: Node3D
var start: Vector3
var end: Vector3
var time: float
var duration: float

func _process(delta: float):
	match state:
		State.WALK_DRAGON:
			time += delta
			time = min(time, duration)
			dragon.position = start * (1 - time/duration) + end * (time/duration)
			if time == duration:
				start = Vector3()
				end = Vector3()
				time = 0
				duration = 0
				state = State.None
				walking_finished.emit()
		State.Fly_out:
			if player_to_animate.position.y < player_to_animate.space.position.y + 5:
				player_to_animate.position.y += 10 * delta
			else:
				state = State.Fly_in
				player_to_animate.position = next_space.position
				destination = player_to_animate.position
				player_to_animate.position += Vector3(0, 5, 0)
				$Controller.camera_focus = next_space
				next_space = null
		State.Fly_in:
			if player_to_animate.position.y > destination.y:
				player_to_animate.position.y -= 10 * delta
			else:
				player_to_animate.position = destination
				state = State.None
				player_to_animate = null
				destination = Vector3()
				animation_finished.emit()

func handle_event(player: Node3D, space: NodeBoard):
	var event_name := "KDE_VALLEY_DRAGON_NAME"
	var icon := "res://plugins/boards/KDEValley/dragons/%s_icon.png" % space.name
	var text := "KDE_VALLEY_TAKE_TO_CAKE"
	
	$SpeechDialog.show_accept_dialog(event_name, icon, text, player.info.player_id)
	if not await $SpeechDialog.dialog_option_taken:
		$Controller.board_continue()
		return

	$Controller.lobby.broadcast(_dragon_animation.bind(player.info.player_id, get_path_to(space)))
	await _dragon_animation(player.info.player_id, get_path_to(space))

@rpc func _dragon_animation(id: int, node: String):
	var player = $Controller.get_player_by_player_id(id)
	var space = get_node(node)
	var dragon_anim: AnimationPlayer =\
		space.get_node("Dragon/AnimationPlayer")
	dragon_anim.play("walk")

	dragon = space.get_node("Dragon")
	var start_transform: Transform3D = dragon.transform

	start = dragon.position
	var d: Vector3 = player.position - dragon.position
	end = player.position - d.normalized() * 0.3
	var dir: Vector3 = (end - start).normalized()
	duration = (end - start).length() * 0.5
	dragon.rotation = Vector3(0, atan2(dir.x, dir.z), 0)
	state = State.WALK_DRAGON
	await self.walking_finished

	dragon_anim.play("fly_start")

	await get_tree().create_timer(0.5).timeout
	var target_space = $Controller.get_cake_space()
	next_space = target_space
	player_to_animate = player
	state = State.Fly_out

	$Controller.camera_focus = space

	await self.animation_finished

	dragon.transform = start_transform
	dragon_anim.play("fly_end")
	dragon = null

	if multiplayer.is_server():
		player.teleport_to(target_space)
		await $Controller.buy_cake(player)
		await get_tree().create_timer(0.5).timeout
		$Controller.board_continue()
