extends CharacterBody2D
var move_speed = 200
var is_left = true
@onready var Animated_sprite = $AnimatedSprite2D
var last_direction = "down"

var max_health = 3
var current_health= 3

@onready var heart_sound = $HeartSound
@onready var heart_display = $Node/Vida

func _physics_process(delta: float) -> void:
	move()
	flip()
	animations()
	move_and_slide()

func flip ():
	if (is_left and velocity.x > 0) or ( not is_left and velocity.x < 0): 
		scale.x = -1
		is_left = not is_left

func animations():
	if velocity.length() == 0:
		Animated_sprite.play("idle_" + last_direction)
		return 
	if abs(velocity.x) > abs(velocity.y):
		Animated_sprite.play("walk_right_left")
		last_direction = "side"
	elif velocity.y > 0:
		Animated_sprite.play("walk_down")
		last_direction = "down"
	else:
		Animated_sprite.play("walk_up")
		last_direction = "up"

	

func move():
	var vel_x := 0.0
	var  vel_y := 0.0
	# Movimiento horizontal
	if Input.is_action_pressed("move_right"):
		vel_x += 1
	elif Input.is_action_pressed("move_left"):
		vel_x -= 1
	 # Movimiento vertical
	if Input.is_action_pressed("move_down"):
		vel_y += 1
	elif Input.is_action_pressed("move_up"):
		vel_y -= 1
	
	if vel_x != 0 and vel_y != 0:
		vel_x *= 0.7071
		vel_y *= 0.7071
		
	velocity.x = vel_x * move_speed
	velocity.y = vel_y * move_speed

func  take_damage(cant: int):
	current_health -= cant
	current_health = clamp(current_health, 0 , max_health) #clamp evalua  que la vida actual no sea menor que 0 ni mayor a la vida maxima
	
	update_hearts_display()
	
	if current_health == 2:
		heart_sound.stream = preload("res://music/sound_heart_player_slow.mp3")
		heart_sound.play()
	
	elif current_health == 1:
		heart_sound.stream = preload("res://music/sound_heart_player_fast.mp3")
		heart_sound.play()
	
	elif  current_health <= 0:
		die()

func die():
	queue_free() #elimina al jugador de la escena 
	#mas adelante implementar animacion de muerte y pantalla de game over 

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
