extends Control

signal tutorial_completed

var tutorial_scenes = [
	"res://Escenas/menu/tutorial.tscn",
	"res://Escenas/menu/tutorial_2.tscn",
	"res://Escenas/menu/tutorial_3.tscn",
	"res://Escenas/menu/tutorial_4.tscn",
	"res://Escenas/menu/tutorial_5.tscn"
]
var current_tutorial_index = 0
var current_tutorial_instance = null

func _ready():
	load_tutorial(0)

func load_tutorial(index: int):
	if current_tutorial_instance:
		current_tutorial_instance.queue_free()
		current_tutorial_instance = null
	
	if index >= tutorial_scenes.size():
		emit_signal("tutorial_completed")
		queue_free()
		return
	
	var tutorial_scene = load(tutorial_scenes[index])
	if tutorial_scene:
		current_tutorial_instance = tutorial_scene.instantiate()
		current_tutorial_instance.z_index = 100
		add_child(current_tutorial_instance)
		if current_tutorial_instance.has_signal("next_tutorial"):
			current_tutorial_instance.connect("next_tutorial", _on_next_tutorial)
			print("Señal next_tutorial conectada para tutorial ", index + 1)
		if current_tutorial_instance.has_signal("tutorial_completed"):
			current_tutorial_instance.connect("tutorial_completed", _on_tutorial_completed)
			print("Señal tutorial_completed conectada para tutorial ", index + 1)
		print("Tutorial ", index + 1, " cargado: ", tutorial_scenes[index])
		print("Instancia del tutorial añadida: ", current_tutorial_instance.name)
		print("Posición: ", current_tutorial_instance.position)
		print("Z_index: ", current_tutorial_instance.z_index)
		print("Visible: ", current_tutorial_instance.visible)
	else:
		print("ERROR: No se pudo cargar la escena del tutorial: ", tutorial_scenes[index])

func _on_next_tutorial():
	print("Recibida señal next_tutorial, avanzando al siguiente tutorial: ", current_tutorial_index + 1)
	current_tutorial_index += 1
	load_tutorial(current_tutorial_index)

func _on_tutorial_completed():
	print("Tutorial completado, emitiendo señal")
	emit_signal("tutorial_completed")
	queue_free()
