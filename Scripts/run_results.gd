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

	var correct_count  = results.filter(func(e): return e["correct"]).size()
	var answered_count = results.filter(func(e): return e["answered"]).size()

	summary_label.text = (
		"%d / %d correct   |   %d skipped\n" +
		"⭐ %d this run   |   ⭐ %d total\n" +
		"🔥 %d day streak   |   📖 %d words learned"
	) % [
		correct_count,
		results.size(),
		results.size() - answered_count,
		QuizManager.stars_collected,
		SaveManager.total_stars + QuizManager.stars_collected,
		SaveManager.words_introduced.size(),
		SaveManager.streak
	]

	if results.is_empty():
		return

	results_list.add_child(_make_header())
	for entry in results:
		results_list.add_child(_make_row(entry))

func _make_header() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for pair in [["", 28], ["字", 56], ["Pinyin", 110], ["Meaning", 300]]:
		var lbl = Label.new()
		lbl.text    = pair[0]
		lbl.modulate = Color(0.7, 0.7, 0.7)
		lbl.custom_minimum_size = Vector2(pair[1], 0)
		if pair[0] == "Meaning":
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
	return row

func _make_row(entry: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

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

	var chinese = Label.new()
	chinese.text                = entry["chinese"]
	chinese.custom_minimum_size = Vector2(56, 0)
	row.add_child(chinese)

	var pinyin = Label.new()
	pinyin.text                = entry["pinyin"]
	pinyin.custom_minimum_size = Vector2(110, 0)
	row.add_child(pinyin)

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
