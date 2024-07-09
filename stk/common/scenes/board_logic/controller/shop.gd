extends Control

signal shopping_completed

@onready var controller: Controller =  get_parent().get_parent()
var current_player: PlayerBoard
var items := []

var selected_item: Node

func _init():
	hide()
	Global.language_changed.connect(_on_refresh_language)

func generate_shop_items(space: NodeBoard):
	assert(current_player, "Generating shop items while no current player is set")
	items = []
	var buyable_item_info: Array = PluginSystem.item_loader.get_buyable_items()

	var buyable := []

	for item in buyable_item_info:
		buyable.append(item)

	for file in space.custom_items:
		buyable.erase(file)
		items.append(file)

	if items.size() > NodeBoard.MAX_STORE_SIZE:
		items.resize(NodeBoard.MAX_STORE_SIZE)

	while items.size() < NodeBoard.MAX_STORE_SIZE and buyable.size() != 0:
		var index: int = randi() % buyable.size()
		var random_item = buyable[index]
		buyable[index] = buyable[-1]
		buyable[-1] = random_item
		buyable.pop_back()
		items.append(random_item)

func ai_do_shopping(player: PlayerBoard) -> void:
	self.current_player = player
	generate_shop_items(player.space)

	# Index into the item array.
	var item_to_buy := -1
	var item_cost := 0
	for i in items.size():
		var cost = load(items[i]).new().item_cost
		# Always keep enough money ready to buy a cake.
		# Buy the most expensive item that satisfies this criteria.
		if player.cookies - cost >= controller.COOKIES_FOR_CAKE and\
				(item_to_buy == -1 or item_cost < cost):
			item_to_buy = i
			item_cost = cost

	if item_to_buy != -1 and player.give_item(load(items[item_to_buy]).new()):
		player.cookies -= item_cost

func player_do_shopping(player: PlayerBoard) -> void:
	self.current_player = player
	generate_shop_items(player.space)
	open_shop.rpc_id(player.info.addr.peer_id, player.info.player_id, items)

@rpc("any_peer") func item_purchased(idx: int):
	if not current_player:
		return
	var network_id := multiplayer.get_remote_sender_id()
	if current_player.info.addr.peer_id != network_id:
		return
	if idx < 0 or idx > items.size():
		controller.lobby.kick(network_id, "Misbehaving Client")
		return
	var item = load(items[idx]).new()
	if item.item_cost > current_player.cookies:
		purchase_failed.rpc_id(network_id, "CONTEXT_NOTIFICATION_NOT_ENOUGH_COOKIES")
		return
	if not current_player.give_item(item):
		purchase_failed.rpc_id(network_id, "CONTEXT_NOTIFICATION_NOT_ENOUGH_SPACE")
		return
	current_player.cookies -= item.item_cost

@rpc("any_peer") func server_shopping_completed():
	if not current_player:
		return
	var player_info := controller.lobby.get_player_by_id(current_player.info.player_id)
	if player_info.addr.peer_id != multiplayer.get_remote_sender_id():
		return
	end_shopping()

func end_shopping():
	self.current_player = null
	self.items = []
	shopping_completed.emit()

@rpc func open_shop(player_id: int, items: Array) -> void:
	if items.size() == 0:
		server_shopping_completed.rpc_id(1)
		return
	
	var player = controller.get_player_by_player_id(player_id)
	for item_path in items:
		var item := PluginSystem.item_loader.has_item(item_path)
		if not item:
			push_error("Failed to load item: " + item_path)
			controller.lobby.leave()
			return
	self.items = items
	
	for i in range(NodeBoard.MAX_STORE_SIZE):
		var element := $Items.get_child(i)
		element.player = player
		element.idx = i
		if i < items.size():
			element.item = items[i]
			element.show()
		else:
			element.hide()
			element.item = ""

	$Items/Item1.select()
	show()

func _on_shop_item(_player, idx: int, _instance) -> void:
	item_purchased.rpc_id(1, idx)

@rpc func purchase_failed(reason: String):
	$Notification.dialog_text = reason
	$Notification.popup_centered()

func _on_show_description(text: String):
	$PanelContainer/VBoxContainer/RichTextLabel.text = tr(text)

func _on_refresh_language():
	if selected_item:
		selected_item.update_description()

func _on_Shop_Back_pressed() -> void:
	hide()
	server_shopping_completed.rpc_id(1)
