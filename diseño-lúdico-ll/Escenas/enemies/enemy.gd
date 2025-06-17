extends CharacterBody2D

var health = 3
var speed = 65
var player_chase = false
var player = null
var player_inattack_zone = false
var can_take_damage = true
var can_attack = true
@export var drop_item: String = ""

@onready var anim_enemy = $AnimatedSprite2D
@onready var respiracion = $Respiracion
@onready var gemido_hurt = $GemidoHurt
@onready var gemido_muerte = $GemidoMuerte
@onready var grito = $Grito

# Preload de las escenas de ítems para optimizar
var linterna_scene = preload("res://Escenas/items/item_linterna.tscn")
var llave_scene = preload("res://Escenas/items/item_llave.tscn")

func _ready() -> void:
	anim_enemy.play("idle")
	respiracion.stream = preload("res://music/Monstruo1_Respiracion.mp3")
	play_respiracion()  # Inicia la respiración al estar idle

func _physics_process(delta: float) -> void:
	move()
	deal_whit_damage()

func move():
	if anim_enemy.is_playing() and anim_enemy.animation in ["hurt", "death", "attack"]:
		return
	if player_chase:
		position += (player.position - position) / speed
		anim_enemy.play("walk")
		stop_respiracion()  # Detiene la respiración al perseguir
		if (player.position.x - position.x) < 0:
			anim_enemy.flip_h = false
		else:
			anim_enemy.flip_h = true
	else:
		anim_enemy.play("idle")
		play_respiracion()  # Reproduce respiración cuando está idle

func play_respiracion():
	if not respiracion.is_playing():
		respiracion.play()

func stop_respiracion():
	if respiracion.is_playing():
		respiracion.stop()

func take_damage(amount: int):
	health -= amount
	$TakeDamageTimer.start()
	can_take_damage = false
	can_attack = false
	anim_enemy.play("hurt")
	play_gemido_hurt()  # Reproduce gemido al recibir daño
	
	if player != null:
		var knockback_dir = (position - player.position).normalized()
		position += knockback_dir * 25
		print("Aplicando knockback")
	if health <= 0:
		die()

func play_gemido_hurt():
	if not gemido_hurt.is_playing():
		gemido_hurt.stream = preload("res://music/Monstruo1_Gemido.mp3")  # Ajusta la ruta
		gemido_hurt.play()

func die():
	global.enemigos_muertos += 1
	print("Enemigo muerto. Muertos: ", global.enemigos_muertos, ", Total: ", global.enemigos_totales)

	var item_scene: PackedScene = null
	if global.enemigos_muertos == 1:
		item_scene = linterna_scene
	elif global.enemigos_totales > 0 and global.enemigos_muertos == global.enemigos_totales:
		item_scene = llave_scene

	if item_scene:
		var item = item_scene.instantiate()
		item.position = position
		get_parent().add_child(item)
		print("Ítem instanciado: ", item_scene.resource_path, " en posición: ", item.position)

	play_gemido_muerte()  # Reproduce gemido de muerte
	anim_enemy.play("death")
	await anim_enemy.animation_finished
	queue_free()

func play_gemido_muerte():
	if not gemido_muerte.is_playing():
		gemido_muerte.stream = preload("res://music/Monstruo1_Gemido2.mp3")  # Ajusta la ruta
		gemido_muerte.play()

func enemy():
	pass

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body and body.has_method("player"):
		player = body
		player_chase = true
		play_grito()  # Grita cuando el jugador entra en el área

func play_grito():
	if not grito.is_playing():
		grito.stream = preload("res://music/Grito_Monstruo.mp3")  # Ajusta la ruta
		grito.play()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body and body.has_method("player"):
		player = null
		player_chase = false

func _on_hit_box_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = true
		if can_attack and not anim_enemy.is_playing():
			attack()

func _on_hit_box_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = false

func deal_whit_damage():
	if player_inattack_zone and global.player_current_attack == true:
		if can_take_damage:
			take_damage(1)

func _on_take_damage_timer_timeout() -> void:
	can_take_damage = true
	can_attack = true

func attack():
	if can_attack and not anim_enemy.is_playing():
		anim_enemy.play("attack")
