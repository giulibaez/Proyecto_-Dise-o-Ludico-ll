extends Area2D

signal tutorial_triggered
@onready var anim = $AnimationPlayer

func _ready():
	connect("body_entered", _on_body_entered)
	anim.play("brillat")

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("tutorial_triggered")
		queue_free() # Elimina el papel tras activar el tutorial
