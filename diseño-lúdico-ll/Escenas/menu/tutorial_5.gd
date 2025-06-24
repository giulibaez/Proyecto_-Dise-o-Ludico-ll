extends Control

signal tutorial_completed

func _on_texture_button_pressed() -> void:
	print("Botón presionado en tutorial_5.tscn, emitiendo tutorial_completed")
	emit_signal("tutorial_completed")
	queue_free()
