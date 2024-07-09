@tool
extends Control

# The maximum health a teams has, this is also the starting health
# This is measured in "half"-hearts, e.g. the value 2 is a full heart in display
@export var max_health = 2 # (int, 1, 8)

@onready var lobby := Lobby.get_lobby(self)

var playerid_index = [-1, -1, -1, -1]

func _load_character(player_id: int, team_index: int):
	playerid_index[player_id - 1] = team_index

	var character := lobby.get_player_by_id(player_id).character
	var icon := PluginSystem.character_loader.load_character_icon(character)

	var texture := TextureRect.new()
	texture.custom_minimum_size = Vector2(64, 64)
	texture.expand = true
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.texture = icon

	var parent := get_node("Player{0}/Icons".format([team_index]))
	parent.add_child(texture)

func _load_health(team_index: int):
	var parent = get_node("Player{0}/Health".format([team_index]))
	for _j in range((max_health + 1) / 2):
		var heart_container = preload("res://common/scenes/overlays/player_health.tscn").instantiate()

		# If it's on the right side, make it being used up from the middle
		if team_index % 2 == 0:
			heart_container.fill_mode = TextureProgressBar.FILL_RIGHT_TO_LEFT

		parent.add_child(heart_container)

func _ready():
	if Engine.is_editor_hint():
		for i in range(4):
			_load_health(i + 1)
	else:
		var i = 1
		
		match lobby.minigame_state.minigame_type:
			Lobby.MINIGAME_TYPES.FREE_FOR_ALL:
				for player_id in lobby.minigame_state.minigame_teams[0]:
					_load_character(player_id, i)
					_load_health(i)
					i += 1
			_:
				for team in lobby.minigame_state.minigame_teams:
					for player_id in team:
						_load_character(player_id, i)
					_load_health(i)
					i += 1
		
		# Remove entries that aren't needed
		while i <= 4:
			get_node("Player{0}".format([i])).queue_free()
			i += 1

# Takes away or recovers (if negative) amount of health of the team with the player `player_id`
# This is measured in "half"-hearts, e.g. the value 2 is a full heart in display
func _update_damage(player_id: int, amount: int):
	_client_update_damage(player_id, amount)
	lobby.broadcast(_client_update_damage.bind(player_id, amount))

@rpc func _client_update_damage(player_id: int, amount: int):
	var index = playerid_index[player_id - 1]
	var children = get_node("Player{0}/Health".format([index])).get_children()

	# Make the hearts be used in reverse order if its on the right side
	# This makes the heart being used up from the center
	# Sadly there is no possibility to reverse the HBoxContainer layout order
	if index % 2 == 0:
		children.invert()

	# A team's health can't fall outside of range
	var health = get_health(player_id) - amount

	for child in children:
		child.value = clamp(health, 0, 2)
		health -= 2

# Removes amount of health from the team with the player `player_id`
# This is measured in "half"-hearts, e.g. the value 2 is a full heart in display
# A team's health cannot drop below zero
# Amount must be >= 0
func take_damage(player_id: int, amount: int):
	assert(amount >= 0, "HealthOverlay: Amount of damage is < 0")
	_update_damage(player_id, amount)

# Recovers amount of health from the team with the player `player_id`
# This is measured in "half"-hearts, e.g. the value 2 is a full heart in display
# Amount must be >= 0
func heal_damage(player_id: int, amount: int):
	assert(amount >= 0 , "HealthOverlay: Amount of heal is < 0")
	_update_damage(player_id, -amount)

# Returns the amount of health a team with the player `player_id` has
# This is measured in "half"-hearts, e.g. the value 2 is a full heart in display
func get_health(player_id: int) -> int:
	var index = playerid_index[player_id - 1]
	var children = get_node("Player{0}/Health".format([index])).get_children()

	var health := 0
	for child in children:
		health += int(child.value)

	return health
