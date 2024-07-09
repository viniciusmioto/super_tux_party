extends Resource

# all minigames in the current rotation that weren't played yet
var _minigames: Array[MinigameLoader.MinigameConfigFile] = []
# all minigames in the current rotation that were already played
var _played: Array[MinigameLoader.MinigameConfigFile] = []

func _init():
	_minigames = PluginSystem.minigame_loader.get_minigames()
	_minigames.shuffle()

# Utility function that should not be called use
# get_random_1v3/get_random_2v2/get_random_duel/get_random_ffa/get_random_nolok/get_random_gnu.
func _get_random_minigame(type: String) -> MinigameLoader.MinigameConfigFile:
	for i in range(len(_minigames)):
		if type in _minigames[i].type:
			var minigame := _minigames[i]
			_minigames.remove_at(i)
			_played.append(minigame)
			return minigame
	# There's no minigame that has the needed type
	# If we're at the start of the queue, then there's no minigame of that type,
	# because we just looked at all of them
	assert(len(_played) > 0, "No minigame for type: " + type)
	# Rebuild a new queue, but keep the unused elements at the start
	_played.shuffle()
	_minigames += _played
	_played = []
	return _get_random_minigame(type)

## Returns a random minigame that can be played in 1v3 mode
func get_random_1v3() -> MinigameLoader.MinigameConfigFile:
	return _get_random_minigame("1v3")

## Returns a random minigame that can be played in 2v2 mode
func get_random_2v2() -> MinigameLoader.MinigameConfigFile:
	return _get_random_minigame("2v2")

## Returns a random minigame that can be played in duel mode
func get_random_duel() -> MinigameLoader.MinigameConfigFile:
	return _get_random_minigame("Duel")

## Returns a random minigame that can be played in ffa mode
func get_random_ffa() -> MinigameLoader.MinigameConfigFile:
	return _get_random_minigame("FFA")

## Returns a random minigame that can be played in nolok solo mode
func get_random_nolok_solo() -> MinigameLoader.MinigameConfigFile:
	return _get_random_minigame("NolokSolo")

## Returns a random minigame that can be played in nolok coop mode
func get_random_nolok_coop() -> MinigameLoader.MinigameConfigFile:
	return _get_random_minigame("NolokCoop")

## Returns a random minigame that can be played in gnu solo mode
func get_random_gnu_solo() -> MinigameLoader.MinigameConfigFile:
	return _get_random_minigame("GnuSolo")

## Returns a random minigame that can be played in gnu coop mode
func get_random_gnu_coop() -> MinigameLoader.MinigameConfigFile:
	return _get_random_minigame("GnuCoop")
