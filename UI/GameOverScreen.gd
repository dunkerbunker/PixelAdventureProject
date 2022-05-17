extends CanvasLayer


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_RestartButton_pressed():
	get_tree().change_scene("res://Maps/Level1.tscn")
