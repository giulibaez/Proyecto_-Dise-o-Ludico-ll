#extends CharacterBody2D
#var move_speed = 100
#var is_left = true
#@onready var Animated_sprite = $AnimatedSprite2D
#var current_direction = "none"
#
#var max_health = 3
#var current_health= 3
#var enemy_inattack_range = false
#var enemy_attack_cooldown = true
#var player_alive= true
#@onready var heart_sound = $HeartSound
#@onready var heart_display = $Node/Vida
#@onready var hitbox_area = $HitBoxArea
#@onready var timer = $AttackCooldown
#
#
#
#
#func _ready() -> void:
	#$AnimatedSprite2D.play("front_idle")
#
#
#@warning_ignore("unused_parameter")
#func _physics_process(delta: float) -> void:
	#move()
	#move_and_slide()
	#enemy_attack()
#
#
#func move():
	## Movimiento horizontal
	#if Input.is_action_pressed("move_right"):
		#current_direction = "right"
		#play_animation(1)
		#velocity.x = move_speed
		#velocity.y = 0
	#elif Input.is_action_pressed("move_left"):
		#current_direction = "left"
		#play_animation(1)
		#velocity.x = -move_speed
		#velocity.y = 0
	 ## Movimiento vertical
	#elif Input.is_action_pressed("move_down"):
		#current_direction = "down"
		#play_animation(1)
		#velocity.y = move_speed
		#velocity.x = 0
	#elif Input.is_action_pressed("move_up"):
		#current_direction = "up"
		#play_animation(1)
		#velocity.y = -move_speed
		#velocity.x = 0
	#else:
		#play_animation(0)
		#velocity.x = 0
		#velocity.y = 0
#
#
#func play_animation(movement):
	#var direction = current_direction
	#var animation = $AnimatedSprite2D
	#
	#if direction =="right":
		#animation.flip_h = true
		#if movement == 1:
			#animation.play("side_walk")
		#elif movement == 0:
			#animation.play("side_idle")
		#
	#if direction =="left":
		#animation.flip_h = false
		#if movement == 1:
			#animation.play("side_walk")
		#elif movement == 0:
			#animation.play("side_idle")
		#
	#if direction =="down":
		#if movement == 1:
			#animation.play("front_walk")
		#elif movement == 0:
			#animation.play("front_idle")
		#
	#if direction =="up":
		#if movement == 1:
			#animation.play("back_walk")
		#elif movement == 0:
			#animation.play("back_idle")
#
#func  take_damage(cant: int):
	#current_health -= cant
	#current_health = clamp(current_health, 0 , max_health) #clamp evalua  que la vida actual no sea menor que 0 ni mayor a la vida maxima
	#
	#update_hearts_display()
	#
	##if current_health == 2:
		##heart_sound.stream = preload("res://music/sound_heart_player_slow.mp3")
		##heart_sound.play()
	##
	##elif current_health == 1:
		##heart_sound.stream = preload("res://music/sound_heart_player_fast.mp3")
		##heart_sound.play()
	#
	#if  current_health <= 0:
		#die()
#
#func die():
	#queue_free() #elimina al jugador de la escena 
	##mas adelante implementar animacion de muerte y pantalla de game over 
#
#func update_hearts_display():
	#match current_health:
		#3:
			#heart_display.frame = 0
		#2:
			#heart_display.frame = 1
		#1:
			#heart_display.frame = 2
		#0:
			#heart_display.frame = 3
#
#
#func player():
	#pass
#
#func _on_hit_box_area_body_entered(body: CharacterBody2D) -> void:
	#if body.has_method("enemy"):
		#enemy_inattack_range = true
		#print("acatoy")
#
#
#func _on_hit_box_area_body_exited(body: CharacterBody2D) -> void:
	#if body.is_in_group("enemies"):
		#enemy_inattack_range = false
#
#func enemy_attack():
	#if enemy_inattack_range and enemy_attack_cooldown and player_alive:
		#take_damage(1)  # Aplica daño
		#enemy_attack_cooldown = false
		#timer.start()  # Inicia el temporizador
		#print("Ataque enemigo! Vida actual: ", current_health)
#
#func _on_attack_cooldown_timeout() -> void:
	#enemy_attack_cooldown = true  # Restablece el cooldown cuando el timer termina
	#print("Cooldown terminado, enemigo puede atacar de nuevo")

extends CharacterBody2D

var move_speed = 100
var is_left = true
@onready var animated_sprite = $AnimatedSprite2D
var current_direction = "none"

var max_health = 3
var current_health = 3
var enemy_inattack_range = false
var enemy_attack_cooldown = true
var player_alive = true
@onready var heart_sound_slow = $Node/HeartSoundSlow
@onready var heart_sound_fast = $Node/HeartSoundFast
@onready var heart_display = $Node/Vida
@onready var hitbox_area = $HitBoxArea
@onready var timer = $AttackCooldown

func _ready() -> void:
	animated_sprite.play("front_idle")
	timer.wait_time = 1.0  # Tiempo de espera entre ataques (ajusta si necesitas)
	timer.one_shot = true  # El timer se ejecuta una vez por ataque
	if not timer.is_connected("timeout", _on_attack_cooldown_timeout):
		timer.connect("timeout", _on_attack_cooldown_timeout)  # Conecta la señal en código

func _physics_process(delta: float) -> void:
	if player_alive:
		move()
		move_and_slide()
		enemy_attack()

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
			animation.play("side_idle")
	if direction == "left":
		animation.flip_h = false
		if movement == 1:
			animation.play("side_walk")
		else:
			animation.play("side_idle")
	if direction == "down":
		if movement == 1:
			animation.play("front_walk")
		else:
			animation.play("front_idle")
	if direction == "up":
		if movement == 1:
			animation.play("back_walk")
		else:
			animation.play("back_idle")

func take_damage(cant: int):
	if not player_alive:
		return
	
	current_health -= cant
	current_health = clamp(current_health, 0, max_health)
	update_hearts_display()
	
	if heart_sound_fast == null and heart_sound_slow == null :
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
	player_alive= false
	if player_alive == false:
		animated_sprite.play("death")
		await animated_sprite.animation_finished
		print("memoori")
	queue_free()

func update_hearts_display():
	match current_health:
		3:
			heart_display.frame = 0
		2:
			heart_display.frame = 1
		1:
			heart_display.frame = 2
		0:
			heart_display.frame = 3

func _on_hit_box_area_body_entered(body: Node2D) -> void:
	if body.has_method("enemy") and not enemy_inattack_range:
		enemy_inattack_range = true

func _on_hit_box_area_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = false

func enemy_attack():
	if enemy_inattack_range and enemy_attack_cooldown and player_alive:
		take_damage(1)
		enemy_attack_cooldown = false
		timer.start()
		print(" Vida actual: ", current_health)

func _on_attack_cooldown_timeout() -> void:
	enemy_attack_cooldown = true
	print("Cooldown terminado, enemigo puede atacar de nuevo")
