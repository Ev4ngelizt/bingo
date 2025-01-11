extends Window
var new_grid
func _on_ready():
	$Control/VBoxContainer.show()
	$Control/GridContent.hide()
	for i in range(1, 10):
		$Control/VBoxContainer/GridContainer/RowsOption.add_item(str(i))
		$Control/VBoxContainer/GridContainer/ColumnsOption.add_item(str(i))

func _on_create_grid_button_pressed():
	$Control/VBoxContainer.hide()
	var rows = $Control/VBoxContainer/GridContainer/RowsOption.get_selected_id()+1
	var columns = $Control/VBoxContainer/GridContainer/ColumnsOption.get_selected_id()+1
	new_grid = Global.get_grid_template(rows, columns)
	print("Creating new grid of size: ", new_grid.size)
	$Control/GridContent/Buttons/Label.text = "Please enter " + str(new_grid.size.rows*new_grid.size.columns) + " more lines"
	$Control/GridContent/Buttons/Label2.text = "Grid size is " + str(new_grid.size.rows) + "x" + str(new_grid.size.columns)
	$Control/GridContent.show()
	
func test_content():
	var input_field = $Control/GridContent/ContentLines
	var text = input_field.text
	var line_count = len(text.split('\n'))
	var max_line = new_grid.size.rows*new_grid.size.columns
	print(line_count)
	if (max_line > line_count):
		$Control/GridContent/Buttons/Label.text = "Please enter " + str(max_line - line_count) + " more lines"
		$Control/GridContent/Buttons/Label.modulate = "white"
	elif (max_line == line_count):
		$Control/GridContent/Buttons/Label.text = "Grid is done !"
		$Control/GridContent/Buttons/Label.modulate = "green"
	else:
		$Control/GridContent/Buttons/Label.text = "You have entered " + str(line_count - max_line) +" too many lines"
		$Control/GridContent/Buttons/Label.modulate = "red"
	return
func _on_content_lines_text_changed() -> void:
	test_content()

		
func _on_save_pressed() -> void:
	if $Control/GridContent/VBoxContainer/TitleLine.text == "":
		$Control/GridContent/Buttons/Label.text = "Please include a title"
		$Control/GridContent/Buttons/Label.modulate = "red"
		return
	if len($Control/GridContent/ContentLines.text.split('\n')) != new_grid.size.rows*new_grid.size.columns:
		test_content()
		$Control/GridContent/Buttons/Label.modulate = "red"
		return
	
	# Writing content to the grid and saving it
	
	new_grid.title = $Control/GridContent/VBoxContainer/TitleLine.text
	new_grid.description = $Control/GridContent/VBoxContainer/DescriptionLines.text
	var grid_content = $Control/GridContent/ContentLines.text.split('\n')
	for i in range(new_grid.size.rows):
		for j in range(new_grid.size.columns):
			new_grid.grid[i][j] = grid_content[i*new_grid.size.columns+j]
	new_grid.date = Time.get_datetime_string_from_system()
	print(new_grid)
	$FileDialog.current_file = new_grid.title
	$FileDialog.popup_centered()
	
func _on_file_dialog_file_selected(path: String) -> void:
	var json = JSON.new()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_line(json.stringify(new_grid, '\t'))
	

func _on_change_size_pressed() -> void:
	pass # Replace with function body.

func _on_exit_pressed() -> void:
	queue_free()
