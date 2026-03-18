extends Node

# ─────────────────────────────────────────────────────────────
# QuizManager — Autoload singleton  (Scripts/quiz_manager.gd)
# ─────────────────────────────────────────────────────────────

const WORD_FILE = "res://hsk1_words.json"

var all_words:        Array      = []
var current_question: Dictionary = {}
var run_results:      Array      = []
var stars_collected:  int        = 0   # stars this run only

var base_move_speed:  float = 15.0
var move_speed:       float = 15.0
var speed_penalised:  bool  = false

# How many new words to introduce per run start (set in settings)
var new_words_per_day: int = 10

signal question_answered(correct: bool, correct_lane: int)

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_words()

func _load_words() -> void:
	if not FileAccess.file_exists(WORD_FILE):
		printerr("QuizManager: hsk1_words.json not found")
		return
	var file   = FileAccess.open(WORD_FILE, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		all_words = parsed
		print("QuizManager: loaded ", all_words.size(), " words")
	else:
		printerr("QuizManager: failed to parse hsk1_words.json")

# ─────────────────────────────────────────────────────────────
# Call this when a run starts — introduces today's new words

func prepare_run() -> void:
	SaveManager.introduce_new_words(all_words, new_words_per_day)

# ─────────────────────────────────────────────────────────────

func generate_question() -> void:
	var pool = SaveManager.get_active_pool(all_words)
	if pool.is_empty():
		printerr("QuizManager: no words introduced yet — run prepare_run() first")
		return

	var correct_word = pool[randi() % pool.size()]

	var wrong_answers: Array[String] = []
	var attempts = 0
	while wrong_answers.size() < 2 and attempts < 100:
		attempts += 1
		var candidate = pool[randi() % pool.size()]
		if candidate["meaning"] != correct_word["meaning"] and \
		   not wrong_answers.has(candidate["meaning"]):
			wrong_answers.append(candidate["meaning"])

	var answer_meanings = [correct_word["meaning"], wrong_answers[0], wrong_answers[1]]
	answer_meanings.shuffle()
	var correct_lane = answer_meanings.find(correct_word["meaning"])

	current_question = {
		"word":         correct_word,
		"correct_lane": correct_lane,
		"answers":      answer_meanings,
		"answered":     false
	}

# ─────────────────────────────────────────────────────────────

func submit_answer(chosen_lane: int) -> void:
	if current_question.is_empty() or current_question.get("answered", false):
		return
	current_question["answered"] = true
	var correct = chosen_lane == current_question["correct_lane"]

	run_results.append({
		"chinese":      current_question["word"]["chinese"],
		"pinyin":       current_question["word"]["pinyin"],
		"meaning":      current_question["word"]["meaning"],
		"correct":      correct,
		"answered":     true,
		"correct_lane": current_question["correct_lane"],
		"answers":      current_question["answers"]
	})

	question_answered.emit(correct, current_question["correct_lane"])

# ─────────────────────────────────────────────────────────────

func reset_run() -> void:
	# Save stars accumulated this run to persistent total
	if stars_collected > 0:
		SaveManager.add_stars(stars_collected)

	run_results.clear()
	current_question = {}
	stars_collected  = 0
	speed_penalised  = false
	move_speed       = base_move_speed
