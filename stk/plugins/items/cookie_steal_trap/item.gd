extends Item

func _init() -> void:
	super(TYPES.PLACABLE, "Cookie Steal Trap")
	is_consumed = true

	can_be_bought = true
	item_cost = 5

func get_description() -> String:
	return "Place this trap on a space to rob cookies from the player who lands on it"

func activate_trap(from_player: Node3D, trap_player: Node3D,
		_controller: Node3D):
	var cookies = int(min(from_player.cookies, 10))

	from_player.cookies -= cookies
	trap_player.cookies += cookies

	# Removes the trap from the node.
	return true
