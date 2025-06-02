extends CharacterBody2D

var health = 2

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	# agregar soltar item, efectos, animaciones, etc.
	queue_free()
