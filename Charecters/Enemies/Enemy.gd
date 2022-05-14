extends KinematicBody2D

class_name Enemy

export(float) var health = 2
export(bool) var can_be_hit = true


func get_hit(damage: float):
	health -= damage
	can_be_hit = false
