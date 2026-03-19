extends Control

# settings.gd  (Scenes/settings.gd)

const WORDS_MIN  := 5
const WORDS_MAX  := 50
const WORDS_STEP := 5

var _words_val: Label
var _dec_btn:   Button
var _inc_btn:   Button
var _vol_slider: HSlider

func _ready() -> void:
	UIStyle.make_bg(self)
	UIStyle.make_title("Settings", self)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-180, -80)
	vbox.custom_minimum_size = Vector2(360, 0)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	# ── Volume ──
	var vol_lbl = UIStyle.make_label("Volume", UIStyle.FS_HEADING, UIStyle.TEXT_DIM)
	vbox.add_child(vol_lbl)

	var vol_row = HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 12)
	vbox.add_child(vol_row)

	_vol_slider = HSlider.new()
	_vol_slider.min_value = 0.0
	_vol_slider.max_value = 1.0
	_vol_slider.step = 0.01
	_vol_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	_vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vol_slider.custom_minimum_size = Vector2(0, 32)
	_vol_slider.value_changed.connect(_on_volume_changed)
	vol_row.add_child(_vol_slider)

	var vol_pct = UIStyle.make_label("%d%%" % roundi(_vol_slider.value * 100), UIStyle.FS_BODY, UIStyle.ACCENT)
	vol_pct.custom_minimum_size = Vector2(46, 0)
	vol_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vol_row.add_child(vol_pct)
	# keep a reference so we can update it live
	_vol_slider.set_meta("pct_label", vol_pct)

	# ── Words per day ──
	var words_lbl = UIStyle.make_label("New Words Per Day", UIStyle.FS_HEADING, UIStyle.TEXT_DIM)
	vbox.add_child(words_lbl)

	var words_row = HBoxContainer.new()
	words_row.add_theme_constant_override("separation", 16)
	vbox.add_child(words_row)

	_dec_btn = UIStyle.make_button("−", UIStyle.FS_HEADING)
	_dec_btn.custom_minimum_size = Vector2(50, 0)
	_dec_btn.pressed.connect(_decrease_words)
	words_row.add_child(_dec_btn)

	_words_val = UIStyle.make_label("10", UIStyle.FS_HEADING, UIStyle.ACCENT)
	_words_val.custom_minimum_size   = Vector2(60, 0)
	_words_val.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_words_val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words_row.add_child(_words_val)

	_inc_btn = UIStyle.make_button("+", UIStyle.FS_HEADING)
	_inc_btn.custom_minimum_size = Vector2(50, 0)
	_inc_btn.pressed.connect(_increase_words)
	words_row.add_child(_inc_btn)

	_update_words_display()

	UIStyle.make_back_button(self, "res://Scenes/main_menu.tscn")

# ─────────────────────────────────────────────────────────────

func _on_volume_changed(value: float) -> void:
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	var lbl = _vol_slider.get_meta("pct_label") as Label
	if lbl:
		lbl.text = "%d%%" % roundi(value * 100)

func _decrease_words() -> void:
	QuizManager.new_words_per_day = max(QuizManager.new_words_per_day - WORDS_STEP, WORDS_MIN)
	SaveManager.save_settings()
	_update_words_display()

func _increase_words() -> void:
	QuizManager.new_words_per_day = min(QuizManager.new_words_per_day + WORDS_STEP, WORDS_MAX)
	SaveManager.save_settings()
	_update_words_display()

func _update_words_display() -> void:
	_words_val.text   = str(QuizManager.new_words_per_day)
	_dec_btn.modulate = UIStyle.TEXT_DARK if QuizManager.new_words_per_day <= WORDS_MIN else UIStyle.TEXT
	_inc_btn.modulate = UIStyle.TEXT_DARK if QuizManager.new_words_per_day >= WORDS_MAX else UIStyle.TEXT
