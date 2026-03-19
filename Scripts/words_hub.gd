extends Control

# words_hub.gd  (Scripts/words_hub.gd)
#
# Scene structure (Scenes/words_hub.tscn):
#   Control (root, this script)
#     Panel
#     Label          (name: TitleLabel, text: "Words")
#     VBoxContainer
#       Button       (name: WordPacksBtn,  text: "Word Packs")
#       Button       (name: MyWordsBtn,    text: "My Words")
#       Button       (name: BackBtn,       text: "Back")

@onready var packs_btn:  Button = $VBoxContainer/WordPacksBtn
@onready var words_btn:  Button = $VBoxContainer/MyWordsBtn
@onready var back_btn:   Button = $BackBtn

func _ready() -> void:
	packs_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/word_packs.tscn")
	)
	words_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/word_list.tscn")
	)
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	)
