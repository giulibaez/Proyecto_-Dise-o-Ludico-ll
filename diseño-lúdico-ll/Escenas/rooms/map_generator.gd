extends Node2D

@export var world_size: Vector2i = Vector2i(8, 8)
@export var number_of_rooms: int = 5
@export var min_enemies: int = 2  
@export var max_enemies: int = 3
@onready var camera = $Camera2D
var room_scene_paths = {
	"cell": "res://Escenas/rooms/roomCell.tscn",
	"main": "res://Escenas/rooms/room_main.tscn",
	"lab": "res://Escenas/rooms/room_lab.tscn",
	"ext": "res://Escenas/rooms/room_ext.tscn"
}
var enemy_scene_path = "res://Escenas/enemies/enemy.tscn" 
var tutorial_scene_path = "res://Escenas/menu/tutorial_controller.tscn"
var enemy_positions: Array = []  # Para almacenar las posiciones de los enemigos
var rooms = []
var taken_position: Array = []
var grid_size_x: int
var grid_size_y: int
var room_size: Vector2 = Vector2(768, 512)
var map_initialized: bool = false
var rooms_without_enemies: Array = []  # Almacena posiciones de habitaciones sin enemigos
var candados = {}  # Diccionario para almacenar {candado: {position: Vector2, direction: String}}

var candado_scene_path = "res://Escenas/contenido_habitaciones/candado.tscn"
var directions = {
		"top": Vector2i(0, -1),
		"down": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0)
	}
var opposite_directions = {
		"top": "down",
		"down": "top",
		"left": "right",
		"right": "left"
	}

func _ready():
	if map_initialized:
		print("Advertencia: Intento de ejecutar _ready más de una vez, abortando")
		return
	
	if number_of_rooms >= (world_size.x * 2) * (world_size.y * 2):
		number_of_rooms = int(world_size.x * 2) * (world_size.y * 2)
	grid_size_x = world_size.x
	grid_size_y = world_size.y
	generate_map()
	map_initialized = true 

func generate_map():
	global.reset()
	rooms.clear()
	taken_position.clear()
	enemy_positions.clear()

	rooms = []
	for i in range(grid_size_x * 2):
		var row = []
		for j in range(grid_size_y * 2):
			row.append(null)
		rooms.append(row)

	var origin = Vector2i.ZERO
	var center_x = grid_size_x
	var center_y = grid_size_y
	rooms[center_x][center_y] = {"grid_pos": origin, "type": "cell"}
	taken_position.append(origin)
	print("Habitación inicial colocada en posición lógica: ", origin, " (grilla: ", center_x, ",", center_y, ")")

	var room_types = ["main", "main", "lab", "ext"]
	var type_index = 0
	for i in range(number_of_rooms - 1):
		var random_compare_start = 0.2
		var random_compare_end = 0.01
		var random_compare = lerp(random_compare_start, random_compare_end, float(i) / (number_of_rooms - 1))
		var check_pos = new_position()

		if not is_position_valid(check_pos) or taken_position.has(check_pos):
			print("Posición inválida o ya ocupada: ", check_pos)
			continue

		var iterations = 0
		while number_of_neighbors(check_pos) > 1 and randf() < random_compare and iterations < 50:
			check_pos = selective_new_position()
			if not is_position_valid(check_pos) or taken_position.has(check_pos):
				print("selective_new_position devolvió posición inválida o ocupada: ", check_pos)
				break
			iterations += 1
			if iterations >= 50:
				print("Advertencia: No se encontró posición válida tras 50 intentos")
				break

		if is_position_valid(check_pos) and not taken_position.has(check_pos):
			var grid_x = check_pos.x + grid_size_x
			var grid_y = check_pos.y + grid_size_y
			var room_type = room_types[type_index % room_types.size()]
			type_index += 1
			rooms[grid_x][grid_y] = {"grid_pos": check_pos, "type": room_type}
			taken_position.append(check_pos)
			print("Habitación colocada en posición lógica: ", check_pos, " (grilla: ", grid_x, ",", grid_y, "), tipo: ", room_type)
		else:
			print("No se asignó habitación en posición: ", check_pos)

	# Decidir cuántos enemigos instanciar
	var total_enemies = randi_range(min_enemies, max_enemies)
	global.enemigos_totales = total_enemies
	var enemies_placed = 0
	var dark_rooms = []  # Lista para almacenar posiciones de habitaciones oscurecidas

	# Instanciar habitaciones
	for pos in taken_position:
		var x = pos.x + grid_size_x
		var y = pos.y + grid_size_y
		var room_data = rooms[x][y]
		if room_data == null:
			print("ERROR: room_data en (", x, ",", y, ") es null. Posición lógica: ", pos)
			continue

		var room_type = room_data["type"]
		var scene_path = room_scene_paths[room_type]
		var room_scene = load(scene_path)
		if not room_scene:
			print("ERROR: No se pudo cargar la escena: ", scene_path)
			continue

		var room_instance = room_scene.instantiate()
		if not room_instance:
			print("ERROR: No se pudo instanciar la escena: ", scene_path)
			continue

		var physical_pos = Vector2(pos.x * room_size.x, pos.y * room_size.y) + Vector2(grid_size_x * room_size.x, grid_size_y * room_size.y)
		room_instance.position = physical_pos
		room_instance.room_position = pos
		print("Instanciando habitación tipo ", room_type, " en posición física: ", physical_pos)

		add_child(room_instance)
		if room_instance.has_method("generate"):
			room_instance.generate()

		rooms[x][y]["instance"] = room_instance

		# Conectar la señal del papel en la habitación inicial
		if pos == origin:
			for child in room_instance.get_children():
				if child.is_in_group("paper"):
					if child.has_signal("tutorial_triggered"):
						child.connect("tutorial_triggered", _on_tutorial_triggered)
						print("Señal tutorial_triggered conectado para el papel en la sala inicial")
					else:
						print("ERROR: El nodo Paper no tiene la señal tutorial_triggered")

