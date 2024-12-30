extends Control

var network = null

func _ready():
	pass
	
func validate_grid():
	return true
	
func _on_import_grid_pressed():
	$FileDialog.popup_centered()
	
func _on_file_dialog_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var content = file.get_as_text()
		var parse_result = json.parse(content)
		if parse_result == OK:
			var grid_data = json.data
			# Validate the imported grid
			if validate_grid():
				print("Grid imported:", grid_data)
				
				# Store the grid in the Global singleton
				Global.custom_grid = grid_data
				
				# Navigate to the game scene
			else:
				print("Invalid grid format!")
	else:
		print("File not found!")

func host_game(port: int = 12345):
	var server = ENetMultiplayerPeer.new()
	var result = server.create_server(port)
	if result != OK:
		print("Failed to start server:", result)
		return
	multiplayer.multiplayer_peer = server
	print("Server started on port", port)

func join_game(address: String, port: int = 12345):
	var client = ENetMultiplayerPeer.new()
	var result = client.create_client(address, port)
	if result != OK:
		print("Failed to connect to server:", result)
		return false
	multiplayer.multiplayer_peer = client
	print("Connected to server at", address)
	get_tree().change_scene_to_file("res://game.tscn")
	return true


func _on_host_button_pressed():
	host_game()
	get_tree().change_scene_to_file("res://game.tscn")

func _on_join_button_pressed():
	var adress = $CenterContainer/VBoxContainer/LineEdit.text
	join_game(adress)
	
