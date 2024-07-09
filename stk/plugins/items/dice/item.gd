extends Item

func _init() -> void:
	super(TYPES.DICE, "1-6 Dice")
	is_consumed = false

func activate(_player: Node3D, _controller: Node3D):
	return (randi() % 6) + 1