# Instanciar enemigos en las habitaciones (excepto en la inicial y room_ext)
		if pos != origin and enemies_placed < total_enemies and room_type != "ext":
			var enemy_scene = load(enemy_scene_path)
			if enemy_scene:
				var enemy_instance = enemy_scene.instantiate()
				var enemy_offset = Vector2(randi_range(50, room_size.x - 50), randi_range(50, room_size.y - 50))
				enemy_instance.position = physical_pos + enemy_offset
				add_child(enemy_instance)
				enemies_placed += 1
				enemy_positions.append(pos)
				print("Enemigo instanciado en habitación tipo ", room_type, " en posición: ", enemy_instance.position)
			else:
				print("ERROR: No se pudo cargar la escena del enemigo: ", enemy_scene_path)


# Asegurar que se instancien todos los enemigos planeados
	while enemies_placed < total_enemies:
		var random_room_pos = taken_position[randi() % taken_position.size()]
		var x = random_room_pos.x + grid_size_x
		var y = random_room_pos.y + grid_size_y
		var room_data = rooms[x][y]
		if random_room_pos != origin and room_data["type"] != "ext":
			var enemy_scene = load(enemy_scene_path)
			if enemy_scene:
				var enemy_instance = enemy_scene.instantiate()
				var physical_pos = Vector2(random_room_pos.x * room_size.x, random_room_pos.y * room_size.y) + Vector2(grid_size_x * room_size.x, grid_size_y * room_size.y)
				var enemy_offset = Vector2(randi_range(50, room_size.x - 50), randi_range(50, room_size.y - 50))
				enemy_instance.position = physical_pos + enemy_offset
				add_child(enemy_instance)
				enemies_placed += 1
				enemy_positions.append(random_room_pos)
				print("Enemigo adicional instanciado en habitación en posición: ", enemy_instance.position)
			else:
				print("ERROR: No se pudo cargar la escena del enemigo: ", enemy_scene_path)

	for pos in taken_position:
		if pos != origin and not enemy_positions.has(pos):
			rooms_without_enemies.append(pos)
			print("Habitación sin enemigos detectada en posición lógica: ", pos)

	var player_scene = load("res://Escenas/player/player.tscn")
	var origin_physical_pos = Vector2(origin.x * room_size.x, origin.y * room_size.y) + Vector2(grid_size_x * room_size.x, grid_size_y * room_size.y)
	if player_scene:
		var player_instance = player_scene.instantiate()
		player_instance.position = origin_physical_pos + Vector2(64, 64)
		add_child(player_instance)
		print("Jugador instanciado en posición: ", player_instance.position)
	else:
		print("ERROR: No se pudo cargar la escena del jugador.")

	camera.position = origin_physical_pos + room_size / 2
	camera.make_current()

	# Encontrar y oscurecer habitaciones adyacentes a room_ext
	var room_ext_pos = null
	for pos in taken_position:
		var x = pos.x + grid_size_x
		var y = pos.y + grid_size_y
		var room_data = rooms[x][y]
		if room_data and room_data["type"] == "ext":
			room_ext_pos = pos
			break

	if room_ext_pos:
		var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
		for dir in directions:
			var adjacent_pos = room_ext_pos + dir
			if taken_position.has(adjacent_pos):
				var adj_x = adjacent_pos.x + grid_size_x
				var adj_y = adjacent_pos.y + grid_size_y
				var adjacent_room_data = rooms[adj_x][adj_y]
				if adjacent_room_data and adjacent_room_data["type"] != "ext":
					var adjacent_room = rooms[adj_x][adj_y]["instance"]
					if adjacent_room:
						adjacent_room.modulate = Color(0.3, 0.3, 0.3)
						print("Habitación adyacente a room_ext oscurecida en posición: ", adjacent_room.position)
						dark_rooms.append(adjacent_pos)  # Guardar posición de habitación oscurecida
						# Ocultar enemigos en esta habitación
						print("Buscando enemigos en habitación en posición: ", adjacent_room.position)
						for child in get_children():
							if child.is_in_group("enemy"):
								var distance = child.position.distance_to(adjacent_room.position)
								print("Enemigo encontrado en posición: ", child.position, ", distancia: ", distance)
								if distance < room_size.x * 0.75:
									child.is_in_dark_room = true  # Marcar como en habitación oscurecida
									child.visible = false  # Ocultar enemigo
									print("Enemigo ocultado en posición: ", child.position)

	conectar_puertas()


