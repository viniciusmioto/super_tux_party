extends Control

@export var player1: SplitScreenCamera
@export var player2: SplitScreenCamera
@export var player3: SplitScreenCamera
@export var player4: SplitScreenCamera

func _ready():
	var lobby := Lobby.get_lobby(self)
	var viewportsize = get_viewport_rect().size
	var player1_viewport = player1.get_node("SubViewport")
	var player2_viewport = player2.get_node("SubViewport")
	
	$Player1.texture = player1_viewport.get_texture()
	$Player2.texture = player2_viewport.get_texture()
	if lobby.minigame_type != Lobby.MINIGAME_TYPES.DUEL:
		var player3_viewport = player3.get_node("SubViewport")
		var player4_viewport = player4.get_node("SubViewport")
		$Player3.texture = player3_viewport.get_texture()
		$Player4.texture = player4_viewport.get_texture()
		
		player1_viewport.size = Vector2(viewportsize.x / 2, viewportsize.y / 2)
		player2_viewport.size = Vector2(viewportsize.x / 2, viewportsize.y / 2)
		player3_viewport.size = Vector2(viewportsize.x / 2, viewportsize.y / 2)
		player4_viewport.size = Vector2(viewportsize.x / 2, viewportsize.y / 2)
	else:
		player1_viewport.size = Vector2(viewportsize.x / 2, viewportsize.y)
		player2_viewport.size = Vector2(viewportsize.x / 2, viewportsize.y)
