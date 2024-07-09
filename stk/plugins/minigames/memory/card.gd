extends Node3D

var variant: int: set = set_variant

var faceup := false
@onready var lobby: Lobby = get_parent().get_parent().lobby

func set_variant(value: int):
	variant = value

	$Front.texture = load("res://plugins/minigames/memory/cards/card_{0}.png".format([value]))

func load_icon(node: Sprite3D, player_id: int):
	var texture = PluginSystem.character_loader.load_character_icon(lobby.get_player_by_id(player_id).character)
	node.texture = texture
	node.pixel_size = min(1.28 / texture.get_width(), 1.28 / texture.get_height())

func _ready():
	load_icon($Player1, lobby.minigame_state.minigame_teams[0][0])
	load_icon($Player2, lobby.minigame_state.minigame_teams[0][1])
	load_icon($Player3, lobby.minigame_state.minigame_teams[1][0])
	load_icon($Player4, lobby.minigame_state.minigame_teams[1][1])

@rpc func _client_flip_up(color: Color):
	faceup = true
	$Front.modulate = color
	$AnimationPlayer.play("flip_up")

func flip_up(color: Color = Color.WHITE):
	lobby.broadcast(_client_flip_up.bind(color))
	_client_flip_up(color)
	return $AnimationPlayer

@rpc func _client_flip_down():
	$AnimationPlayer.play("flip_down")

func flip_down():
	lobby.broadcast(_client_flip_down)
	_client_flip_down()
	return $AnimationPlayer

func is_animation_running() -> bool:
	return $AnimationPlayer.is_playing()

func animation_player() -> AnimationPlayer:
	return $AnimationPlayer as AnimationPlayer

@rpc func show_player(idx: int):
	get_node("Player" + str(idx)).show()

@rpc func hide_player(idx: int):
	get_node("Player" + str(idx)).hide()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "flip_down":
		faceup = false
