extends Control

func _ready():
	pass
	

func _on_import_button_pressed():
	$FileDialog.popup_centered()
	
func validate_grid_data(data):
	return true
	
func _on_file_dialog_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var content = file.get_as_text()
		var parse_result = json.parse(content)
		if parse_result == OK:
			var grid_data = json.data
			# Validate the imported grid
			if validate_grid_data(grid_data):
				print("Grid imported:", grid_data)
				
				# Store the grid in the Global singleton
				Global.custom_grid = grid_data
				
				# Navigate to the game scene
				get_tree().change_scene("res://game.tscn")
			else:
				print("Invalid grid format!")
	else:
		print("File not found!")
