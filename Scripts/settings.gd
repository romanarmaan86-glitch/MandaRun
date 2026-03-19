extends Control

# settings.gd  (Scenes/settings.gd)

const SPEED_EASY   := 9.0
const SPEED_NORMAL := 15.0
const SPEED_HARD   := 23.0
const WORDS_MIN    := 5
const WORDS_MAX    := 50
const WORDS_STEP   := 5

var _diff_btns:    Array = []
var _words_val:    Label
var _dec_btn:      Button
var _inc_btn:      Button

func _ready() -> void:
	UIStyle.make_bg(self)
	UIStyle.make_title("Settings", self)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-180, -100)
	vbox.custom_minimum_size = Vector2(360, 0)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	# ── Difficulty ──
	var diff_lbl = UIStyle.make_label("Difficulty", UIStyle.FS_HEADING, UIStyle.TEXT_DIM)
	vbox.add_child(diff_lbl)

	var diff_row = HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 10)
	vbox.add_child(diff_row)

	for pair in [["Easy", SPEED_EASY], ["Normal", SPEED_NORMAL], ["Hard", SPEED_HARD]]:
		var btn = UIStyle.make_button(pair[0], UIStyle.FS_BODY)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_difficulty.bind(pair[1], btn))
		diff_row.add_child(btn)
		_diff_btns.append({"btn": btn, "speed": pair[1]})

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
	_words_val.custom_minimum_size    = Vector2(60, 0)
	_words_val.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	_words_val.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	words_row.add_child(_words_val)

	_inc_btn = UIStyle.make_button("+", UIStyle.FS_HEADING)
	_inc_btn.custom_minimum_size = Vector2(50, 0)
	_inc_btn.pressed.connect(_increase_words)
	words_row.add_child(_inc_btn)

	# Apply current values
	_highlight_difficulty(QuizManager.base_move_speed)
	_update_words_display()

	UIStyle.make_back_button(self, "res://Scenes/main_menu.tscn")

# ─────────────────────────────────────────────────────────────

func _on_difficulty(speed: float, btn: Button) -> void:
	QuizManager.base_move_speed = speed
	QuizManager.move_speed      = speed
	QuizManager.speed_penalised = false
	SaveManager.save_settings()
	_highlight_difficulty(speed)

func _highlight_difficulty(active_speed: float) -> void:
	for entry in _diff_btns:
		var is_active = is_equal_approx(entry["speed"], active_speed)
		entry["btn"].modulate = UIStyle.GREEN if is_active else UIStyle.TEXT

func _decrease_words() -> void:
	QuizManager.new_words_per_day = max(QuizManager.new_words_per_day - WORDS_STEP, WORDS_MIN)
	SaveManager.save_settings()
	_update_words_display()

func _increase_words() -> void:
	QuizManager.new_words_per_day = min(QuizManager.new_words_per_day + WORDS_STEP, WORDS_MAX)
	SaveManager.save_settings()
	_update_words_display()

func _update_words_display() -> void:
	_words_val.text    = str(QuizManager.new_words_per_day)
	_dec_btn.modulate  = UIStyle.TEXT_DARK if QuizManager.new_words_per_day <= WORDS_MIN else UIStyle.TEXT
	_inc_btn.modulate  = UIStyle.TEXT_DARK if QuizManager.new_words_per_day >= WORDS_MAX else UIStyle.TEXT