func _on_tutorial_triggered():
	# Crear o obtener un CanvasLayer para el tutorial
	var canvas_layer = $TutorialCanvasLayer
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "TutorialCanvasLayer"
		add_child(canvas_layer)
	
	var tutorial_controller_scene = load(tutorial_scene_path)
	if tutorial_controller_scene:
		var tutorial_controller_instance = tutorial_controller_scene.instantiate()
		tutorial_controller_instance.z_index = 100 # Ajusta según necesidad
		canvas_layer.add_child(tutorial_controller_instance)
		if tutorial_controller_instance.has_signal("tutorial_completed"):
			tutorial_controller_instance.connect("tutorial_completed", _on_tutorial_completed)

			print("Controlador de tutorial iniciado y juego pausado en CanvasLayer")
		else:
			print("ERROR: El controlador no tiene la señal tutorial_completed")
	else:
		print("ERROR: No se pudo cargar la escena del controlador de tutoriales: ", tutorial_scene_path)

func _on_tutorial_completed():
	get_tree().paused = false
	print("Tutorial completado y juego reanudado")
	
func move_camera_to_room(pos: Vector2i):
	var target_pos = Vector2(pos.x * room_size.x, pos.y * room_size.y) + Vector2(grid_size_x * room_size.x, grid_size_y * room_size.y) + room_size / 2
	camera.position = target_pos

	# Verificar si la habitación no tiene enemigos y no tiene un cofre ya instanciado
	if rooms_without_enemies.has(pos):
		var grid_x = pos.x + grid_size_x
		var grid_y = pos.y + grid_size_y
		var room_data = rooms[grid_x][grid_y]
		if room_data and not room_data.has("chest_instance"):
			var chest_scene = load("res://Escenas/contenido_habitaciones/chest.tscn") 
			if chest_scene:
				var chest_instance = chest_scene.instantiate()
				var physical_pos = Vector2(pos.x * room_size.x, pos.y * room_size.y) + Vector2(grid_size_x * room_size.x, grid_size_y * room_size.y)
				var chest_offset = Vector2(room_size.x / 2, room_size.y / 2)
				chest_instance.position = physical_pos + chest_offset
				add_child(chest_instance)
				room_data["chest_instance"] = chest_instance  
				print("Cofre instanciado en habitación sin enemigos en posición: ", chest_instance.position)
			else:
				print("ERROR: No se pudo cargar la escena del cofre: res://Escenas/objects/chest.tscn")

