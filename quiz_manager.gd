extends Node

# ─────────────────────────────────────────────────────────────
# QuizManager — Autoload singleton
# Add to Project > Project Settings > Autoload as "QuizManager"
# ─────────────────────────────────────────────────────────────

const WORD_FILE = "res://hsk1_words.json"
const NEW_WORDS_PER_DAY = 10

# All 500 words loaded from JSON
var all_words: Array = []

# Words unlocked so far (rank <= unlocked_up_to)
var unlocked_up_to: int = NEW_WORDS_PER_DAY

# Active question for the current quiz platform
var current_question: Dictionary = {}
# { "word": {...}, "correct_lane": int, "answers": [str, str, str] }
# answers[i] is what's displayed on lane i (0=left, 1=mid, 2=right)

# Results accumulated during this run
# Each entry: { "chinese": str, "pinyin": str, "meaning": str,
#               "correct": bool, "answered": bool }
var run_results: Array = []

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_words()

func _load_words() -> void:
	if not FileAccess.file_exists(WORD_FILE):
		printerr("QuizManager: hsk1_words.json not found at ", WORD_FILE)
		return
	var file = FileAccess.open(WORD_FILE, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		all_words = parsed
		print("QuizManager: loaded ", all_words.size(), " words")
	else:
		printerr("QuizManager: failed to parse hsk1_words.json")

# ─────────────────────────────────────────────────────────────
# Call this when a quiz platform is about to spawn.
# Picks a random word from unlocked pool, generates 2 wrong answers,
# assigns all 3 to random lanes.

func generate_question() -> void:
	if all_words.is_empty():
		return

	# Pick from unlocked words (index 0 .. unlocked_up_to - 1)
	var pool_size = min(unlocked_up_to, all_words.size())
	var correct_word = all_words[randi() % pool_size]

	# Pick 2 wrong answers (different words, different meanings)
	var wrong_answers: Array[String] = []
	var attempts = 0
	while wrong_answers.size() < 2 and attempts < 100:
		attempts += 1
		var candidate = all_words[randi() % pool_size]
		if candidate["meaning"] != correct_word["meaning"] and \
		   not wrong_answers.has(candidate["meaning"]):
			wrong_answers.append(candidate["meaning"])

	# Build answer list: correct meaning + 2 wrong, then shuffle into 3 lanes
	var answer_meanings = [correct_word["meaning"], wrong_answers[0], wrong_answers[1]]
	answer_meanings.shuffle()

	var correct_lane = answer_meanings.find(correct_word["meaning"])

	current_question = {
		"word": correct_word,
		"correct_lane": correct_lane,
		"answers": answer_meanings,
		"answered": false
	}

# ─────────────────────────────────────────────────────────────
# Called by answer_panel when the player walks through a panel.

func submit_answer(chosen_lane: int) -> void:
	if current_question.is_empty() or current_question.get("answered", false):
		return

	current_question["answered"] = true
	var correct = chosen_lane == current_question["correct_lane"]

	run_results.append({
		"chinese":  current_question["word"]["chinese"],
		"pinyin":   current_question["word"]["pinyin"],
		"meaning":  current_question["word"]["meaning"],
		"correct":  correct,
		"answered": true
	})

	# Emit signal so quiz_platform can show the flash overlay
	question_answered.emit(correct, current_question["correct_lane"])

# ─────────────────────────────────────────────────────────────
# Called when a quiz platform passes without the player hitting any panel.

func skip_question() -> void:
	if current_question.is_empty() or current_question.get("answered", false):
		return
	current_question["answered"] = true
	run_results.append({
		"chinese":  current_question["word"]["chinese"],
		"pinyin":   current_question["word"]["pinyin"],
		"meaning":  current_question["word"]["meaning"],
		"correct":  false,
		"answered": false   # false = skipped (no panel hit)
	})

# ─────────────────────────────────────────────────────────────

func reset_run() -> void:
	run_results.clear()
	current_question = {}

# ─────────────────────────────────────────────────────────────

signal question_answered(correct: bool, correct_lane: int)
