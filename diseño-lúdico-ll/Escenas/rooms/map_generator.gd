extends Node2D

# Tamaño de la cuadrícula lógica del mapa (exportado para edición en el editor de Godot)
@export var world_size: Vector2i = Vector2i(8, 8)
# Número de habitaciones a generar (exportado para edición en el editor)
@export var number_of_rooms: int = 10
# Diccionario con las rutas a las escenas de las habitaciones
var room_scene_paths = {
	"cell": "res://Escenas/rooms/roomCell.tscn",
	"lab": "res://Escenas/rooms/room_lab.tscn"
}

# Matriz que almacena los datos de las habitaciones en la cuadrícula
var rooms = []
# Lista de posiciones lógicas ocupadas
var taken_position: Array = []
# Dimensiones de la cuadrícula
var grid_size_x: int
var grid_size_y: int
# Tamaño físico de cada habitación en píxeles
var room_size: Vector2 = Vector2(384, 256)
# Bandera para evitar múltiples inicializaciones
var map_initialized: bool = false

# Método que se ejecuta cuando el nodo entra en la escena
func _ready():
	# Evita ejecutar _ready más de una vez
	if map_initialized:
		print("Advertencia: Intento de ejecutar _ready más de una vez, abortando")
		return
	
	# Limita el número de habitaciones al tamaño máximo de la cuadrícula
	if number_of_rooms >= (world_size.x * 2) * (world_size.y * 2):
		number_of_rooms = int(world_size.x * 2) * (world_size.y * 2)
	# Inicializa las dimensiones de la cuadrícula
	grid_size_x = world_size.x
	grid_size_y = world_size.y
	# Genera el mapa
	generate_map()
	# Marca el mapa como inicializado
	map_initialized = true

