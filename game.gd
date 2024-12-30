extends Control

var grid_state: Array = []
var player_colors = [Color(1, 0, 0), Color(0, 1, 0), Color(0, 0, 1), Color(1, 1, 0)]
var peer_color_map = {}  # Maps peer IDs to their colors
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
			
			button.tooltip_text = label.text 
			button.set_meta("row", row_index)
			button.set_meta("col", col_index)
			button.connect("pressed", Callable(self, "_on_cell_pressed").bind(row_index, col_index))
			$GridDisplay.add_child(button)
			if grid_state[row_index][col_index] != 0:
				button.modulate = get_player_color(grid_state[row_index][col_index])
				button.disabled = true
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
	if grid_state[row][col] != 0:
		print("Cell already marked!")
		return
	grid_state[row][col] = peer_id
	var button = find_button(row, col)
	if button:
		button.modulate = get_player_color(peer_id)
		button.disabled = true
	print("Cell", row, col, "marked by player", peer_id)

func get_player_color(peer_id: int):
	match peer_id % 4:  # Cycle through 4 basic colors
		0: return Color(1, 0, 0)  # Red
		1: return Color(0, 1, 0)  # Green
		2: return Color(0, 0, 1)  # Blue
		3: return Color(1, 1, 0)  # Yellow
	return Color(1, 1, 1)  # Default (white)
		
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
			return row[0]
	for col in range(Global.custom_grid.size.columns):
		var column = []
		for row in range(Global.custom_grid.size.rows):
			column.append(grid_state[row][col])
		if all_elements_equal(column) and column[0] != 0:
			print("A player has won the game: ", column[0])
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
	return true

@rpc("call_remote")
func sync_grid(grid_data, grid_state_data):
# Update the local grid with the received data
	for row_index in range(grid_data.size()):
		for col_index in range(grid_data[row_index].size()):
			Global.custom_grid.grid[row_index][col_index] = grid_data[row_index][col_index]
			grid_state = grid_state_data
	
	# Refresh the grid display
	display_grid(Global.custom_grid)
	
func broadcast_grid():
	if multiplayer.is_server():
		var grid_data = Global.custom_grid.grid
		rpc("sync_grid", grid_data, grid_state)
		
func _on_peer_connected(peer_id: int):
	broadcast_grid()
	if not peer_id in peer_color_map:
		if player_colors.size() > 0:
			peer_color_map[peer_id] = player_colors.pop_front()  # Assign a unique color
			print("Assigned color to peer:", peer_id, peer_color_map[peer_id])
		else:
			print("No more colors available for peer:", peer_id)

func _on_peer_disconnected(peer_id: int):
	print("Peer disconnected:", peer_id)
	if peer_id in peer_color_map:
		player_colors.append(peer_color_map[peer_id])  # Reclaim the color
		peer_color_map.erase(peer_id)
				
			
