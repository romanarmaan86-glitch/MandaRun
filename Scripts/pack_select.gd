extends Control

# pack_select.gd  (Scripts/pack_select.gd)

var _selected_pack: String = ""
var _pack_list: VBoxContainer
var _start_btn: Button

# Difficulty definitions: [label, move_speed, spawn_chance]
const DIFFICULTIES = [
	{ "label": "🐢  Easy",   "speed": 12.5, "spawn_chance": 0.70 },
	{ "label": "⚡  Normal", "speed": 17.0, "spawn_chance": 0.85 },
	{ "label": "💀  Hard",   "speed": 22.0, "spawn_chance": 0.95 },
]
var _selected_difficulty: int = 1  # default: Normal

func _ready() -> void:
	_selected_pack = SaveManager.active_pack

	UIStyle.make_bg(self)
	UIStyle.make_title("Choose a Pack", self)

	_pack_list = UIStyle.make_scroll(self, 90, -170)

	# ── Difficulty row ──────────────────────────────────────
	var diff_label = UIStyle.make_label("Difficulty", UIStyle.FS_SUB, UIStyle.TEXT_DIM)
	diff_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	diff_label.offset_left   = 20
	diff_label.offset_top    = -162
	diff_label.offset_right  = 200
	diff_label.offset_bottom = -132
	add_child(diff_label)

	var diff_row = HBoxContainer.new()
	diff_row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	diff_row.offset_left   = 20
	diff_row.offset_top    = -130
	diff_row.offset_right  = -20
	diff_row.offset_bottom = -90
	diff_row.add_theme_constant_override("separation", 10)
	add_child(diff_row)

	for i in DIFFICULTIES.size():
		var btn = UIStyle.make_button(DIFFICULTIES[i]["label"], UIStyle.FS_SUB)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == _selected_difficulty:
			_highlight_diff_btn(btn, true)
		btn.pressed.connect(_on_difficulty.bind(i, diff_row))
		diff_row.add_child(btn)

	# ── Start button ────────────────────────────────────────
	_start_btn = UIStyle.make_button("▶  Start Run", UIStyle.FS_BODY)
	_start_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_start_btn.offset_left   = -200
	_start_btn.offset_top    = -60
	_start_btn.offset_right  = -20
	_start_btn.offset_bottom = -10
	_start_btn.pressed.connect(_on_start)
	add_child(_start_btn)

	UIStyle.make_back_button(self, "res://Scenes/main_menu.tscn")
	_populate()

# ── Difficulty helpers ───────────────────────────────────────

func _highlight_diff_btn(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_stylebox_override("normal", UIStyle.button_style(Color(0.25, 0.55, 0.25)))
		btn.modulate = UIStyle.GREEN
	else:
		btn.add_theme_stylebox_override("normal", UIStyle.button_style())
		btn.modulate = UIStyle.TEXT

func _on_difficulty(index: int, diff_row: HBoxContainer) -> void:
	_selected_difficulty = index
	for i in diff_row.get_child_count():
		_highlight_diff_btn(diff_row.get_child(i) as Button, i == index)

# ── Pack list ────────────────────────────────────────────────

func _populate() -> void:
	for child in _pack_list.get_children():
		child.queue_free()

	for pack in WordPacks.get_all_packs():
		if SaveManager.owns_pack(pack["id"]):
			_pack_list.add_child(_make_row(pack))

	_start_btn.disabled = _selected_pack.is_empty()

func _make_row(pack: Dictionary) -> PanelContainer:
	var is_selected = (_selected_pack == pack["id"])
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.card_style(is_selected))

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_lbl = UIStyle.make_label(pack["name"], UIStyle.FS_HEADING)
	vbox.add_child(name_lbl)

	var sub_lbl = UIStyle.make_label("%d words  •  %s" % [pack["size"], pack["desc"]], UIStyle.FS_SMALL, UIStyle.TEXT_DIM)
	vbox.add_child(sub_lbl)

	var sel_btn = UIStyle.make_button("✓ Selected" if is_selected else "Select", UIStyle.FS_SUB)
	sel_btn.modulate = UIStyle.GREEN if is_selected else UIStyle.TEXT
	sel_btn.pressed.connect(_on_select.bind(pack["id"]))
	hbox.add_child(sel_btn)

	return panel

func _on_select(pack_id: String) -> void:
	_selected_pack = pack_id
	SaveManager.set_active_pack(pack_id)
	_populate()

func _on_start() -> void:
	if not _selected_pack.is_empty():
		# Apply chosen difficulty
		var diff = DIFFICULTIES[_selected_difficulty]
		QuizManager.base_move_speed = diff["speed"]
		QuizManager.move_speed      = diff["speed"]
		# Spawn chance is read by obstaclespawner at runtime via this property
		# We store it on QuizManager so it survives the scene change
		QuizManager.set_meta("spawn_chance", diff["spawn_chance"])
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
