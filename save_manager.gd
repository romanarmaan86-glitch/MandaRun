extends Node

# ─────────────────────────────────────────────────────────────
# SaveManager — Autoload singleton  (Scripts/save_manager.gd)
# Add to Autoloads ABOVE QuizManager.
# ─────────────────────────────────────────────────────────────

const SAVE_PATH = "user://save.tres"

var _data: SaveData = null

# ─────────────────────────────────────────────────────────────
# Convenience accessors

var last_played_date: String:
	get: return _data.last_played_date
	set(v): _data.last_played_date = v

var words_introduced: Array:
	get: return _data.words_introduced
	set(v): _data.words_introduced = v

var new_words_today: int:
	get: return _data.new_words_today
	set(v): _data.new_words_today = v

var total_stars: int:
	get: return _data.total_stars
	set(v): _data.total_stars = v

var streak: int:
	get: return _data.streak
	set(v): _data.streak = v

var saved_move_speed: float:
	get: return _data.saved_move_speed
	set(v): _data.saved_move_speed = v

var saved_new_words_per_day: int:
	get: return _data.saved_new_words_per_day
	set(v): _data.saved_new_words_per_day = v

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	load_save()
	_apply_saved_settings()
	_check_day_change()

func _apply_saved_settings() -> void:
	QuizManager.base_move_speed   = _data.saved_move_speed
	QuizManager.move_speed        = _data.saved_move_speed
	QuizManager.new_words_per_day = _data.saved_new_words_per_day

func _check_day_change() -> void:
	var today = _today_string()

	if _data.last_played_date == "":
		_data.last_played_date = today
		_data.streak           = 0
		save()
		return

	if today == _data.last_played_date:
		return

	if _is_consecutive(_data.last_played_date, today):
		_data.streak += 1
	else:
		_data.streak = 1

	_data.last_played_date = today
	_data.new_words_today  = 0
	save()

func _today_string() -> String:
	var t = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t["year"], t["month"], t["day"]]

func _is_consecutive(prev: String, today: String) -> bool:
	if prev.length() < 10 or today.length() < 10:
		return false
	var prev_unix  = Time.get_unix_time_from_datetime_string(prev  + "T00:00:00")
	var today_unix = Time.get_unix_time_from_datetime_string(today + "T00:00:00")
	return (today_unix - prev_unix) == 86400

# ─────────────────────────────────────────────────────────────

func introduce_new_words(all_words: Array, max_new: int) -> void:
	var remaining = max_new - _data.new_words_today
	if remaining <= 0:
		return

	var introduced_set = {}
	for rank in _data.words_introduced:
		introduced_set[rank] = true

	var added = 0
	for word in all_words:
		if added >= remaining:
			break
		var rank = word["rank"]
		if not introduced_set.has(rank):
			_data.words_introduced.append(rank)
			introduced_set[rank] = true
			added += 1

	if added > 0:
		_data.new_words_today += added
		save()

func get_active_pool(all_words: Array) -> Array:
	if _data.words_introduced.is_empty():
		return []
	var rank_set = {}
	for rank in _data.words_introduced:
		rank_set[rank] = true
	var pool = []
	for word in all_words:
		if rank_set.has(word["rank"]):
			pool.append(word)
	return pool

func add_stars(amount: int) -> void:
	_data.total_stars += amount
	save()

func save_settings() -> void:
	_data.saved_move_speed        = QuizManager.base_move_speed
	_data.saved_new_words_per_day = QuizManager.new_words_per_day
	save()

# ─────────────────────────────────────────────────────────────

func save() -> void:
	var err = ResourceSaver.save(_data, SAVE_PATH)
	if err != OK:
		printerr("SaveManager: failed to save — error ", err)

func load_save() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded = ResourceLoader.load(SAVE_PATH)
		if loaded is SaveData:
			_data = loaded
			return
		else:
			printerr("SaveManager: save file corrupt or wrong type — resetting")
	_data = SaveData.new()
