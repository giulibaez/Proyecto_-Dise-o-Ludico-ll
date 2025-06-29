extends CharacterBody2D

var move_speed = 100
var is_left = true
var current_direction = "none"
var max_health = 3
var current_health = 3
var enemy_inattack_range = false
var enemy_attack_cooldown = true
var player_alive = true
var attack_inprogress = false 
var tiene_linterna = false
var tiene_llave = false
var linterna_encendida = false  
var blood_splatter = null 
var current_room: Vector2i = Vector2i.ZERO
var enemies_in_vision: Array = []  # Lista para rastrear enemigos dentro del área

var in_room_ext = false  # Nueva variable para rastrear si está en room_ext
@onready var victory_timer = Timer.new()  # Temporizador para la pantalla de victoria
var door_opened = false  # Nueva variable para rastrear si la puerta a room_ext está abierta

@onready var animated_sprite = $AnimatedSprite2D
@onready var heart_sound_slow = $Node/HeartSoundSlow
@onready var heart_sound_fast = $Node/HeartSoundFast
@onready var heart_display = $Node/Vida
@onready var hitbox_area = $HitBoxArea
@onready var timer = $AttackCooldown
@onready var linterna_light = $LinternaLight  # Referencia al nodo PointLight2D
@onready var vision_linterna: Area2D = $VisionLinterna

func _ready() -> void:
	animated_sprite.play("front_idle")
	timer.one_shot = true
	if not timer.is_connected("timeout", _on_attack_cooldown_timeout):
		timer.connect("timeout", _on_attack_cooldown_timeout)
	linterna_light.enabled = false  # Asegura que la linterna esté apagada al inicio
	add_to_group("player")  # Para que Linterna.gd lo detecte
	var map_generator = get_parent()
	if map_generator:
		blood_splatter = map_generator.get_node("CanvasLayer/BloodSplatter")  # Ruta relativa desde MapGenerator
	if blood_splatter:
		blood_splatter.modulate.a = 0.0  # Oculta las manchas al inicio
	else:
		print("Error: BloodSplatter no encontrado")
	add_to_group("player")
	victory_timer.wait_time = 1.0  # Esperar 3 segundos
	victory_timer.one_shot = true
	victory_timer.connect("timeout", _on_victory_timer_timeout)
	add_child(victory_timer)

func _physics_process(delta: float) -> void:
	if player_alive:
		move()
		move_and_slide()
		enemy_attack()
		attack()
		usar_linterna()
		update_vision_area()
		clamp_position_to_current_room(get_parent())

func _process(delta):
	var gen = get_parent()
	var rs = gen.room_size
	var gsx = gen.grid_size_x
	var gsy = gen.grid_size_y

	var room_x = floor(position.x / rs.x) - gsx
	var room_y = floor(position.y / rs.y) - gsy
	var player_room = Vector2i(room_x, room_y)

	if player_room != current_room:
		var direction = _get_transition_direction(player_room)
		if _can_enter_room(player_room, direction):
			current_room = player_room
			gen.move_camera_to_room(current_room)
			var nx = player_room.x + gsx
			var ny = player_room.y + gsy
			if nx >= 0 and nx < gen.grid_size_x * 2 and ny >= 0 and ny < gen.grid_size_y * 2:
				var room_data = gen.rooms[nx][ny]
				if room_data and room_data["type"] == "ext":
					in_room_ext = true
					print("Entraste en room_ext")
		else:
			position = clamp_position_to_current_room(gen)
			print("Movimiento bloqueado a room_ext: necesitas la llave")

	if in_room_ext and victory_timer.is_stopped():
		var room_center = Vector2((current_room.x + gsx) * rs.x + rs.x / 2, (current_room.y + gsy) * rs.y + rs.y / 2)
		var distance_to_center = position.distance_to(room_center)
		print("Distancia al centro de room_ext: ", distance_to_center)
		if distance_to_center < 100:
			victory_timer.start()
			print("Jugador en el centro de room_ext, iniciando temporizador de victoria")

