extends Node
var player_colors = [
	Color(1, 0, 0),    # Red
	Color(0, 0, 1),    # Blue
	Color(1, 1, 0)  # Yellow
]

var peer_color_map = {1 : Color(1, 0, 1)} 
var custom_grid = {
	"title": "My Custom Bingo Grid",
	"size": { "rows": 5, "columns": 5 },
	"author": "John Doe",
	"description": "A fun custom grid for family bingo night!",
	"grid": [
		["B1", "B2", "B3", "B4", "B5"],
		["I1", "I2", "I3", "I4", "I5"],
		["N1", "N2", "FREE", "N4", "N5"],
		["G1", "G2", "G3", "G4", "G5"],
		["O1", "O2", "O3", "O4", "O5"]
	],
	"date": ""
}

func get_grid_template(rows, columns):
	var grid_template = {
		"title": "",
		"size": { "rows": rows, "columns": columns },
		"author": "",
		"description": "",
		"grid": []
	}
	for i in range(rows):
		grid_template.grid.append([])
		for j in range(columns):
			grid_template.grid[i].append("")
	return grid_template
