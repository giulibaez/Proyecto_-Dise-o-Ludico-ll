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

@onready var animated_sprite = $AnimatedSprite2D
@onready var heart_sound_slow = $Node/HeartSoundSlow
@onready var heart_sound_fast = $Node/HeartSoundFast
@onready var heart_display = $Node/Vida
@onready var hitbox_area = $HitBoxArea
@onready var timer = $AttackCooldown
@onready var linterna_light = $LinternaLight  # Referencia al nodo PointLight2D
@onready var vision_linterna: Area2D = $VisionLinterna
var current_room: Vector2i = Vector2i.ZERO
var enemies_in_vision: Array = []  # Lista para rastrear enemigos dentro del área

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

func _physics_process(delta: float) -> void:
	if player_alive:
		move()
		move_and_slide()
		enemy_attack()
		attack()
		usar_linterna()
		update_vision_area()

func _process(delta):
	var gen = get_parent()
	var rs = gen.room_size
	var gsx = gen.grid_size_x
	var gsy = gen.grid_size_y

	var room_x = floor(position.x / rs.x) - gsx
	var room_y = floor(position.y / rs.y) - gsy
	var player_room = Vector2i(room_x, room_y)

	if player_room != current_room:
		current_room = player_room
		gen.move_camera_to_room(current_room)

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
		heart_sound_slow.stop()
	if current_health == 0:
		die()

func die():
	player_alive = false
	if player_alive == false:
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	queue_free()

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

func obtener_llave():
	tiene_llave = true
	print("Llave obtenida")

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
