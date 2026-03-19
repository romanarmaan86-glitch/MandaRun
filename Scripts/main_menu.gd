extends Control

# main_menu.gd  (Scripts/main_menu.gd)

func _ready() -> void:
	_update_stars()
	_update_streak()

func _update_stars() -> void:
	var lbl = find_child("StarsLabel", true, false) as Label
	if lbl:
		lbl.text = "⭐ %d" % SaveManager.total_stars

func _update_streak() -> void:
	var lbl = find_child("StreakLabel", true, false) as Label
	if lbl:
		lbl.text = "🔥 %d day streak" % SaveManager.streak if SaveManager.streak > 0 else ""

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/pack_select.tscn")

func _on_words_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/words_hub.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")
