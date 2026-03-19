extends Control

# words_hub.gd  (Scripts/words_hub.gd)

func _ready() -> void:
	UIStyle.make_bg(self)
	UIStyle.make_title("Words", self)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-120, -60)
	vbox.custom_minimum_size = Vector2(240, 0)
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	var packs_btn = UIStyle.make_button("🛍  Word Packs", UIStyle.FS_BODY)
	packs_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/word_packs.tscn"))
	vbox.add_child(packs_btn)

	var mywords_btn = UIStyle.make_button("📋  My Words", UIStyle.FS_BODY)
	mywords_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/word_list.tscn"))
	vbox.add_child(mywords_btn)

	UIStyle.make_back_button(self, "res://Scenes/main_menu.tscn")
