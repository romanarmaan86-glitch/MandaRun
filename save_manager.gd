extends Node

# ─────────────────────────────────────────────────────────────
# SaveManager — Autoload singleton  (Scripts/save_manager.gd)
# Must be ABOVE QuizManager in the Autoload list.
# ─────────────────────────────────────────────────────────────

const SAVE_PATH = "user://save.tres"

# _data is created immediately so accessors never hit a null reference
# even if something reads SaveManager before _ready() finishes.
var _data: SaveData = SaveData.new()

# ─────────────────────────────────────────────────────────────
# Accessors — rest of codebase uses SaveManager.streak etc.

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
	load_save()          # overwrites _data with saved values
	_check_day_change()  # must run BEFORE _apply_saved_settings
						 # so streak is correct before anything reads it
	_apply_saved_settings()

func _apply_saved_settings() -> void:
	QuizManager.base_move_speed   = _data.saved_move_speed
	QuizManager.move_speed        = _data.saved_move_speed
	QuizManager.new_words_per_day = _data.saved_new_words_per_day

func _check_day_change() -> void:
	var today = _today_string()

	if _data.last_played_date == "":
		# First ever launch
		_data.last_played_date = today
		_data.streak           = 0
		save()
		return

	if today == _data.last_played_date:
		return   # Same day, nothing to do

	# New day
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

	# Build lookup of already-introduced ranks
	var introduced_set = {}
	for rank in _data.words_introduced:
		introduced_set[rank] = true

	# Build a new array — reassigning fixes the Resource dirty-tracking bug
	# where appending to the existing array doesn't mark the resource as changed
	var new_list: Array = _data.words_introduced.duplicate()
	var added = 0

	for word in all_words:
		if added >= remaining:
			break
		var rank = word["rank"]
		if not introduced_set.has(rank):
			new_list.append(rank)
			introduced_set[rank] = true
			added += 1

	if added > 0:
		_data.words_introduced = new_list   # reassign so Resource tracks the change
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
	if not ResourceLoader.exists(SAVE_PATH):
		# No save file yet — _data is already a fresh SaveData from var declaration
		return

	var loaded = ResourceLoader.load(SAVE_PATH)
	if loaded is SaveData:
		_data = loaded
	else:
		printerr("SaveManager: corrupt save — starting fresh")
		_data = SaveData.new()
