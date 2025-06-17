extends Node2D

@export var world_size: Vector2i = Vector2i(8, 8)
@export var number_of_rooms: int = 5
@export var min_enemies: int = 2  
@export var max_enemies: int = 4
@onready var camera = $Camera2D
var room_scene_paths = {
	"cell": "res://Escenas/rooms/roomCell.tscn",
	"main": "res://Escenas/rooms/room_main.tscn",
	"lab": "res://Escenas/rooms/room_lab.tscn",
	"ext": "res://Escenas/rooms/room_ext.tscn"
}
var enemy_scene_path = "res://Escenas/enemies/enemy.tscn"  # Nuevo: ruta de la escena del enemigo

var rooms = []
var taken_position: Array = []
var grid_size_x: int
var grid_size_y: int
var room_size: Vector2 = Vector2(768, 512)
var map_initialized: bool = false
# Resto de las funciones (move_camera_to_room, is_position_valid, new_position, etc.) permanecen sin cambios


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

	# Nuevo: decidir cuántos enemigos instanciar
	var total_enemies = randi_range(min_enemies, max_enemies)
	global.enemigos_totales = total_enemies  # Actualizar el conteo global
	var enemies_placed = 0

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

		# Nuevo: instanciar enemigos en las habitaciones (excepto en la inicial)
		if pos != origin and enemies_placed < total_enemies:
			var enemy_scene = load(enemy_scene_path)
			if enemy_scene:
				var enemy_instance = enemy_scene.instantiate()
				# Posición aleatoria dentro de la habitación (ajusta según el tamaño)
				var enemy_offset = Vector2(randi_range(50, room_size.x - 50), randi_range(50, room_size.y - 50))
				enemy_instance.position = physical_pos + enemy_offset
				add_child(enemy_instance)
				enemies_placed += 1
				print("Enemigo instanciado en habitación tipo ", room_type, " en posición: ", enemy_instance.position)
			else:
				print("ERROR: No se pudo cargar la escena del enemigo: ", enemy_scene_path)

	# Asegurar que se instancien todos los enemigos planeados
	while enemies_placed < total_enemies:
		var random_room_pos = taken_position[randi() % taken_position.size()]
		if random_room_pos != origin:  # Evitar la habitación inicial
			var enemy_scene = load(enemy_scene_path)
			if enemy_scene:
				var enemy_instance = enemy_scene.instantiate()
				var x = random_room_pos.x + grid_size_x
				var y = random_room_pos.y + grid_size_y
				var physical_pos = Vector2(random_room_pos.x * room_size.x, random_room_pos.y * room_size.y) + Vector2(grid_size_x * room_size.x, grid_size_y * room_size.y)
				var enemy_offset = Vector2(randi_range(50, room_size.x - 50), randi_range(50, room_size.y - 50))
				enemy_instance.position = physical_pos + enemy_offset
				add_child(enemy_instance)
				enemies_placed += 1
				print("Enemigo adicional instanciado en habitación en posición: ", enemy_instance.position)
			else:
				print("ERROR: No se pudo cargar la escena del enemigo: ", enemy_scene_path)

	var player_scene = load("res://Escenas/player/Player.tscn")
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

	conectar_puertas()

func move_camera_to_room(pos: Vector2i):
	var target_pos = Vector2(pos.x * room_size.x, pos.y * room_size.y) + Vector2(grid_size_x * room_size.x, grid_size_y * room_size.y) + room_size / 2
	camera.position = target_pos

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
