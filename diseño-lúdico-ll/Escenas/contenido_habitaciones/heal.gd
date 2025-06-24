extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("player"):
		if body.current_health < body.max_health:
			body.current_health = min(body.current_health + 1, body.max_health)
			body.update_hearts_display()
			print("Jugador curado, salud actual: ", body.current_health)
			queue_free()  # Eliminar el corazón tras ser recogido
		else:
			print("Jugador ya tiene salud máxima, corazón no recogido")
