extends Control


func _on_salir_pressed() -> void:
	get_tree().quit()


func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/main.tscn")


func _on_como_jugar_pressed() -> void:
	pass # Replace with function body.


func _on_creditos_pressed() -> void:
	pass # Replace with function body.
