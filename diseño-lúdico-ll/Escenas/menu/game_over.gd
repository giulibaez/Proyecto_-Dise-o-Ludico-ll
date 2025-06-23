extends Control


func _on_volver_a_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/main.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/menu/menu.tscn")
