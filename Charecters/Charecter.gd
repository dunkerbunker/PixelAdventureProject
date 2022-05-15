extends KinematicBody2D


export(float) var health = 2 setget set_health

func _get_hit(damage: float):
	push_error("get hit function has not been implemented")

func _on_hit_finished():
	push_error("on hit function has not been implemented")

func set_health(value):
	health = value
	
	if (health <= 0):
		queue_free()
