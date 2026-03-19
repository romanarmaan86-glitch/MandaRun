extends Control

# main_menu.gd  (Scripts/main_menu.gd)

func _ready() -> void:
	UIStyle.make_bg(self)

	# Title
	var title = UIStyle.make_title("Manda-Run", self, 60)
	title.add_theme_font_size_override("font_size", 48)
	title.modulate = UIStyle.ACCENT

	# Stars + streak row
	var top_row = HBoxContainer.new()
	top_row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top_row.position = Vector2(-150, 130)
	top_row.custom_minimum_size = Vector2(300, 36)
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 24)
	add_child(top_row)

	var stars_lbl = UIStyle.make_label("⭐ %d" % SaveManager.total_stars, UIStyle.FS_BODY, UIStyle.ACCENT)
	top_row.add_child(stars_lbl)

	if SaveManager.streak > 0:
		var streak_lbl = UIStyle.make_label("🔥 %d day streak" % SaveManager.streak, UIStyle.FS_BODY)
		top_row.add_child(streak_lbl)

	# Buttons
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-120, -60)
	vbox.custom_minimum_size = Vector2(240, 0)
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	var start_btn = UIStyle.make_button("▶  Start Run", UIStyle.FS_HEADING)
	start_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/pack_select.tscn"))
	vbox.add_child(start_btn)

	var words_btn = UIStyle.make_button("📖  Words", UIStyle.FS_BODY)
	words_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/words_hub.tscn"))
	vbox.add_child(words_btn)

	var settings_btn = UIStyle.make_button("⚙  Settings", UIStyle.FS_BODY)
	settings_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/settings.tscn"))
	vbox.add_child(settings_btn)