# Verificar si el jugador está en el centro de room_ext
	if in_room_ext and not victory_timer.is_stopped():
		var room_center = Vector2((current_room.x + gsx) * rs.x + rs.x / 2, (current_room.y + gsy) * rs.y + rs.y / 2)
		var distance_to_center = position.distance_to(room_center)
		if distance_to_center < 50:  # Margen de 50 píxeles
			victory_timer.start()
			print("Jugador en el centro de room_ext, iniciando temporizador de victoria")



func _on_victory_timer_timeout():
	print("Tiempo de espera finalizado, mostrando pantalla de victoria")
	get_tree().change_scene_to_file("res://Escenas/menu/victoria.tscn")

func move():
	if Input.is_action_pressed("move_right"):
		current_direction = "right"
		play_animation(1)
		velocity.x = move_speed
		velocity.y = 0
	elif Input.is_action_pressed("move_left"):
		current_direction = "left"
		play_animation(1)
		velocity.x = -move_speed
		velocity.y = 0
	elif Input.is_action_pressed("move_down"):
		current_direction = "down"
		play_animation(1)
		velocity.y = move_speed
		velocity.x = 0
	elif Input.is_action_pressed("move_up"):
		current_direction = "up"
		play_animation(1)
		velocity.y = -move_speed
		velocity.x = 0
	else:
		play_animation(0)
		velocity.x = 0
		velocity.y = 0

func play_animation(movement):
	var direction = current_direction
	var animation = animated_sprite
	
	if direction == "right":
		animation.flip_h = true
		if movement == 1:
			animation.play("side_walk")
		else:
			if attack_inprogress == false:
				animation.play("side_idle")
	if direction == "left":
		animation.flip_h = false
		if movement == 1:
			animation.play("side_walk")
		else:
			if attack_inprogress == false:
				animation.play("side_idle")
	if direction == "down":
		if movement == 1:
			animation.play("front_walk")
		else:
			if attack_inprogress == false:
				animation.play("front_idle")
	if direction == "up":
		if movement == 1:
			animation.play("back_walk")
		else:
			if attack_inprogress == false:
				animation.play("back_idle")

func take_damage(cant: int):
	if not player_alive:
		return
	
	current_health -= cant
	current_health = clamp(current_health, 0, max_health)
	update_hearts_display()
	
	if heart_sound_fast == null and heart_sound_slow == null:
		print("Error")
		return
	if current_health == 2:
		heart_sound_slow.stream = preload("res://music/sound_heart_player_slow.mp3")
		heart_sound_slow.play()
	elif current_health == 1:
		heart_sound_fast.stream = preload("res://music/sound_heart_player_fast.mp3")
		heart_sound_fast.play()
	if current_health == 0:
		die()

func die():
	player_alive = false
	if player_alive == false:
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	queue_free()
	get_tree().change_scene_to_file("res://Escenas/menu/game_over.tscn")

func update_hearts_display():
	match current_health:
		3:
			heart_display.frame = 0
			if blood_splatter:
				blood_splatter.modulate.a = 0.0  # Sin manchas
		2:
			heart_display.frame = 1
			if blood_splatter:
				blood_splatter.modulate.a = 0.3  # Manchas leves
		1:
			heart_display.frame = 2
			if blood_splatter:
				blood_splatter.modulate.a = 0.6  # Manchas más visibles
		0:
			heart_display.frame = 3
			if blood_splatter:
				blood_splatter.modulate.a = 0.8  # Manchas muy visibles


func _on_hit_box_area_body_entered(body: Node2D) -> void:
	if body.has_method("enemy") and not enemy_inattack_range:
		enemy_inattack_range = true
		print("enemigo detectado n hitbox")
		if enemy_attack_cooldown:
			$EnemyDamageDelayTimer.start()
			print("inicia delay")

func _on_hit_box_area_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = false

