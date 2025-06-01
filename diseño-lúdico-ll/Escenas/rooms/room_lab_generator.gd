extends Node2D

@export var room_type :String = "lab"
@onready var floor_map :TileMapLayer = $TileMap/Floors #referencia a nodo hijo floors
@onready var wall_map : TileMapLayer = $TileMap/Walls #referencia a nodo hijo walls

func _ready() -> void:
	randomize()#en ready para que los num aleatorios cambien cada que inicie el juego
	generate_lab() 


func  generate_lab ():
	for x in range (10): #recorre columnas del 0_9
		for y in range (10): #recorre filas 0_9
			var position = Vector2i (x,y) #guarda la coordenada (x,y) como vector de enteros (es un vector de 2 componentes lo uso para representar las cordenadas en la grilla
			if x==0 or x==9 or y== 0 or y==9: #si esta en un borde
				wall_map.set_cell( position, 0 , Vector2(11,3)) #coloca una pared
			else:
				var tile_position = Vector2i(7,6) if randi( ) %2 == 0  else Vector2i (14,5) 
				floor_map.set_cell(position, 0 , tile_position) #sino, coloca un piso 
				#coloca un tile del atlas 0 en la posicion (x,y) del tile map y usa el subtile que esta en la posicion (X,Y) dfentro del atlas
