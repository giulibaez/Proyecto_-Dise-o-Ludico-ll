extends Node2D

# Diccionario de escenas
var room_scene_paths = {
	"cell": "res://Escenas/rooms/roomCell.tscn",
	"lab": "res://Escenas/rooms/room_lab.tscn"
}

#lista vacia para habitaciones intnasciadas
var rooms = []


func _ready():
	generate_map()

func generate_map():
	var positions = [
		Vector2(0, 0),
		Vector2(256, 0),
		Vector2(0, 256),
		Vector2(256, 256)
	]
	
	var room_types = ["cell", "lab"]
	
	for i in range(room_types.size()):
		var room_type = room_types[i]
		var scene_path = room_scene_paths[room_type]
		var room_scene = load(scene_path)
		var room_instance = room_scene.instantiate()
		
		# Posicionar la habitación en la escena principal según la grilla
		room_instance.position = positions[i]
		
		add_child(room_instance)
		
		# Llamar a la función generate() dei la habitación para que genere su contenido
		if room_instance.has_method("generate"):
			room_instance.generate()
		
		rooms.append(room_instance)
