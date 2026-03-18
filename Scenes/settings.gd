extends Control

# settings.gd  (Scenes/settings.gd)

@onready var easy_btn:   Button = $DifficultyButtons/EasyBtn
@onready var normal_btn: Button = $DifficultyButtons/NormalBtn
@onready var hard_btn:   Button = $DifficultyButtons/HardBtn

const SPEED_EASY   := 9.0
const SPEED_NORMAL := 15.0
const SPEED_HARD   := 23.0

func _ready() -> void:
	easy_btn.pressed.connect(func():   _select(SPEED_EASY,   easy_btn))
	normal_btn.pressed.connect(func(): _select(SPEED_NORMAL, normal_btn))
	hard_btn.pressed.connect(func():   _select(SPEED_HARD,   hard_btn))

	var current = QuizManager.base_move_speed
	match current:
		SPEED_EASY:  _highlight(easy_btn)
		SPEED_HARD:  _highlight(hard_btn)
		_:           _highlight(normal_btn)

func _select(speed: float, btn: Button) -> void:
	# Set both so penalty restore always returns to the chosen difficulty
	QuizManager.base_move_speed = speed
	QuizManager.move_speed      = speed
	QuizManager.speed_penalised = false
	_highlight(btn)

func _highlight(active: Button) -> void:
	for b in [easy_btn, normal_btn, hard_btn]:
		b.modulate = Color(1.0, 1.0, 1.0) if b == active else Color(0.5, 0.5, 0.5)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
