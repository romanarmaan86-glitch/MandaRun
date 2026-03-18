extends Node

# ─────────────────────────────────────────────────────────────
# SaveManager — Autoload singleton  (Scripts/save_manager.gd)
# Add to Project > Autoloads as "SaveManager" ABOVE QuizManager
# ─────────────────────────────────────────────────────────────

const SAVE_PATH = "user://save.json"

var last_played_date:       String = ""
var words_introduced:       Array  = []
var new_words_today:        int    = 0
var total_stars:            int    = 0
var streak:                 int    = 0
var saved_move_speed:       float  = 15.0
var saved_new_words_per_day: int   = 10

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	load_save()
	_apply_saved_settings()
	_check_day_change()

func _apply_saved_settings() -> void:
	QuizManager.base_move_speed   = saved_move_speed
	QuizManager.move_speed        = saved_move_speed
	QuizManager.new_words_per_day = saved_new_words_per_day

func _check_day_change() -> void:
	var today = _today_string()

	if last_played_date == "":
		# Very first launch — just record today, streak starts at 0
		last_played_date = today
		streak           = 0
		save()
		return

	if today == last_played_date:
		return   # Same day, nothing to do

	# It's a new day — check if consecutive before resetting
	if _is_consecutive(last_played_date, today):
		streak += 1
	else:
		streak = 1   # gap in play, restart streak at 1

	last_played_date = today
	new_words_today  = 0
	save()

func _today_string() -> String:
	var t = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t["year"], t["month"], t["day"]]

func _is_consecutive(prev: String, today: String) -> bool:
	# Guard against empty or malformed strings
	if prev.length() < 10 or today.length() < 10:
		return false
	var prev_unix  = Time.get_unix_time_from_datetime_string(prev  + "T00:00:00")
	var today_unix = Time.get_unix_time_from_datetime_string(today + "T00:00:00")
	# Consecutive = exactly one day apart (86400 seconds)
	return (today_unix - prev_unix) == 86400

# ─────────────────────────────────────────────────────────────

func introduce_new_words(all_words: Array, max_new: int) -> void:
	var remaining_slots = max_new - new_words_today
	if remaining_slots <= 0:
		return

	var introduced_set = {}
	for rank in words_introduced:
		introduced_set[rank] = true

	var added = 0
	for word in all_words:
		if added >= remaining_slots:
			break
		var rank = word["rank"]
		if not introduced_set.has(rank):
			words_introduced.append(rank)
			introduced_set[rank] = true
			added += 1

	if added > 0:
		new_words_today += added
		save()

func get_active_pool(all_words: Array) -> Array:
	if words_introduced.is_empty():
		return []
	var rank_set = {}
	for rank in words_introduced:
		rank_set[rank] = true
	var pool = []
	for word in all_words:
		if rank_set.has(word["rank"]):
			pool.append(word)
	return pool

func add_stars(amount: int) -> void:
	total_stars += amount
	save()

func save_settings() -> void:
	saved_move_speed         = QuizManager.base_move_speed
	saved_new_words_per_day  = QuizManager.new_words_per_day
	save()

# ─────────────────────────────────────────────────────────────

func save() -> void:
	var data = {
		"last_played_date":        last_played_date,
		"words_introduced":        words_introduced,
		"new_words_today":         new_words_today,
		"total_stars":             total_stars,
		"streak":                  streak,
		"saved_move_speed":        saved_move_speed,
		"saved_new_words_per_day": saved_new_words_per_day
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	else:
		printerr("SaveManager: could not write save file")

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		printerr("SaveManager: could not read save file")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		printerr("SaveManager: corrupt save file — resetting")
		return

	last_played_date         = parsed.get("last_played_date",        "")
	words_introduced         = parsed.get("words_introduced",        [])
	new_words_today          = parsed.get("new_words_today",         0)
	total_stars              = parsed.get("total_stars",             0)
	streak                   = parsed.get("streak",                  0)
	saved_move_speed         = parsed.get("saved_move_speed",        15.0)
	saved_new_words_per_day  = parsed.get("saved_new_words_per_day", 10)
