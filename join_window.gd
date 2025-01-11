extends Window
signal join_game(adress)

func _on_button_pressed():
	var adress = $Control/VBoxContainer/LineEdit.text
	if adress == "":
		adress = "127.0.0.1"
	$Control/VBoxContainer/LineEdit.hide()
	$Control/VBoxContainer/Button.hide()
	$Control/VBoxContainer/Label.text = "Connecting..."
	join_game.emit(adress)
