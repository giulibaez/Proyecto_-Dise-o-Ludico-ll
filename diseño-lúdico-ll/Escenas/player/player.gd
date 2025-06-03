extends CharacterBody2D
var move_speed = 100
var is_left = true
@onready var Animated_sprite = $AnimatedSprite2D
var current_direction = "none"

var max_health = 3
var current_health= 3

@onready var heart_sound = $HeartSound
@onready var heart_display = $Node/Vida
@onready var hitbox_area = $HitBoxArea


func _ready() -> void:
	$AnimatedSprite2D.play("front_idle")


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	move()
	move_and_slide()


func move():
	# Movimiento horizontal
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
	 # Movimiento vertical
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
	var animation = $AnimatedSprite2D
	
	if direction =="right":
		animation.flip_h = true
		if movement == 1:
			animation.play("side_walk")
		elif movement == 0:
			animation.play("side_idle")
		
	if direction =="left":
		animation.flip_h = false
		if movement == 1:
			animation.play("side_walk")
		elif movement == 0:
			animation.play("side_idle")
		
	if direction =="down":
		if movement == 1:
			animation.play("front_walk")
		elif movement == 0:
			animation.play("front_idle")
		
	if direction =="up":
		if movement == 1:
			animation.play("back_walk")
		elif movement == 0:
			animation.play("back_idle")

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		perform_attack()
		

func perform_attack():
	hitbox_area.monitoring = true
	await get_tree().create_timer(0.2).timeout#el golpe dura 2 seg
	hitbox_area.monitoring = false
	


func _on_hit_box_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(1)
