extends Node

const GameOverScreen = preload("res://UI/GameOverScreen.tscn")

var active_player setget set_active_player

func set_active_player(player):
	if(active_player != player):
		if(is_instance_valid(active_player)):
			active_player.disconnect("player_died", self, "on_player_died")
		
		active_player = player
		active_player.connect("player_died", self, "on_player_died")
		
func on_player_died(player):
	var game_over = GameOverScreen.instance()
	add_child(game_over)
	get_tree().paused = true
