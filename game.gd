extends Control

var client
var grid_state: Array = []
var custom_theme

func _on_ready():
	custom_theme = load("res://main_menu.tres")

func display_grid(grid_data):
	
	$Title.text = grid_data.title
	$GridDisplay.columns = grid_data.size.columns
	for child in $GridDisplay.get_children():
		$GridDisplay.remove_child(child)
		child.queue_free()
	for row_index in range(grid_data.size.rows):
		for col_index in range(grid_data.size.columns):
			var button = Button.new()
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var label = Label.new()
			button.add_child(label)
			button.focus_mode = Control.FOCUS_NONE
		
			label.text = grid_data.grid[row_index][col_index]
			label.anchors_preset = PRESET_FULL_RECT
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			label.size_flags_vertical = SIZE_EXPAND_FILL
			label.anchor_left = 0.0  # Anchor to the left edge
			label.anchor_top = 0.0   # Anchor to the top edge
			label.anchor_right = 1.0 # Anchor to the right edge
			label.anchor_bottom = 1.0
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Center horizontally
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.set_autowrap_mode(TextServer.AUTOWRAP_WORD)  # Enable word-based wrapping
			label.add_theme_font_size_override("font_size", 10)
			label.add_theme_color_override("font_color", "gray")
			button.tooltip_text = label.text 
			button.set_meta("row", row_index)
			button.set_meta("col", col_index)
			button.connect("pressed", Callable(self, "_on_cell_pressed").bind(row_index, col_index))
			$GridDisplay.add_child(button)
			if grid_state[row_index][col_index] != 0:
				button.modulate = get_player_color(grid_state[row_index][col_index])
	return
func _ready():
	multiplayer.connect("peer_connected", Callable(self, "_on_peer_connected"))
	var is_host = multiplayer.is_server()
	$VBoxContainer/Reset.visible = is_host
	$VBoxContainer/Shuffle.visible = is_host
	var grid_data = Global.custom_grid
	grid_state = []
	for i in range(grid_data.size.rows):
		grid_state.append([])
		for j in range(grid_data.size.columns):
			grid_state[i].append(0)
	
	print("grid_state: ", grid_state)
	display_grid(grid_data)

func find_button(row: int, col: int) -> Button:
	# Iterate through the children of the GridContainer
	for child in $GridDisplay.get_children():
		if child is Button and child.get_meta("row") == row and child.get_meta("col") == col:
			return child
	return null
	
@rpc("call_local", "any_peer")
func mark_cell(row: int, col: int, peer_id: int):
	# Check if the cell is already marked
	if grid_state[row][col] != peer_id and grid_state[row][col] != 0:
		print("Cell already marked!")
		return
	elif grid_state[row][col] == peer_id:
		grid_state[row][col] = 0
		var button = find_button(row, col)
		if button:
			button.modulate = "white"
			button.disabled = false
		print("Cell", row, col, "unmarked by player", peer_id)
	else:
		grid_state[row][col] = peer_id
		var button = find_button(row, col)
		if button:
			button.modulate = get_player_color(peer_id)
			button.disabled = false
		$AudioStreamPlayer.play()
		print("Cell", row, col, "marked by player", peer_id)
		
func get_player_color(peer_id: int):
	if peer_id in Global.peer_color_map:
		return Global.peer_color_map[peer_id]
	#match peer_id % 4:  # Cycle through 4 basic colors
		#0: return Color(1, 0, 0)  # Red
		#1: return Color(0, 1, 0)  # Green
		#2: return Color(0, 0, 1)  # Blue
		#3: return Color(1, 1, 0)  # Yellow
	return Color(0, 1, 0)  # Default (white)
		
func _on_cell_pressed(row, col):
	var peer_id = multiplayer.multiplayer_peer.get_unique_id()
	rpc("mark_cell", row, col, peer_id)
	print(grid_state)
	check_win()
	check_blocked()

func reset_grid():
	# Reset the grid state to all unmarked (0s)
	for row in range(Global.custom_grid.size.rows):
		for col in range(Global.custom_grid.size.columns):
			grid_state[row][col] = 0

	# Redraw the grid from the original loaded content
	display_grid(Global.custom_grid)
	broadcast_grid()
	
