extends Control

signal next_tutorial

func _on_texture_button_pressed() -> void:
	print("Botón presionado en tutorial.tscn, emitiendo next_tutorial")
	emit_signal("next_tutorial")
	await get_tree().create_timer(0.1).timeout  # Espera 0.1 segundos
	queue_free()
