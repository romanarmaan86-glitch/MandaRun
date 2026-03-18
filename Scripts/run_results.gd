extends Control

# run_results.gd  (Scripts/run_results.gd)

@onready var title_label:   Label         = $TitleLabel
@onready var summary_label: Label         = $SummaryLabel
@onready var results_list:  VBoxContainer = $ScrollContainer/ResultsList
@onready var continue_btn:  Button        = $ContinueButton

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	title_label.text = "Run Results"
	_populate()

func _populate() -> void:
	var results = QuizManager.run_results

	if results.is_empty():
		summary_label.text = "No quiz questions this run.\nStars collected: %d" % QuizManager.stars_collected
		return

	var correct_count  = results.filter(func(e): return e["correct"]).size()
	var answered_count = results.filter(func(e): return e["answered"]).size()

	summary_label.text = "%d / %d correct   |   %d skipped   |   ⭐ %d stars" % [
		correct_count,
		results.size(),
		results.size() - answered_count,
		QuizManager.stars_collected
	]

	# Header row
	results_list.add_child(_make_header())

	for entry in results:
		results_list.add_child(_make_row(entry))

func _make_header() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for text in ["", "字", "Pinyin", "Meaning"]:
		var lbl = Label.new()
		lbl.text = text
		lbl.modulate = Color(0.7, 0.7, 0.7)
		match text:
			"":       lbl.custom_minimum_size = Vector2(28, 0)
			"字":      lbl.custom_minimum_size = Vector2(56, 0)
			"Pinyin": lbl.custom_minimum_size = Vector2(110, 0)
			"Meaning":
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.custom_minimum_size   = Vector2(300, 0)
		row.add_child(lbl)
	return row

func _make_row(entry: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	# Status
	var status = Label.new()
	if not entry["answered"]:
		status.text     = "–"
		status.modulate = Color(0.6, 0.6, 0.6)
	elif entry["correct"]:
		status.text     = "✓"
		status.modulate = Color(0.2, 0.9, 0.3)
	else:
		status.text     = "✗"
		status.modulate = Color(0.9, 0.2, 0.2)
	status.custom_minimum_size = Vector2(28, 0)
	row.add_child(status)

	# Chinese
	var chinese = Label.new()
	chinese.text                = entry["chinese"]
	chinese.custom_minimum_size = Vector2(56, 0)
	row.add_child(chinese)

	# Pinyin
	var pinyin = Label.new()
	pinyin.text                = entry["pinyin"]
	pinyin.custom_minimum_size = Vector2(110, 0)
	row.add_child(pinyin)

	# Meaning — fixed width so it never wraps character-by-character
	var meaning = Label.new()
	meaning.text                  = entry["meaning"]
	meaning.custom_minimum_size   = Vector2(300, 0)
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meaning.autowrap_mode         = TextServer.AUTOWRAP_WORD
	row.add_child(meaning)

	return row

func _on_continue() -> void:
	QuizManager.reset_run()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
