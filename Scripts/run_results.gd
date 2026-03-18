extends Control

# ─────────────────────────────────────────────────────────────
# run_results.gd  (Scripts/run_results.gd)
#
# FIX 4: English meaning was wrapping vertically (one letter per line)
# because the Label had no minimum width and SIZE_EXPAND_FILL alone
# doesn't work inside an HBoxContainer that has no fixed width itself.
#
# Solution: give the meaning label a large custom_minimum_size.x so
# it has room to display horizontally, and set autowrap to WORD only
# (not character), so it only breaks at spaces if it must wrap at all.
# ─────────────────────────────────────────────────────────────

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
		summary_label.text = "No quiz questions this run."
		return

	var correct_count  = results.filter(func(e): return e["correct"]).size()
	var answered_count = results.filter(func(e): return e["answered"]).size()
	summary_label.text = "%d / %d correct   (%d skipped)" % [
		correct_count, results.size(), results.size() - answered_count
	]

	for entry in results:
		results_list.add_child(_make_row(entry))

func _make_row(entry: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	# ── Status icon ──
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

	# ── Chinese character ──
	var chinese = Label.new()
	chinese.text               = entry["chinese"]
	chinese.custom_minimum_size = Vector2(56, 0)
	row.add_child(chinese)

	# ── Pinyin ──
	var pinyin = Label.new()
	pinyin.text                = entry["pinyin"]
	pinyin.custom_minimum_size = Vector2(110, 0)
	row.add_child(pinyin)

	# ── English meaning ──
	# FIX: custom_minimum_size.x = 300 ensures the label has enough
	# horizontal room. SIZE_EXPAND_FILL then fills whatever is left.
	# AUTOWRAP_WORD means it only wraps at spaces, never mid-word.
	var meaning = Label.new()
	meaning.text                = entry["meaning"]
	meaning.custom_minimum_size = Vector2(300, 0)
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meaning.autowrap_mode       = TextServer.AUTOWRAP_WORD
	row.add_child(meaning)

	return row

func _on_continue() -> void:
	QuizManager.reset_run()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
