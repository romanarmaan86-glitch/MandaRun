extends Control

# run_results.gd  (Scripts/run_results.gd)

func _ready() -> void:
	UIStyle.make_bg(self)
	UIStyle.make_title("Run Results", self)

	# Summary panel
	var summary_panel = PanelContainer.new()
	summary_panel.add_theme_stylebox_override("panel", UIStyle.card_style())
	summary_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	summary_panel.position = Vector2(-280, 80)
	summary_panel.custom_minimum_size = Vector2(560, 0)
	add_child(summary_panel)

	var summary_lbl = UIStyle.make_label("", UIStyle.FS_BODY, UIStyle.ACCENT)
	summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_panel.add_child(summary_lbl)

	# Results list
	var results_list = UIStyle.make_scroll(self, 180, -80)

	# Continue button
	var cont_btn = UIStyle.make_button("Continue", UIStyle.FS_BODY)
	cont_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cont_btn.offset_left   = -220
	cont_btn.offset_top    = -60
	cont_btn.offset_right  = -20
	cont_btn.offset_bottom = -10
	cont_btn.pressed.connect(_on_continue)
	add_child(cont_btn)

	# Populate
	var all_results   = QuizManager.run_results
	var answered      = all_results.filter(func(e): return e["answered"])
	var correct_count = answered.filter(func(e): return e["correct"]).size()

	summary_lbl.text = "%d / %d correct   |   ⭐ %d this run   |   ⭐ %d total" % [
		correct_count,
		answered.size(),
		QuizManager.stars_collected,
		SaveManager.total_stars + QuizManager.stars_collected
	]

	if answered.is_empty():
		var empty_lbl = UIStyle.make_label("No questions answered this run.", UIStyle.FS_BODY, UIStyle.TEXT_DIM)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		results_list.add_child(empty_lbl)
		return

	# Header
	results_list.add_child(_make_header())
	for entry in answered:
		results_list.add_child(_make_row(entry))

func _make_header() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for pair in [["", 28], ["字", 50], ["Pinyin", 110], ["Meaning", 300]]:
		var lbl = UIStyle.make_label(pair[0], UIStyle.FS_SMALL, UIStyle.TEXT_DIM)
		lbl.custom_minimum_size = Vector2(pair[1], 0)
		if pair[0] == "Meaning":
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
	return row

func _make_row(entry: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.card_style())

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var status = UIStyle.make_label(
		"✓" if entry["correct"] else "✗",
		UIStyle.FS_BODY,
		UIStyle.GREEN if entry["correct"] else UIStyle.RED
	)
	status.custom_minimum_size = Vector2(28, 0)
	hbox.add_child(status)

	var chinese = UIStyle.make_label(entry["chinese"], 20)
	chinese.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(chinese)

	var pinyin = UIStyle.make_label(entry["pinyin"], UIStyle.FS_SMALL, UIStyle.TEXT_DIM)
	pinyin.custom_minimum_size = Vector2(110, 0)
	hbox.add_child(pinyin)

	var meaning = UIStyle.make_label(entry["meaning"], UIStyle.FS_SUB)
	meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meaning.autowrap_mode         = TextServer.AUTOWRAP_WORD
	hbox.add_child(meaning)

	return panel

func _on_continue() -> void:
	QuizManager.reset_run()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
