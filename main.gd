extends Node

func _on_player_died():
	get_tree().change_scene_to_file("res://main_menu.tscn")
