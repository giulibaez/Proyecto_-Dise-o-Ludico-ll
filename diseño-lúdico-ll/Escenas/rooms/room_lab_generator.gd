extends Node2D

@export var room_type: String = "lab"
@onready var floor_map: TileMapLayer = $TileMap/Floors
@onready var wall_map: TileMapLayer = $TileMap/Walls
@export var room_position: Vector2i = Vector2i.ZERO
@export var door_tiles: Dictionary = {
	"top": Vector2i(4,0),
	"down": Vector2i(4,2),
	"left": Vector2i(3, 1),
	"right": Vector2i(5, 1)
}

var object_scene_paths = {
	"rock": "res://Escenas/contenido_habitaciones/rock.tscn",
	"tumor":"res://Escenas/contenido_habitaciones/tumor.tscn",
	"dead_player": "res://Escenas/contenido_habitaciones/dead_player.tscn",
	"pozo" : "res://Escenas/contenido_habitaciones/pozo.tscn"
}
var room_object_chances = {
	"ext": ["dead_player"],  # Objetos típicos para room_ext
	"cell": [ "rock","tumor", "dead_player"],   # Objetos típicos para room_cell
	"main": ["rock", "pozo"],               # Objetos típicos para room_main
	"lab": ["dead_player", "rock", "tumor"]  # Objetos típicos para room_lab
}

@export var floor_tiles: Array[Vector2i] = [Vector2i(1, 1), Vector2i(4, 1)]
@export var floor_tile_percent: Array[float] = [0.9, 0.1]
@export var size: Vector2i = Vector2i(12, 8)

func _ready() -> void:
	generate()

func generate():
	var rand = RandomNumberGenerator.new()
	rand.randomize()
	for x in size.x:
		for y in size.y:
			var position = Vector2i(x, y)
			if x == 0 and y == 0:
				wall_map.set_cell(position, 0, Vector2i(0, 0)) # Esquina superior izquierda
			elif x == size.x - 1 and y == 0:
				wall_map.set_cell(position, 0, Vector2i(2, 0)) # Esquina superior derecha
			elif x == 0 and y == size.y - 1:
				wall_map.set_cell(position, 0, Vector2i(0, 2)) # Esquina inferior izquierda
			elif x == size.x - 1 and y == size.y - 1:
				wall_map.set_cell(position, 0, Vector2i(2, 2)) # Esquina inferior derecha
			elif y == 0:
				wall_map.set_cell(position, 0, Vector2i(1, 0)) # Borde superior
			elif y == size.y - 1:
				wall_map.set_cell(position, 0, Vector2i(1, 2)) # Borde inferior
			elif x == 0:
				wall_map.set_cell(position, 0, Vector2i(0, 1)) # Borde izquierdo
			elif x == size.x - 1:
				wall_map.set_cell(position, 0, Vector2i(2, 1)) # Borde derecho
			else:
				var tile_position = select_percent_tile(rand)
				floor_map.set_cell(position, 0, tile_position)
	# Instanciar objetos con colisión
	var max_objects = 2
	var object_count = rand.randi_range(0, max_objects)
	print("Intentando instanciar ", object_count, " objetos en ", room_type)
	for _i in range(object_count):
		if room_object_chances.has(room_type) and room_object_chances[room_type].size() > 0:
			var available_objects = room_object_chances[room_type]
			var object_type = available_objects[rand.randi() % available_objects.size()]
			var object_scene = load(object_scene_paths[object_type])
			if object_scene:
				var object_instance = object_scene.instantiate()
				var object_offset = Vector2(rand.randi_range(32, (size.x - 2) * 64), rand.randi_range(32, (size.y - 2) * 64))
				object_instance.position = position + object_offset  # Usar la posición del nodo Room2D
				var parent = get_parent()
				if parent:
					parent.add_child(object_instance)
					print("Objeto ", object_type, " instanciado en ", room_type, " en posición: ", object_instance.position)
				else:
					print("Error: No se encontró el nodo padre")
			else:
				print("ERROR: No se pudo cargar la escena del objeto: ", object_scene_paths[object_type])

func select_percent_tile(rand: RandomNumberGenerator) -> Vector2i:
	var total_percent = 0.0
	for percent in floor_tile_percent:
		total_percent += percent
	var random_value = rand.randf() * total_percent
	var current_percent = 0.0
	
	for i in range(floor_tile_percent.size()):
		current_percent += floor_tile_percent[i]
		if random_value <= current_percent:
			return floor_tiles[i]
	
	return floor_tiles[0]

func abrir_puerta(direccion: String, tile: Vector2i, source_id: int):
	var cell_pos: Vector2i
	# Ajusta la posición de la puerta para que sea más natural (centro del borde, pero alineada)
	match direccion:
		"top":
			cell_pos = Vector2i(size.x / 2, 0)
		"down":
			cell_pos = Vector2i(size.x / 2, size.y - 1)
		"left":
			cell_pos = Vector2i(0, size.y / 2)
		"right":
			cell_pos = Vector2i(size.x - 1, size.y / 2)
		_:
			print("ERROR: Dirección inválida para abrir puerta: ", direccion)
			return
	
	# Usa el tile específico para la dirección si está en door_tiles, de lo contrario usa el tile proporcionado
	var door_tile = door_tiles.get(direccion, tile)
	
	# Verifica si el tile ya está colocado
	var current_tile = wall_map.get_cell_atlas_coords(cell_pos)
	if current_tile == door_tile:
		print("Advertencia: Puerta ya colocada en ", cell_pos, " para dirección ", direccion)
		return
	
	# Coloca el tile de la puerta
	wall_map.set_cell(cell_pos, source_id, door_tile)
	print("Puerta abierta en ", room_type, " en posición ", cell_pos, " (dirección: ", direccion, ", tile: ", door_tile, ", source_id: ", source_id, ")")
