extends Area2D

export(PackedScene) var destination_scene

func _on_MapMove_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	get_tree().change_scene_to(destination_scene)

