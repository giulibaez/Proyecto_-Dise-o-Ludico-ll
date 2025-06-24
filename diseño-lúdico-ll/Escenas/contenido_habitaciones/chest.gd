extends StaticBody2D

@onready var area: Area2D = $ChestArea
var has_dropped_item: bool = false  # Evitar que el cofre suelte múltiples ítems
var heart_scene_path: String = "res://Escenas/contenido_habitaciones/heal.tscn"



func _on_area_2d_body_entered(body: CharacterBody2D) -> void:
	print("cuerpito")
	if body.is_in_group("player") and not has_dropped_item:
		var heart_scene = load(heart_scene_path)
		if heart_scene:
			var heart_instance = heart_scene.instantiate()
			heart_instance.position = position + Vector2(0, -100)  # Colocar el corazón encima del cofre
			get_parent().add_child(heart_instance)
			has_dropped_item = true
			print("Corazón soltado por cofre en posición: ", heart_instance.position)
		else:
			print("ERROR: No se pudo cargar la escena del corazón: ", heart_scene_path)
