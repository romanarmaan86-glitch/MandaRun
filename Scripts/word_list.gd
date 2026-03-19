extends Control

# word_list.gd  (Scripts/word_list.gd)
#
# Scene structure (Scenes/word_list.tscn):
#   Control (root, this script)
#     Panel
#     Label          (name: TitleLabel,  text: "My Words")
#     LineEdit       (name: SearchBox,   placeholder: "Search...")
#     ScrollContainer
#       VBoxContainer  (name: WordList)
#     Button         (name: BackBtn,    text: "Back")

@onready var word_list:  VBoxContainer = $ScrollContainer/WordList
@onready var search_box: LineEdit      = $SearchBox
@onready var back_btn:   Button        = $BackBtn

var _all_words: Array = []
var _search_term: String = ""

func _ready() -> void:
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/words_hub.tscn")
	)
	search_box.text_changed.connect(_on_search_changed)

	# Load words from active pack
	_all_words = WordPacks.load_words_for_pack(SaveManager.active_pack)
	_rebuild()

func _on_search_changed(new_text: String) -> void:
	_search_term = new_text.to_lower().strip_edges()
	_rebuild()

func _rebuild() -> void:
	for child in word_list.get_children():
		child.queue_free()
	await get_tree().process_frame

	var learned:   Array = []
	var unlearned: Array = []

	for word in _all_words:
		# Apply search filter
		if _search_term != "":
			var chinese = word["chinese"].to_lower()
			var pinyin  = word["pinyin"].to_lower()
			var meaning = word["meaning"].to_lower()
			if not (chinese.contains(_search_term) or
					pinyin.contains(_search_term) or
					meaning.contains(_search_term)):
				continue

		var rank = word["rank"]
		if SaveManager.has_seen(rank):
			learned.append(word)
		else:
			unlearned.append(word)

	learned.sort_custom(func(a, b):
		return SaveManager.get_level(a["rank"]) > SaveManager.get_level(b["rank"])
	)

	for word in learned:
		word_list.add_child(_make_learned_row(word))
	for word in unlearned:
		word_list.add_child(_make_unlearned_row(word))

func _make_learned_row(word: Dictionary) -> HBoxContainer:
	var rank  = word["rank"]
	var level = SaveManager.get_level(rank)
	var ws    = SaveManager.get_word_streak(rank)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var chinese = Label.new()
	chinese.text                = word["chinese"]
	chinese.custom_minimum_size = Vector2(50, 0)
	chinese.add_theme_font_size_override("font_size", 22)
	row.add_child(chinese)

	var pinyin = Label.new()
	pinyin.text                = word["pinyin"]
	pinyin.custom_minimum_size = Vector2(100, 0)
	pinyin.modulate            = Color(0.8, 0.8, 0.8)
	pinyin.add_theme_font_size_override("font_size", 14)
	row.add_child(pinyin)

	var meaning = Label.new()
	meaning.text                  = word["meaning"]
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meaning.autowrap_mode         = TextServer.AUTOWRAP_WORD
	meaning.add_theme_font_size_override("font_size", 14)
	row.add_child(meaning)

	# Stars + streak progress (e.g. ★★★☆☆  2/3)
	var progress = Label.new()
	progress.text                = "%s  %d/3" % [_stars_string(level), ws]
	progress.custom_minimum_size = Vector2(110, 0)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress.add_theme_font_size_override("font_size", 13)
	row.add_child(progress)

	var reset_btn = Button.new()
	reset_btn.text                = "↺"
	reset_btn.custom_minimum_size = Vector2(36, 0)
	reset_btn.tooltip_text        = "Reset progress for this word"
	reset_btn.pressed.connect(_on_reset_word.bind(rank))
	row.add_child(reset_btn)

	return row

func _make_unlearned_row(word: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.modulate = Color(0.35, 0.35, 0.35)

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

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(146, 0)
	row.add_child(spacer)

	return row

func _stars_string(level: int) -> String:
	return "★".repeat(level) + "☆".repeat(5 - level)

func _on_reset_word(rank: int) -> void:
	SaveManager.reset_word(rank)
	_rebuild()
