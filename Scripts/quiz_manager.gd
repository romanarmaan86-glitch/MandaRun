extends Node

# ─────────────────────────────────────────────────────────────
# QuizManager — Autoload singleton  (Scripts/quiz_manager.gd)
# ─────────────────────────────────────────────────────────────

const WORD_FILE        = "res://hsk1_words.json"
const NEW_WORDS_PER_DAY = 10

var all_words:      Array = []
var unlocked_up_to: int   = NEW_WORDS_PER_DAY
var current_question: Dictionary = {}
var run_results:    Array = []
var stars_collected: int  = 0   # incremented by star.gd on collect

signal question_answered(correct: bool, correct_lane: int)

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_words()

func _load_words() -> void:
	if not FileAccess.file_exists(WORD_FILE):
		printerr("QuizManager: hsk1_words.json not found at ", WORD_FILE)
		return
	var file   = FileAccess.open(WORD_FILE, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		all_words = parsed
		print("QuizManager: loaded ", all_words.size(), " words")
	else:
		printerr("QuizManager: failed to parse hsk1_words.json")

# ─────────────────────────────────────────────────────────────

func generate_question() -> void:
	if all_words.is_empty():
		return

	var pool_size   = min(unlocked_up_to, all_words.size())
	var correct_word = all_words[randi() % pool_size]

	var wrong_answers: Array[String] = []
	var attempts = 0
	while wrong_answers.size() < 2 and attempts < 100:
		attempts += 1
		var candidate = all_words[randi() % pool_size]
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
	run_results.clear()
	current_question = {}
	stars_collected  = 0
