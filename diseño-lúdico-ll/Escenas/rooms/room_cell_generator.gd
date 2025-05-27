extends Node2D

@export var room_type :String = "cell"
@onready var floor_map :TileMapLayer = $TileMap/Floors #referencia a nodo hijo floors
@onready var wall_map : TileMapLayer = $TileMap/Walls #referencia a nodo hijo walls


@export var floor_tiles: Array[Vector2i] = [Vector2i(3, 7), Vector2i(11, 6)] # Lista de tiles de piso 
@export var floor_tile_percent: Array[float] = [0.9, 0.3] # 70% tile1, 30% tile2

func _ready() -> void:

	generate_cell() 


func  generate_cell ():
	var rand = RandomNumberGenerator.new() #generador de numeritos
	rand.randomize() 
	for x in range (10): #recorre columnas del 0_9
		for y in range (10): #recorre filas 0_9
			var position = Vector2i (x,y) #guarda la coordenada (x,y) como vector de enteros (es un vector de 2 componentes lo uso para representar las cordenadas en la grilla
			if x==0 or x==9 or y== 0 or y==9: #si esta en un borde
				wall_map.set_cell( position, 0 , Vector2i(3,2)) #coloca una pared
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
