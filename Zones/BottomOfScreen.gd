extends Area2D



func _on_BottomOfScreen_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	body.die()
