extends Node2D

# Diccionario de escenas
var room_scene_paths = {
	"cell": "res://Escenas/rooms/roomCell.tscn", #cada clave es un tipo de archivo 
	"lab": "res://Escenas/rooms/room_lab.tscn"
}

#lista vacia para almacenar las habitaciones intnasciadas
var rooms = []


func _ready():
	generate_map()

func generate_map(): # se arma el mapa de habitaciones 
	var positions = [ #posiciones bases; cuadricula 2X2
		Vector2(0, 0),
		Vector2(256, 0),
		Vector2(0, 256),
		Vector2(256, 256)
	]
	
	var room_types = ["cell", "lab"] #lista con los tipos de habitacion, las mimas que guarde en el diccionario
	
	for i in range(room_types.size()): # recorre los indices de las habitaciones asegurnadose de no pasar el tamaño de la lista 
		var room_type = room_types[i] # guarda la habitacion en el indice del bucle
		var scene_path = room_scene_paths[room_type] # verifica si existe una entrada para este tipo 
		var room_scene = load(scene_path) # carga como recurso la escena 
		var room_instance = room_scene.instantiate()#crea una instancia 
		# Posiciona la instancia en la escena principal según la grilla de 2x2
		room_instance.position = positions[i]
		add_child(room_instance)# agrega la habitacion al arbol de nodos 
		# Llamar a la función generate() dei la habitación para que genere su contenido
		if room_instance.has_method("generate"):
			room_instance.generate()
		
		rooms.append(room_instance)# guarda la intancia en la lista de habitaciones 
