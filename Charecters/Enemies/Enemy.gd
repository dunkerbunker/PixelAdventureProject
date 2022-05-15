extends "res://Charecters/Charecter.gd"

class_name Enemy

export(bool) var can_be_hit = true
export(float) var collision_damage = 1

func _get_hit(damage: float):
	push_error("get hit function has not been implemented")

func _on_EnemyCollisionHitbox_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	body.get_hit(collision_damage)
