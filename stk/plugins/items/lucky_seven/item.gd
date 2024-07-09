extends Item

func _init() -> void:
	super(TYPES.DICE, "Lucky Seven")
	is_consumed = true
	
	can_be_bought = true
	item_cost = 2

func get_description() -> String:
	return "Use this special dice to roll a guaranteed seven!"

func activate(_player: Node3D, _controller: Node3D):
	return 7
