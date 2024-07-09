extends VBoxContainer

var cookies := 0: set = set_cookies
var total_cookies := 0: set = set_total_cookies

@export var icon: Texture2D = preload("res://common/scenes/board_logic/controller/icons/cookie.png"): get = get_display_icon, set = set_display_icon

func set_display_icon(icon):
	$Line1/TextureRect.texture = icon
	$Line2/TextureRect.texture = icon

func get_display_icon() -> Texture2D:
	return $Line1/TextureRect.texture

func set_cookies(c: int):
	cookies = c
	update_ui()

func set_total_cookies(c: int):
	total_cookies = c
	update_ui()

func _ready():
	show()

func update_ui():
	if cookies == 0:
		$Line1/Reward.hide()
		$Line1/TextureRect.hide()
	else:
		$Line1/Reward.text = "+" + str(cookies)
		$Line1/Reward.show()
		$Line1/TextureRect.show()
	$Line2/Total.text = str(total_cookies - cookies)

func countdown():
	cookies -= int(sign(cookies))
	update_ui()