# Genera el mapa proceduralmente
func generate_map():
	# Limpia las listas de habitaciones y posiciones ocupadas
	rooms.clear()
	taken_position.clear()
	
	# Inicializa la matriz lógica con celdas vacías (null)
	rooms = []
	for i in range(grid_size_x * 2):
		var row = []
		for j in range(grid_size_y * 2):
			row.append(null)
		rooms.append(row)

	# Coloca la habitación inicial en el centro lógico (0,0)
	var origin = Vector2i.ZERO
	var center_x = grid_size_x
	var center_y = grid_size_y
	rooms[center_x][center_y] = {"grid_pos": origin, "type": 1} # Tipo 1 = "cell"
	taken_position.append(origin)
	print("Habitación inicial colocada en posición lógica: ", origin, " (grilla: ", center_x, ",", center_y, ")")

	# Genera el resto de las habitaciones
	var random_compare_start = 0.2 # Probabilidad inicial para aceptar posiciones con múltiples vecinos
	var random_compare_end = 0.01  # Probabilidad final
	for i in range(number_of_rooms - 1):
		# Interpola la probabilidad para favorecer mapas más dispersos al inicio
		var random_compare = lerp(random_compare_start, random_compare_end, float(i) / (number_of_rooms - 1))
		var check_pos = new_position() # Obtiene una posición candidata

		# Verifica si la posición es inválida o ya está ocupada
		if not is_position_valid(check_pos) or taken_position.has(check_pos):
			print("Posición inválida o ya ocupada: ", check_pos)
			continue

		# Intenta encontrar una posición con pocos vecinos
		var iterations = 0
		while number_of_neighbors(check_pos) > 1 and randi() % 100 > random_compare * 100 and iterations < 50:
			check_pos = selective_new_position()
			if not is_position_valid(check_pos) or taken_position.has(check_pos):
				print("selective_new_position devolvió posición inválida o ocupada: ", check_pos)
				break
			iterations += 1
			if iterations >= 50:
				print("Advertencia: No se encontró posición válida tras 50 intentos")
				break

		# Asigna la habitación si la posición es válida y no está ocupada
		if is_position_valid(check_pos) and not taken_position.has(check_pos):
			var grid_x = check_pos.x + grid_size_x
			var grid_y = check_pos.y + grid_size_y
			rooms[grid_x][grid_y] = {"grid_pos": check_pos, "type": 0} # Tipo 0 = "lab"
			taken_position.append(check_pos)
			print("Habitación colocada en posición lógica: ", check_pos, " (grilla: ", grid_x, ",", grid_y, ")")
		else:
			print("No se asignó habitación en posición: ", check_pos)

	# Instancia las habitaciones en la escena
	for pos in taken_position:
		var x = pos.x + grid_size_x
		var y = pos.y + grid_size_y
		var room_data = rooms[x][y]
		# Verifica si los datos de la habitación son válidos
		if room_data == null:
			print("ERROR: room_data en (", x, ",", y, ") es null. Posición lógica: ", pos)
			continue

		# Determina el tipo de habitación ("cell" o "lab")
		var room_type = "cell" if room_data["type"] == 1 else "lab"
		var scene_path = room_scene_paths[room_type]
		var room_scene = load(scene_path)
		# Verifica si la escena se cargó correctamente
		if not room_scene:
			print("ERROR: No se pudo cargar la escena: ", scene_path)
			continue

		# Instancia la escena de la habitación
		var room_instance = room_scene.instantiate()
		if not room_instance:
			print("ERROR: No se pudo instanciar la escena: ", scene_path)
			continue

		# Calcula la posición física desplazada para que todas las posiciones sean positivas
		var physical_pos = Vector2(pos.x * room_size.x, pos.y * room_size.y) + Vector2(grid_size_x * room_size.x, grid_size_y * room_size.y)
		room_instance.position = physical_pos
		print("Instanciando habitación tipo ", room_type, " en posición física: ", physical_pos)

		# Agrega la habitación como hijo del nodo actual
		add_child(room_instance)

		# Ejecuta el método generate si existe
		if room_instance.has_method("generate"):
			room_instance.generate()

		# Obtiene los nodos de conectores y los almacena
		var connectors = {
			"top": room_instance.get_node_or_null("ConnectorT"),
			"down": room_instance.get_node_or_null("ConnectorD"),
			"right": room_instance.get_node_or_null("ConnectorR"),
			"left": room_instance.get_node_or_null("ConnectorL")
		}
		room_instance.set("connectors", connectors)
		rooms[x][y]["instance"] = room_instance

# Verifica si una posición lógica está dentro de los límites de la cuadrícula
func is_position_valid(pos: Vector2i) -> bool:
	var x = pos.x + grid_size_x
	var y = pos.y + grid_size_y
	var valid = x >= 0 and x < grid_size_x * 2 and y >= 0 and y < grid_size_y * 2
	if not valid:
		print("Posición inválida: ", pos, " (grilla: ", x, ",", y, ")")
	return valid

# Genera una nueva posición lógica adyacente a una posición ocupada
func new_position() -> Vector2i:
	var index = randi() % taken_position.size()
	var base_pos = taken_position[index]
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	var dir = directions[randi() % directions.size()]
	var new_pos = base_pos + dir
	if is_position_valid(new_pos) and not taken_position.has(new_pos):
		return new_pos
	return selective_new_position()

# Cuenta el número de vecinos ocupados de una posición
func number_of_neighbors(pos: Vector2i) -> int:
	var count = 0
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	for dir in directions:
		var neighbor = pos + dir
		if taken_position.has(neighbor):
			count += 1
	return count

# Busca una posición válida y no ocupada con un máximo de 50 intentos
func selective_new_position() -> Vector2i:
	for i in range(50):
		var pos = new_position()
		if is_position_valid(pos) and not taken_position.has(pos):
			return pos
	print("selective_new_position no encontró posición válida, devolviendo Vector2i.ZERO")
	return Vector2i.ZERO


#poner la cama en el jugador e intanciar al jugador en el 0,0/ probar 
