extends Node

# ─────────────────────────────────────────────────────────────
# QuizManager — Autoload singleton  (Scripts/quiz_manager.gd)
# ─────────────────────────────────────────────────────────────

const WORD_FILE = "res://hsk1_words.json"

const TYPE_EN_TO_ZH = 0
const TYPE_PY_TO_ZH = 1
const TYPE_ZH_TO_EN = 2
const TYPE_INTRO    = 3

# Lower level = appears more often
const LEVEL_WEIGHTS = [8, 5, 3, 2, 1, 0]

var all_words:         Array      = []
var current_question:  Dictionary = {}
var run_results:       Array      = []
var stars_collected:   int        = 0

var base_move_speed:   float = 15.0
var move_speed:        float = 15.0
var speed_penalised:   bool  = false
var new_words_per_day: int   = 10

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

func prepare_run() -> void:
	SaveManager.introduce_new_words(all_words, new_words_per_day)

# ─────────────────────────────────────────────────────────────

func _pick_word(pool: Array) -> Dictionary:
	var weighted: Array = []
	for word in pool:
		var rank   = word["rank"]
		var level  = SaveManager.get_level(rank)
		var weight = LEVEL_WEIGHTS[level] if level < LEVEL_WEIGHTS.size() else 0
		for _i in weight:
			weighted.append(word)
	if weighted.is_empty():
		return pool[randi() % pool.size()]
	return weighted[randi() % weighted.size()]

func generate_question() -> void:
	var pool = SaveManager.get_active_pool(all_words)
	if pool.is_empty():
		printerr("QuizManager: no words in pool")
		return

	var unseen = pool.filter(func(w): return not SaveManager.has_seen(w["rank"]))
	if not unseen.is_empty():
		_build_intro_question(unseen[randi() % unseen.size()])
		return

	_build_quiz_question(_pick_word(pool), pool)

func _build_intro_question(word: Dictionary) -> void:
	current_question = {
		"word":         word,
		"q_type":       TYPE_INTRO,
		"correct_lane": 0,
		"answers":      [word["meaning"], word["meaning"], word["meaning"]],
		"answered":     false
	}

func _build_quiz_question(correct_word: Dictionary, pool: Array) -> void:
	var q_type = randi() % 3

	var wrong_answers: Array[String] = []
	var attempts = 0
	while wrong_answers.size() < 2 and attempts < 100:
		attempts += 1
		var candidate        = pool[randi() % pool.size()]
		var candidate_answer = _answer_for_type(candidate, q_type)
		var correct_answer   = _answer_for_type(correct_word, q_type)
		if candidate_answer != correct_answer and not wrong_answers.has(candidate_answer):
			wrong_answers.append(candidate_answer)

	var answer_options = [_answer_for_type(correct_word, q_type), wrong_answers[0], wrong_answers[1]]
	answer_options.shuffle()
	var correct_lane = answer_options.find(_answer_for_type(correct_word, q_type))

	current_question = {
		"word":         correct_word,
		"q_type":       q_type,
		"correct_lane": correct_lane,
		"answers":      answer_options,
		"answered":     false
	}

func _answer_for_type(word: Dictionary, q_type: int) -> String:
	match q_type:
		TYPE_EN_TO_ZH, TYPE_PY_TO_ZH: return word["chinese"]
		TYPE_ZH_TO_EN:                 return word["meaning"]
		_:                             return word["chinese"]

# ─────────────────────────────────────────────────────────────

func submit_answer(chosen_lane: int) -> void:
	if current_question.is_empty() or current_question.get("answered", false):
		return
	current_question["answered"] = true

	var q_type  = current_question.get("q_type", TYPE_ZH_TO_EN)
	var rank    = current_question["word"].get("rank", -1)
	var correct = (q_type == TYPE_INTRO) or (chosen_lane == current_question["correct_lane"])

	if rank >= 0:
		if not SaveManager.has_seen(rank):
			# First encounter — just mark seen, don't affect streak/level
			SaveManager.mark_word_seen(rank)
		elif q_type != TYPE_INTRO:
			# Only quiz answers count toward streak/mastery
			if correct:
				SaveManager.record_correct(rank)
			else:
				SaveManager.record_wrong(rank)

	run_results.append({
		"chinese":      current_question["word"]["chinese"],
		"pinyin":       current_question["word"]["pinyin"],
		"meaning":      current_question["word"]["meaning"],
		"correct":      correct,
		"answered":     true,
		"correct_lane": current_question["correct_lane"],
		"answers":      current_question["answers"],
		"intro":        q_type == TYPE_INTRO,
		"level":        SaveManager.get_level(rank),
		"word_streak":  SaveManager.get_word_streak(rank)
	})

	question_answered.emit(correct, current_question["correct_lane"])

# ─────────────────────────────────────────────────────────────

func reset_run() -> void:
	if stars_collected > 0:
		SaveManager.add_stars(stars_collected)
	run_results.clear()
	current_question = {}
	stars_collected  = 0
	speed_penalised  = false
	move_speed       = base_move_speed
