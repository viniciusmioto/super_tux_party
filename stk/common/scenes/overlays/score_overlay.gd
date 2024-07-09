@tool
extends Control

@export var icon: Texture2D: set = set_icon
@export var startscore: int = 0

enum ValueType {
	Int,
	Float
}

@export var value_type: ValueType = ValueType.Int

@onready var lobby := Lobby.get_lobby(self)

var playerid_index: Array[int] = [-1, -1, -1, -1]
var points: Array[float] = [startscore, startscore, startscore, startscore]
var teams = [[], [], [], []]

func _load_character(player_id: int, team_index: int):
	playerid_index[player_id - 1] = team_index
	teams[team_index - 1].append(player_id)

	var info := lobby.get_player_by_id(player_id)
	var character := info.character
	var icon := PluginSystem.character_loader.load_character_icon(character)

	var texture := TextureRect.new()
	texture.custom_minimum_size = Vector2(64, 64)
	texture.expand = true
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.texture = icon

	var parent = get_node("Player{0}/Icons".format([team_index]))
	parent.add_child(texture)

func _load_score(team_index: int):
	var parent := get_node("Player{0}".format([team_index]))
	parent.get_node("Score/Icon").texture = self.icon
	parent.get_node("Score/Amount").text = str(startscore)

func _ready():
	if Engine.is_editor_hint():
		for i in range(4):
			_load_score(i + 1)
	else:
		var i := 1
		
		match lobby.minigame_state.minigame_type:
			Lobby.MINIGAME_TYPES.FREE_FOR_ALL:
				for player_id in lobby.minigame_state.minigame_teams[0]:
					_load_character(player_id, i)
					_load_score(i)
					i += 1
			_:
				for team in lobby.minigame_state.minigame_teams:
					for player_id in team:
						_load_character(player_id, i)
					_load_score(i)
					i += 1
		
		while i <= len(lobby.player_info):
			get_node("Player{0}".format([i])).queue_free()
			i += 1

func set_score(player_id: int, score: float):
	points[player_id - 1] = score
	lobby.broadcast(_client_set_score.bind(player_id, score))

@rpc func _client_set_score(player_id: int, score: float):
	points[player_id - 1] = score
	var index = playerid_index[player_id - 1]
	var total := 0.0
	for pid in teams[index - 1]:
		total += points[pid - 1]
	var label := get_node("Player{0}/Score/Amount".format([index]))
	match value_type:
		ValueType.Int:
			label.text = str(int(total))
		ValueType.Float:
			label.text = "%.2f" % total

func get_score(player_id):
	return points[player_id - 1]

func set_icon(tex):
	icon = tex
	
	if is_inside_tree():
		for i in range(4):
			var node = get_node_or_null("Player{0}/Score/Icon".format([i + 1]))
			if node:
				node.texture = icon
