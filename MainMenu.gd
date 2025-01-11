extends Control

var network = null
var client
var grid_creation = preload("res://grid_creation.tscn")
var window = preload("res://join_window.tscn")
signal send_color(color)
	
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

func join_game(address: String, port: int = 12345, timeout = 5.0):
	client = ENetMultiplayerPeer.new()
	var result = client.create_client(address, port)
	if result != OK:
		print("Failed to connect to server:", result)
		show_error_message("Failed to connect to server:" + str(result))
		return false
		
	multiplayer.multiplayer_peer = client
	var connection_timer = Timer.new()
	connection_timer.wait_time = timeout
	connection_timer.one_shot = true
	connection_timer.timeout.connect(_on_connection_timeout)
	add_child(connection_timer)
	connection_timer.start()

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	
func _connection_failed():
	show_error_message("Failed to connect to server")
	disconnect_peer()
	
func _on_connected_to_server():
	print("Successfully connected to server")
	var timer = get_node_or_null("connection_timer")
	if timer:
		timer.stop()
		timer.queue_free()
	get_tree().change_scene_to_file("res://game.tscn")
	
func _on_connection_timeout():
	print("Failed to connect to server: Connection timed out")
	show_error_message("Failed to connect to server: Connection timed out")
	
func disconnect_peer():
	if client and client.is_connected_to_host():
		client.close_connection()
	client = null
	get_tree().multiplayer.peer = null
	print("Disconnected from the server")
	
func show_error_message(error):
	$Window/Control/VBoxContainer/Label.text = error
	
func _on_host_button_pressed():
	host_game()
	get_tree().change_scene_to_file("res://game.tscn")

func _on_join_button_pressed():
	var new_window = window.instantiate()
	add_child(new_window)
	new_window.connect("close_requested", new_window.queue_free)
	new_window.connect("join_game", join_game)
	new_window.popup()
	
func _on_peer_connected(peer_id):
	pass
	
func _on_create_button_pressed():
	var grid = get_node("GridCreation")
	if grid:
		grid.show()
		return
	else:
		grid = grid_creation.instantiate()
		grid.connect("close_requested", grid.hide)
		add_child(grid)
		grid.show()

func _on_grid_creation_close_requested():
	$GridCreation.queue_free()