@rpc("call_local", "authority")
func shuffle_grid():
	# Flatten both the grid content and grid state
	var flattened_grid = []
	var flattened_state = []
	for row in range(Global.custom_grid.size.rows):
		for col in range(Global.custom_grid.size.columns):
			flattened_grid.append(Global.custom_grid.grid[row][col])
			flattened_state.append(grid_state[row][col])

	# Shuffle the indices to ensure both are shuffled the same way
	var indices = range(flattened_grid.size())
	indices.shuffle()

	# Reassign the shuffled values back to the grid and grid state
	var index = 0
	for row in range(Global.custom_grid.size.rows):
		for col in range(Global.custom_grid.size.columns):
			Global.custom_grid.grid[row][col] = flattened_grid[indices[index]]
			grid_state[row][col] = flattened_state[indices[index]]
			index += 1

	# Redraw the grid with updated content
	display_grid(Global.custom_grid)
	
	print("Grid and grid state shuffled!")
	print(grid_state)
	broadcast_grid()
	
func _on_reset_pressed():
	reset_grid()

func _on_shuffle_pressed():
	shuffle_grid()

func all_elements_equal(array) -> bool:
	if array.size() == 0:
		return false
	var first = array[0]
	for element in array:
		if element != first:
			return false
	return true
	
func check_win():
	for row in grid_state:
		if all_elements_equal(row) and row[0] != 0:
			print("A player has won the game: ", row[0])
			$Window.popup()
			$Window/Label.text = "A player won the game !"
			return row[0]
	for col in range(Global.custom_grid.size.columns):
		var column = []
		for row in range(Global.custom_grid.size.rows):
			column.append(grid_state[row][col])
		if all_elements_equal(column) and column[0] != 0:
			print("A player has won the game: ", column[0])
			$Window.popup()
			$Window/Label.text = "A player won the game !"
			return column[0]
			
func check_blocked():
	for row in grid_state:
		var row_blocked = false
		var seen = 0
		for element in row:
			if element != 0 and seen != 0 and element != seen:
				row_blocked = true
				break
			elif seen == 0 and element != 0:
				seen = element
		if row_blocked == false:
			return false
			
	for col in range(Global.custom_grid.size.columns):
		var col_blocked = false
		var seen = 0
		for row in range(Global.custom_grid.size.rows):
			if grid_state[row][col] != 0 and seen != 0 and grid_state[row][col] != seen:
				col_blocked = true
				break
			elif seen == 0 and grid_state[row][col] != 0:
				seen = grid_state[row][col]
		if not col_blocked:
			return false
	print("Grid is blocked, shuffle is required")
	$Window/Label.text = "Grid is blocked, host needs to shuffle"
	$Window.popup()
	return true

@rpc("call_remote")
func sync_grid(grid, new_grid_state):
# Update the local grid with the received data
	#for row_index in range(grid_data.size()):
		#for col_index in range(grid_data[row_index].size()):
			#Global.custom_grid.grid[row_index][col_index] = grid_data[row_index][col_index]
			#grid_state = grid_state_data
	Global.custom_grid = grid
	grid_state = new_grid_state
	# Refresh the grid display
	display_grid(Global.custom_grid)

@rpc("call_remote")
func sync_colors(peer_color_map=Global.peer_color_map):
	Global.peer_color_map = peer_color_map
	print("Colors synchronized")
	
func broadcast_grid():
	if multiplayer.is_server():
		var grid_data = Global.custom_grid.grid
		rpc("sync_grid", Global.custom_grid, grid_state)
		
func _on_peer_connected(peer_id: int):
	broadcast_grid()
	print("Connected :", peer_id)
	if not peer_id in Global.peer_color_map:
		print("Player not in color map")
		if Global.player_colors:
			Global.peer_color_map[peer_id] =  Global.player_colors[-1]# Assign a unique color
			Global.player_colors.erase(-1)
			print("Player added to global color map")
		else:
			print("Unable to assign a color to player ", peer_id)
	if multiplayer.is_server():
		rpc("sync_colors", Global.peer_color_map)

func _on_peer_disconnected(peer_id: int):
	print("Peer disconnected:", peer_id)
	if peer_id in Global.peer_color_map:
		Global.player_colors.append(Global.peer_color_map[peer_id])  # Reclaim the color
		Global.peer_color_map.erase(peer_id)
		if multiplayer.is_server():
			rpc("sync_colors")

func _on_back_pressed():
	multiplayer.multiplayer_peer.close()
	get_tree().change_scene_to_file("res://main_menu.tscn")
	

func _on_window_close_requested() -> void:
	$Window.hide()
