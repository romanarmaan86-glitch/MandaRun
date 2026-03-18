extends Control

# settings.gd  (Scenes/settings.gd)

@onready var easy_btn:      Button = $DifficultyButtons/EasyBtn
@onready var normal_btn:    Button = $DifficultyButtons/NormalBtn
@onready var hard_btn:      Button = $DifficultyButtons/HardBtn
@onready var words_label:   Label  = $WordsPerDayLabel
@onready var words_decrease:Button = $WordsPerDayButtons/DecreaseBtn
@onready var words_value:   Label  = $WordsPerDayButtons/ValueLabel
@onready var words_increase:Button = $WordsPerDayButtons/IncreaseBtn

const SPEED_EASY   := 9.0
const SPEED_NORMAL := 15.0
const SPEED_HARD   := 23.0

const WORDS_MIN  := 5
const WORDS_MAX  := 50
const WORDS_STEP := 5

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	easy_btn.pressed.connect(func():   _select_difficulty(SPEED_EASY,   easy_btn))
	normal_btn.pressed.connect(func(): _select_difficulty(SPEED_NORMAL, normal_btn))
	hard_btn.pressed.connect(func():   _select_difficulty(SPEED_HARD,   hard_btn))
	words_decrease.pressed.connect(_decrease_words)
	words_increase.pressed.connect(_increase_words)

	match QuizManager.base_move_speed:
		SPEED_EASY:  _highlight_difficulty(easy_btn)
		SPEED_HARD:  _highlight_difficulty(hard_btn)
		_:           _highlight_difficulty(normal_btn)

	_update_words_display()

# ─────────────────────────────────────────────────────────────

func _select_difficulty(speed: float, btn: Button) -> void:
	QuizManager.base_move_speed = speed
	QuizManager.move_speed      = speed
	QuizManager.speed_penalised = false
	_highlight_difficulty(btn)
	SaveManager.save_settings()   # persist immediately

func _highlight_difficulty(active: Button) -> void:
	for b in [easy_btn, normal_btn, hard_btn]:
		b.modulate = Color(1.0, 1.0, 1.0) if b == active else Color(0.5, 0.5, 0.5)

func _decrease_words() -> void:
	QuizManager.new_words_per_day = max(QuizManager.new_words_per_day - WORDS_STEP, WORDS_MIN)
	_update_words_display()
	SaveManager.save_settings()   # persist immediately

func _increase_words() -> void:
	QuizManager.new_words_per_day = min(QuizManager.new_words_per_day + WORDS_STEP, WORDS_MAX)
	_update_words_display()
	SaveManager.save_settings()   # persist immediately

func _update_words_display() -> void:
	words_value.text        = str(QuizManager.new_words_per_day)
	words_decrease.modulate = Color(0.5, 0.5, 0.5) if QuizManager.new_words_per_day <= WORDS_MIN else Color(1, 1, 1)
	words_increase.modulate = Color(0.5, 0.5, 0.5) if QuizManager.new_words_per_day >= WORDS_MAX else Color(1, 1, 1)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
