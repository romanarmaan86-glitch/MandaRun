extends Node

# main.gd  (Scripts/main.gd)

func _ready() -> void:
	# Introduce today's new words before the run begins
	QuizManager.prepare_run()

func _on_player_died() -> void:
	get_tree().change_scene_to_file("res://Scenes/run_results.tscn")
