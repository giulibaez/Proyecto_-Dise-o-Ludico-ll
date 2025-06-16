extends CharacterBody2D

var health = 3
var speed = 65
var player_chase= false
var player = null
var player_inattack_zone= false
var can_take_damage = true
var can_attack = true

@onready var anim_enemy = $AnimatedSprite2D



func _physics_process(delta: float) -> void:
	move()
	deal_whit_damage()

func move():
	if anim_enemy.is_playing() and anim_enemy.animation in ["hurt", "death","attack"]:
		return
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
	print("daño")
	$TakeDamageTimer.start()
	can_take_damage= false
	can_attack = false
	anim_enemy.play("hurt")
	if player != null:
		var knockback_dir = (position - player.position).normalized()
		position += knockback_dir * 40
		print("aplicando knocknaback")
	if health == 0:
		die()

func die():
	anim_enemy.play("death")
	print("animacion de muerte")
	await anim_enemy.animation_finished
	queue_free()

func enemy():
	pass

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true


func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase = false 


func _on_hit_box_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = true
		if can_attack:
			anim_enemy.play("attack")


func _on_hit_box_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = false
		
func deal_whit_damage():
	if player_inattack_zone and global.player_current_attack == true:
		if can_take_damage == true:
			take_damage(1)


func _on_take_damage_timer_timeout() -> void:
	can_take_damage = true
	can_attack = true

func attack():
	anim_enemy.play("attack")
