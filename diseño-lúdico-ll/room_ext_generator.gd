extends Node2D

@export var room_type :String = "ext"
@onready var floor_map :TileMapLayer = $Node2D/Floors
@onready var wall_map : TileMapLayer = $Node2D/Walls #referencia a nodo hijo walls
@export var room_position: Vector2i = Vector2i.ZERO #una Mouskeherramienta Misteriosa que nos ayudara mas tarde 


@export var floor_tiles: Array[Vector2i] = [Vector2i(1, 1), Vector2i(4,1)] # Lista de tiles de piso 
@export var floor_tile_percent: Array[float] = [0.9, 0.1] # 90% tile1, 10% tile2
@export var size: Vector2i = Vector2i (12,8)

func _ready() -> void:
	generate_ext() 


func  generate_ext():
	var rand = RandomNumberGenerator.new() #generador de numeritos
	rand.randomize() 
	for x in size.x: #recorre columnas del 0_9
		for y in size.y: #recorre filas 0_9
			var position = Vector2i (x,y) #guarda la coordenada (x,y) como vector de enteros (es un vector de 2 componentes lo uso para representar las cordenadas en la grilla
			if x == 0 and y == 0:
				wall_map.set_cell(position, 0, Vector2i(0, 0)) # esquina superior izquierda
			elif x == size.x - 1 and y == 0:
				wall_map.set_cell(position, 0, Vector2i(2, 0)) # esquina superior derecha
			elif x == 0 and y == size.y - 1:
				wall_map.set_cell(position, 0, Vector2i(0, 2)) # esquina inferior izquierda
			elif x == size.x - 1 and y == size.y - 1:
				wall_map.set_cell(position, 0, Vector2i(2, 2)) # esquina inferior derecha
			elif y == 0:
				wall_map.set_cell(position, 0, Vector2i(1, 0)) # borde superior
			elif y == size.y - 1:
				wall_map.set_cell(position, 0, Vector2i(1, 2)) # borde inferior
			elif x == 0:
				wall_map.set_cell(position, 0, Vector2i(0, 1)) # borde izquierdo
			elif x == size.x - 1:
				wall_map.set_cell(position, 0, Vector2i(2, 1)) # borde derecho

			else:
				var tile_position = select_percent_tile(rand)
				floor_map.set_cell( position, 0 , tile_position) #sino, coloca un piso aleatorio
				#coloca un tile del atlas 0 en la posicion (x,y) del tile map y usa el subtile que esta en la posicion (X,Y) dfentro del atlas

func select_percent_tile(rand :RandomNumberGenerator) -> Vector2i:
	var total_percent = 0.0
	for percent in floor_tile_percent:
		total_percent += percent # sumo todos los valores de la lista de porcentajes 
	var random_value = rand.randf() * total_percent # numero aleatorio resultado de multiplicar un randmon con el porcentaje 
	var current_percent =0.0 #variable que se usa para acomular cada valor de floor_tile_percent
	
	for i in range (floor_tile_percent.size()): #itera sobre cada tile y su porcentaje asociado (por sus indices)
		current_percent += floor_tile_percent[i] # se suman los porcentajes
		if random_value <= current_percent: # verifica si el random de antes, cae dentro del intervalo acomulado
			return floor_tiles[i]
	
	return floor_tiles [0]


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
