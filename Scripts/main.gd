extends Node

# ─────────────────────────────────────────────────────────────
# main.gd
# Connect the player's "died" signal to _on_player_died in the
# Godot editor (Node tab on the Player node → died → main.gd).
# ─────────────────────────────────────────────────────────────

func _on_player_died() -> void:
	# Go to results screen instead of main menu directly.
	# The results screen will go to main menu when the player taps Continue.
	get_tree().change_scene_to_file("res://Scenes/run_results.tscn")
