extends Control

# main_menu.gd  (Scripts/main_menu.gd)
#
# Add a Label named "StreakLabel" to main_menu.tscn wherever you
# want the streak to appear. The script updates it on _ready.

@onready var streak_label: Label = $StreakLabel

func _ready() -> void:
	_update_streak()

func _update_streak() -> void:
	var s = SaveManager.streak
	if s <= 0:
		streak_label.text = ""
	else:
		streak_label.text = "🔥 %d day streak" % s

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")