func enemy_attack():
	pass

func _on_attack_cooldown_timeout() -> void:
	enemy_attack_cooldown = true

func attack():
	var dir = current_direction
	
	if Input.is_action_just_pressed("attack"):
		global.player_current_attack = true
		attack_inprogress = true
		if dir == "right":
			animated_sprite.flip_h = true
			animated_sprite.play("side_attack")
			$DealAttackTimer.start()
		if dir == "left":
			animated_sprite.flip_h = false
			animated_sprite.play("side_attack")
			$DealAttackTimer.start()
		if dir == "down":
			animated_sprite.play("front_attack")
			$DealAttackTimer.start()
		if dir == "up":
			animated_sprite.play("back_attack")
			$DealAttackTimer.start()

func _on_deal_attack_timer_timeout() -> void:
	$DealAttackTimer.stop()
	global.player_current_attack = false
	attack_inprogress = false 

func player():
	pass

func _on_enemy_damage_delay_timer_timeout() -> void:
	if enemy_inattack_range and enemy_attack_cooldown and player_alive:
		take_damage(1)
		enemy_attack_cooldown = false
		timer.start()
		print("daño aplicado al jugador")
	else:
		print("no se aplica daño al jugador")

func obtener_linterna():
	tiene_linterna = true
	print("Linterna obtenida")

func usar_linterna():
	if Input.is_action_just_pressed("use_linterna") and tiene_linterna:
		linterna_encendida = !linterna_encendida
		linterna_light.enabled = linterna_encendida
		print("Linterna ", "encendida" if linterna_encendida else "apagada")
		
		# Actualizar visibilidad de enemigos en el área de visión
		for enemy in enemies_in_vision:
			if enemy.is_in_group("enemy") and enemy.is_in_dark_room:
				enemy.visible = linterna_encendida
				print("Enemigo en posición ", enemy.position, " ahora ", "visible" if linterna_encendida else "oculto")

func update_vision_area():
	# Opcional: Ajustar la posición o forma del área según la dirección del jugador
	var collision_shape = vision_linterna.get_node("CollisionShape2D")
	match current_direction:
		"right":
			collision_shape.position = Vector2(50, 0)
		"left":
			collision_shape.position = Vector2(-50, 0)
		"down":
			collision_shape.position = Vector2(0, 50)
		"up":
			collision_shape.position = Vector2(0, -50)
		_:
			collision_shape.position = Vector2(0, 0)

func _on_vision_linterna_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_vision.append(body)
		print("Enemigo entró en VisionLinterna: ", body.position)
		if body.is_in_dark_room:
			body.visible = linterna_encendida  # Mostrar solo si la linterna está encendida
		else:
			body.visible = true  # Siempre visible en habitaciones no oscurecidas
		print("Enemigo en posición ", body.position, " ahora ", "visible" if body.visible else "oculto")


func _on_vision_linterna_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_vision.erase(body)
		if body.is_in_dark_room:
			body.visible = false  # Ocultar si está en una habitación oscurecida
		else:
			body.visible = true  # Mantener visible en habitaciones no oscurecidas
		print("Enemigo salió de VisionLinterna: ", body.position, ", ahora ", "visible" if body.visible else "oculto")


# Nueva función para aplicar cura
func apply_heal(amount: int):
	if current_health < max_health:
		current_health = min(current_health + amount, max_health)
		update_hearts_display()
		print("Jugador curado a ", current_health, " de vida")


func _get_transition_direction(new_room: Vector2i) -> String:
	var delta = new_room - current_room
	if delta == Vector2i(0, -1):
		return "up"
	elif delta == Vector2i(0, 1):
		return "down"
	elif delta == Vector2i(-1, 0):
		return "left"
	elif delta == Vector2i(1, 0):
		return "right"
	return ""

