extends Control

# word_list.gd  (Scripts/word_list.gd)

var _all_words:   Array = []
var _search_term: String = ""
var _word_list:   VBoxContainer
var _search_box:  LineEdit

func _ready() -> void:
	UIStyle.make_bg(self)
	UIStyle.make_title("My Words", self)

	# Search box
	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search chinese, pinyin, meaning..."
	_search_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_search_box.position = Vector2(-280, 80)
	_search_box.custom_minimum_size = Vector2(560, 40)
	_search_box.text_changed.connect(_on_search)
	add_child(_search_box)

	_word_list = UIStyle.make_scroll(self, 134, -20)
	UIStyle.make_back_button(self, "res://Scenes/words_hub.tscn")

	_all_words = WordPacks.load_words_for_pack(SaveManager.active_pack)
	_rebuild()

func _on_search(text: String) -> void:
	_search_term = text.to_lower().strip_edges()
	_rebuild()

func _rebuild() -> void:
	for child in _word_list.get_children():
		child.queue_free()
	await get_tree().process_frame

	var learned:   Array = []
	var unlearned: Array = []

	for word in _all_words:
		if _search_term != "":
			if not (word["chinese"].to_lower().contains(_search_term) or
					word["pinyin"].to_lower().contains(_search_term) or
					word["meaning"].to_lower().contains(_search_term)):
				continue
		if SaveManager.has_seen(word["rank"]):
			learned.append(word)
		else:
			unlearned.append(word)

	learned.sort_custom(func(a, b):
		return SaveManager.get_level(a["rank"]) > SaveManager.get_level(b["rank"])
	)

	for word in learned:
		_word_list.add_child(_make_learned_row(word))
	for word in unlearned:
		_word_list.add_child(_make_unlearned_row(word))

func _make_learned_row(word: Dictionary) -> PanelContainer:
	var rank  = word["rank"]
	var level = SaveManager.get_level(rank)
	var ws    = SaveManager.get_word_streak(rank)

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.card_style())

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var chinese = UIStyle.make_label(word["chinese"], 22)
	chinese.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(chinese)

	var pinyin = UIStyle.make_label(word["pinyin"], UIStyle.FS_SUB, UIStyle.TEXT_DIM)
	pinyin.custom_minimum_size = Vector2(110, 0)
	hbox.add_child(pinyin)

	var meaning = UIStyle.make_label(word["meaning"], UIStyle.FS_SUB)
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meaning.autowrap_mode         = TextServer.AUTOWRAP_WORD
	hbox.add_child(meaning)

	# Stars + streak
	var prog = UIStyle.make_label("%s %d/3" % [_stars_str(level), ws], UIStyle.FS_SMALL, UIStyle.ACCENT)
	prog.custom_minimum_size      = Vector2(90, 0)
	prog.horizontal_alignment     = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(prog)

	var reset_btn = UIStyle.make_button("↺", UIStyle.FS_SUB)
	reset_btn.custom_minimum_size = Vector2(40, 0)
	reset_btn.pressed.connect(_on_reset.bind(rank))
	hbox.add_child(reset_btn)

	return panel

func _make_unlearned_row(word: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = UIStyle.card_style()
	style.bg_color = Color(0.10, 0.10, 0.16)
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate = Color(0.4, 0.4, 0.4)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var chinese = UIStyle.make_label(word["chinese"], 22)
	chinese.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(chinese)

	var pinyin = UIStyle.make_label(word["pinyin"], UIStyle.FS_SUB)
	pinyin.custom_minimum_size = Vector2(110, 0)
	hbox.add_child(pinyin)

	var meaning = UIStyle.make_label(word["meaning"], UIStyle.FS_SUB)
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meaning.autowrap_mode         = TextServer.AUTOWRAP_WORD
	hbox.add_child(meaning)

	return panel

func _stars_str(level: int) -> String:
	return "★".repeat(level) + "☆".repeat(5 - level)

func _on_reset(rank: int) -> void:
	SaveManager.reset_word(rank)
	_rebuild()
