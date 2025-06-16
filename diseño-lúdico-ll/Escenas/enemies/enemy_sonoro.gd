extends CharacterBody2D
enum State {PATROLLING, CHASING, AGGRESSIVE} # tiene 3 estados definidos 

@export var patrol_speed: float = 40.0
@export var chase_speed: float = 90.0
@export var detection_radius: float = 100.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0

var current_state: State = State.PATROLLING
var sound_position: Vector2 = Vector2.ZERO # lugar donde se detecto un sonido
var current_target: Node2D = null # a quien a atacar
var return_timer: float = 0.0 # cuenta para volver a patrullar
var attack_timer: float = 0.0 # tiempo de ataque
var patrol_direction: Vector2 = Vector2.ZERO
var last_movement: Vector2 = Vector2.ZERO

@onready var detection_shape_node = $DetectionArea/CollisionShape2D
@onready var attack_shape_node = $AttackArea/CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

# ready sobreescribe las formas de colision y las asigna
#conecta las señales
#llama a start patrol, para e,pezar a patrullar
func _ready():
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = detection_radius
	detection_shape_node.shape = detection_shape  

	var attack_shape = CircleShape2D.new()
	attack_shape.radius = attack_range
	attack_shape_node.shape = attack_shape 

	detection_area.connect("area_entered", _on_sound_detected)
	attack_area.connect("body_entered", _on_body_entered_attack_zone)

	start_patrol()

#dependiendo del estado actual, actualiza el estado y se mueve 
func _physics_process(delta):
	match current_state:
		State.PATROLLING:
			update_patrol(delta)
		State.CHASING:
			chase_sound(delta)
		State.AGGRESSIVE:
			handle_aggression(delta)
	
	move_and_slide()



func start_patrol():
	current_state = State.PATROLLING
	# Generar dirección aleatoria inicial
	patrol_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	$AnimatedSprite2D.play("walk_slow")

#genera movimiento aleatoreo y si choca con algo cambia de dirección
func update_patrol(delta):
	# Cambiar dirección aleatoriamente
	if randf() < 0.01:
		patrol_direction = patrol_direction.rotated(randf_range(-PI/4, PI/4))
	
	velocity = patrol_direction * patrol_speed
	
	# Si choca con algo, cambiar dirección drasticamente
	if get_slide_collision_count() > 0:
		patrol_direction = patrol_direction.rotated(randf_range(PI/4, PI/2))


func _on_sound_detected(area):
	if current_state != State.AGGRESSIVE and area.is_in_group("sound_emitters"):
		sound_position = area.global_position
		current_state = State.CHASING
		$AnimatedSprite2D.play("walk_fast")

func chase_sound(delta):
	var direction = global_position.direction_to(sound_position)
	velocity = direction * chase_speed
	last_movement = direction
	
	# Rotar sprite según dirección
	if abs(direction.x) > 0.1:
		$AnimatedSprite2D.flip_h = direction.x < 0
	
	# Verificar si llegó al sonido
	if global_position.distance_to(sound_position) < 10.0:
		current_state = State.AGGRESSIVE
		return_timer = 2.0  # Temporizador para volver a patrullar
		$AnimatedSprite2D.play("alert")
		find_immediate_target()

func find_immediate_target():
	var potential_targets = attack_area.get_overlapping_bodies()
	for body in potential_targets:
		if body != self and (body.is_in_group("player") or body.is_in_group("npc") or body.is_in_group("enemies")):
			current_target = body
			break

func handle_aggression(delta):
	return_timer -= delta
	
	# Atacar si hay objetivo
	if current_target and is_instance_valid(current_target):
		var target_dir = global_position.direction_to(current_target.global_position)
		last_movement = target_dir
		
		# Rotar hacia el objetivo
		if abs(target_dir.x) > 0.1:
			$AnimatedSprite2D.flip_h = target_dir.x < 0
		
		# Manejar ataque
		attack_timer -= delta
		if attack_timer <= 0:
			if global_position.distance_to(current_target.global_position) <= attack_range:
				perform_attack()
				attack_timer = attack_cooldown
	elif return_timer <= 0:
		# Volver a patrullar si no hay objetivos
		start_patrol()

func perform_attack():
	$AnimatedSprite2D.play("attack")
	# Aquí iría la lógica de daño al objetivo
	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(10)
	
	# Buscar nuevo objetivo después de atacar
	current_target = null
	find_immediate_target()

func _on_body_entered_attack_zone(body):
	if current_state == State.AGGRESSIVE and body != self:
		if not current_target or !is_instance_valid(current_target):
			if body.is_in_group("player") or body.is_in_group("npc") or body.is_in_group("enemies"):
				current_target = body


#Para emitir sonidos que el enemigo detecte:

# En el objeto que hace sonido:
func emit_sound():
	var sound_area = Area2D.new()
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 10
	sound_area.add_child(collision)
	sound_area.add_to_group("sound_emitters")
	
	# Configurar para que desaparezca después de un tiempo
	sound_area.position = global_position
	get_parent().add_child(sound_area)
	sound_area.create_timer(0.5).timeout.connect(sound_area.queue_free)
