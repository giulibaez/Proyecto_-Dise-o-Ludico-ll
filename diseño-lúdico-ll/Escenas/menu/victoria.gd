extends Control


func _on_volver_al_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/menu/menu.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