func _can_enter_room(new_room: Vector2i, direction: String) -> bool:
	if direction == "":
		return true
	var gen = get_parent()
	var nx = new_room.x + gen.grid_size_x
	var ny = new_room.y + gen.grid_size_y
	if nx >= 0 and nx < gen.grid_size_x * 2 and ny >= 0 and ny < gen.grid_size_y * 2:
		var neighbor_data = gen.rooms[nx][ny]
		if neighbor_data and neighbor_data["type"] == "ext" and not door_opened:
			print("Bloqueo en _can_enter_room, door_opened: ", door_opened)
			return false
	return true

func clamp_position_to_current_room(gen) -> Vector2:
	var rs = gen.room_size
	var gsx = gen.grid_size_x
	var gsy = gen.grid_size_y
	var tile_size = 64
	var door_margin = tile_size * 3.0  # Margen para interacción con el candado

	var min_x = (current_room.x + gsx) * rs.x
	var max_x = (current_room.x + gsx) * rs.x + rs.x
	var min_y = (current_room.y + gsy) * rs.y
	var max_y = (current_room.y + gsy) * rs.y + rs.y

	var new_pos = position
	var door_blocked = false
	var near_candado = false
	var candado_near = null
	var candado_direction = ""

	# Definir directions una sola vez
	var directions = {
		"up": Vector2i(0, -1),
		"down": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0)
	}

	# Verificar si el jugador está cerca de un candado
	for candado in gen.candados.keys():
		if is_instance_valid(candado):
			var candado_pos = gen.candados[candado]["position"]
			var distance = position.distance_to(candado_pos)
			if distance < door_margin:
				near_candado = true
				candado_near = candado
				candado_direction = gen.candados[candado]["direction"]
				print("Cerca de candado en puerta ", candado_direction, ", posición: ", position, ", candado: ", candado_pos, ", distancia: ", distance)
				if Input.is_action_just_pressed("interact"):
					print("Tecla E presionada, tiene_llave: ", tiene_llave)
					if tiene_llave:
						door_opened = true
						candado.get_node("AnimatedSprite2D").frame = 1  # Cambia al frame "abierto"
						candado.queue_free()  # Elimina el candado
						gen.candados.erase(candado)  # Elimina del diccionario
						print("Candado abierto y eliminado en puerta ", candado_direction)
					else:
						print("Necesitas la llave para abrir el candado con E")
				else:
					print("Presiona E para interactuar con el candado")

	# Bloquear movimiento hacia room_ext si no se ha abierto la puerta
	for dir_name in directions:
		var neighbor_pos = current_room + directions[dir_name]
		var nx = neighbor_pos.x + gsx
		var ny = neighbor_pos.y + gsy
		if nx >= 0 and nx < gen.grid_size_x * 2 and ny >= 0 and ny < gen.grid_size_y * 2:
			var neighbor_data = gen.rooms[nx][ny]
			if neighbor_data and neighbor_data["type"] == "ext" and not door_opened:
				match dir_name:
					"up":
						if position.y < min_y + tile_size:
							new_pos.y = min_y + tile_size
							door_blocked = true
							print("Bloqueado en puerta superior, door_opened: ", door_opened)
					"down":
						if position.y > max_y - tile_size:
							new_pos.y = max_y - tile_size
							door_blocked = true
							print("Bloqueado en puerta inferior, door_opened: ", door_opened)
					"left":
						if position.x < min_x + tile_size:
							new_pos.x = min_x + tile_size
							door_blocked = true
							print("Bloqueado en puerta izquierda, door_opened: ", door_opened)
					"right":
						if position.x > max_x - tile_size:
							new_pos.x = max_x - tile_size
							door_blocked = true
							print("Bloqueado en puerta derecha, door_opened: ", door_opened)

	if door_blocked and not near_candado:
		print("Movimiento bloqueado a room_ext: necesitas abrir el candado")

	return Vector2(clamp(new_pos.x, min_x, max_x), clamp(new_pos.y, min_y, max_y))
func obtener_llave():
	tiene_llave = true
	print("Llave obtenida")
