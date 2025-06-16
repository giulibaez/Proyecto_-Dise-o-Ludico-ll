extends CharacterBody2D

var health = 2
var speed = 65
var player_chase= false
var player = null

@onready var anim_enemy = $AnimatedSprite2D



func _physics_process(delta: float) -> void:
	move()

func move():
	if player_chase:
		position += (player.position - position)/speed 
		anim_enemy.play("walk")
		if (player.position.x - position.x) <0:
			anim_enemy.flip_h = false
		else:
			anim_enemy.flip_h = true
	else:
		anim_enemy.play("idle")


func take_damage(amount: int):
	health -= amount
	anim_enemy.play("hurt")
	if health <= 0:
		die()

func die():
	anim_enemy.play("death")
	queue_free()

func enemy():
	pass

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true
	attack_player()


func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase = false 

func attack_player():
	if player_chase:
		anim_enemy.play("attack")
