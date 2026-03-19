extends Control

# ─────────────────────────────────────────────────────────────
# word_list.gd  (Scripts/word_list.gd)
#
# Scene structure expected (Scenes/word_list.tscn):
#   Control (root, this script)
#     Panel
#     Label          (name: TitleLabel)
#     ScrollContainer
#       VBoxContainer  (name: WordList)
#     Button         (name: BackButton, text: "Back")
# ─────────────────────────────────────────────────────────────

@onready var word_list:   VBoxContainer = $ScrollContainer/WordList
@onready var back_button: Button        = $BackButton

func _ready() -> void:
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	)
	_populate()

func _populate() -> void:
	# Load the word list from JSON
	if not FileAccess.file_exists("res://hsk1_words.json"):
		printerr("word_list: hsk1_words.json not found")
		return

	var file   = FileAccess.open("res://hsk1_words.json", FileAccess.READ)
	var words  = JSON.parse_string(file.get_as_text()) as Array

	# Sort: learned words first (by level desc), then unlearned
	var learned:   Array = []
	var unlearned: Array = []

	for word in words:
		var rank = word["rank"]
		if SaveManager.has_seen(rank):
			learned.append(word)
		else:
			unlearned.append(word)

	# Sort learned by level descending
	learned.sort_custom(func(a, b):
		return SaveManager.get_level(a["rank"]) > SaveManager.get_level(b["rank"])
	)

	# Build rows
	for word in learned:
		word_list.add_child(_make_learned_row(word))

	for word in unlearned:
		word_list.add_child(_make_unlearned_row(word))

# ─────────────────────────────────────────────────────────────

func _make_learned_row(word: Dictionary) -> HBoxContainer:
	var rank  = word["rank"]
	var level = SaveManager.get_level(rank)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# Chinese character
	var chinese = Label.new()
	chinese.text                = word["chinese"]
	chinese.custom_minimum_size = Vector2(50, 0)
	chinese.add_theme_font_size_override("font_size", 22)
	row.add_child(chinese)

	# Pinyin
	var pinyin = Label.new()
	pinyin.text                = word["pinyin"]
	pinyin.custom_minimum_size = Vector2(100, 0)
	pinyin.add_theme_font_size_override("font_size", 14)
	pinyin.modulate = Color(0.8, 0.8, 0.8)
	row.add_child(pinyin)

	# Meaning
	var meaning = Label.new()
	meaning.text                  = word["meaning"]
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meaning.autowrap_mode         = TextServer.AUTOWRAP_WORD
	meaning.add_theme_font_size_override("font_size", 14)
	row.add_child(meaning)

	# Level stars
	var stars = Label.new()
	stars.text                = _stars_string(level)
	stars.custom_minimum_size = Vector2(80, 0)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(stars)

	# Reset button
	var reset_btn = Button.new()
	reset_btn.text             = "↺"
	reset_btn.custom_minimum_size = Vector2(36, 0)
	reset_btn.tooltip_text     = "Reset progress for this word"
	reset_btn.pressed.connect(_on_reset_word.bind(rank))
	row.add_child(reset_btn)

	return row

func _make_unlearned_row(word: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.modulate = Color(0.35, 0.35, 0.35)   # dark = not yet learned

	var chinese = Label.new()
	chinese.text                = word["chinese"]
	chinese.custom_minimum_size = Vector2(50, 0)
	chinese.add_theme_font_size_override("font_size", 22)
	row.add_child(chinese)

	var pinyin = Label.new()
	pinyin.text                = word["pinyin"]
	pinyin.custom_minimum_size = Vector2(100, 0)
	pinyin.add_theme_font_size_override("font_size", 14)
	row.add_child(pinyin)

	var meaning = Label.new()
	meaning.text                  = word["meaning"]
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meaning.autowrap_mode         = TextServer.AUTOWRAP_WORD
	meaning.add_theme_font_size_override("font_size", 14)
	row.add_child(meaning)

	# Spacer in place of stars + reset for unlearned words
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(116, 0)
	row.add_child(spacer)

	return row

func _stars_string(level: int) -> String:
	var filled = "★".repeat(level)
	var empty  = "☆".repeat(5 - level)
	return filled + empty

func _on_reset_word(rank: int) -> void:
	SaveManager.reset_word(rank)
	# Rebuild the list to reflect changes
	for child in word_list.get_children():
		child.queue_free()
	await get_tree().process_frame
	_populate()
