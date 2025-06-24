extends Control

signal next_tutorial

func _on_texture_button_pressed() -> void:
	print("Botón presionado en tutorial.tscn, emitiendo next_tutorial")
	emit_signal("next_tutorial")
	queue_free()