func is_position_valid(pos: Vector2i) -> bool:
	var x = pos.x + grid_size_x
	var y = pos.y + grid_size_y
	var valid = x >= 0 and x < grid_size_x * 2 and y >= 0 and y < grid_size_y * 2
	if not valid:
		print("Posición inválida: ", pos, " (grilla: ", x, ",", y, ")")
	return valid

func new_position() -> Vector2i:
	var index = randi() % taken_position.size()
	var base_pos = taken_position[index]
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	var dir = directions[randi() % directions.size()]
	var new_pos = base_pos + dir
	if is_position_valid(new_pos) and not taken_position.has(new_pos):
		return new_pos
	return selective_new_position()

func number_of_neighbors(pos: Vector2i) -> int:
	var count = 0
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	for dir in directions:
		var neighbor = pos + dir
		if taken_position.has(neighbor):
			count += 1
	return count

func selective_new_position() -> Vector2i:
	for i in range(50):
		var pos = new_position()
		if is_position_valid(pos) and not taken_position.has(pos):
			return pos
	print("selective_new_position no encontró posición válida, devolviendo Vector2i.ZERO")
	return Vector2i.ZERO


func conectar_puertas():
	var tile_size = Vector2(64, 64)  
	for pos in taken_position:
		var x = pos.x + grid_size_x
		var y = pos.y + grid_size_y
		var room_data = rooms[x][y]
		if room_data == null or not "instance" in room_data:
			continue

		var instance = room_data["instance"]
		for dir_name in directions.keys():
			var neighbor_pos = pos + directions[dir_name]
			if taken_position.has(neighbor_pos):
				var nx = neighbor_pos.x + grid_size_x
				var ny = neighbor_pos.y + grid_size_y
				var neighbor_data = rooms[nx][ny]
				if neighbor_data and "instance" in neighbor_data:
					instance.abrir_puerta(dir_name, Vector2i.ZERO, 0)
					var neighbor_instance = neighbor_data["instance"]
					neighbor_instance.abrir_puerta(opposite_directions[dir_name], Vector2i.ZERO, 0)

					# Verificar si la habitación vecina es de tipo "ext"
					if neighbor_data["type"] == "ext":
						var candado_scene = load(candado_scene_path)
						if candado_scene:
							var candado_instance = candado_scene.instantiate()
							var door_cell_pos = Vector2i.ZERO
							match dir_name:
								"top":
									door_cell_pos = Vector2i(instance.size.x / 2, 0)
								"down":
									door_cell_pos = Vector2i(instance.size.x / 2, instance.size.y - 1)
								"left":
									door_cell_pos = Vector2i(0, instance.size.y / 2)
								"right":
									door_cell_pos = Vector2i(instance.size.x - 1, instance.size.y / 2)
							var door_pos_pixels = instance.position + (Vector2(door_cell_pos) * tile_size) + (tile_size / 2)
							candado_instance.position = door_pos_pixels
							add_child(candado_instance)
							candados[candado_instance] = {"position": door_pos_pixels, "direction": dir_name}
							print("Candado instanciado en puerta ", dir_name, " de la habitación adyacente en posición: ", candado_instance.position)
						else:
							print("ERROR: No se pudo cargar la escena del candado: ", candado_scene_path)

func abrir_candados():
	for candado in candados.keys():
		if is_instance_valid(candado):
			candado.get_node("AnimatedSprite2D").frame = 1  # Cambia al frame "abierto"
			candado.queue_free()  # Elimina el candado
	candados.clear()  # Limpia el diccionario
	print("Candados abiertos y eliminados")


	for pos in taken_position:
		var x = pos.x + grid_size_x
		var y = pos.y + grid_size_y
		var room_data = rooms[x][y]
		if room_data == null or not "instance" in room_data:
			continue

		var instance = room_data["instance"]
		for dir_name in directions.keys():
			var neighbor_pos = pos + directions[dir_name]
			if taken_position.has(neighbor_pos):
				var nx = neighbor_pos.x + grid_size_x
				var ny = neighbor_pos.y + grid_size_y
				var neighbor_data = rooms[nx][ny]
				if neighbor_data and "instance" in neighbor_data:
					instance.abrir_puerta(dir_name, Vector2i.ZERO, 0)
					var neighbor_instance = neighbor_data["instance"]
					neighbor_instance.abrir_puerta(opposite_directions[dir_name], Vector2i.ZERO, 0)
