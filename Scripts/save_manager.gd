extends Node

# ─────────────────────────────────────────────────────────────
# SaveManager — Autoload singleton  (Scripts/save_manager.gd)
# Must be ABOVE QuizManager in the Autoload list.
# ─────────────────────────────────────────────────────────────

const SAVE_PATH          = "user://save.tres"
const MAX_LEVEL          = 5
const STREAK_TO_LEVEL_UP = 3

var _data: SaveData = SaveData.new()

# ─────────────────────────────────────────────────────────────
# Accessors

var last_played_date: String:
	get: return _data.last_played_date
	set(v): _data.last_played_date = v

var words_introduced: Array:
	get: return _data.words_introduced
	set(v): _data.words_introduced = v

var words_seen: Array:
	get: return _data.words_seen
	set(v): _data.words_seen = v

var word_levels: Dictionary:
	get: return _data.word_levels
	set(v): _data.word_levels = v

var word_streaks: Dictionary:
	get: return _data.word_streaks
	set(v): _data.word_streaks = v

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

var owned_packs: Array:
	get: return _data.owned_packs
	set(v): _data.owned_packs = v

var active_pack: String:
	get: return _data.active_pack
	set(v): _data.active_pack = v

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	load_save()
	_check_day_change()
	_apply_saved_settings()

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
# Pack ownership

func owns_pack(pack_id: String) -> bool:
	return _data.owned_packs.has(pack_id)

func buy_pack(pack_id: String, price: int) -> bool:
	if owns_pack(pack_id):
		return false
	if _data.total_stars < price:
		return false
	_data.total_stars -= price
	var new_owned = _data.owned_packs.duplicate()
	new_owned.append(pack_id)
	_data.owned_packs = new_owned
	save()
	return true

func set_active_pack(pack_id: String) -> void:
	if not owns_pack(pack_id):
		return
	_data.active_pack = pack_id
	save()

# ─────────────────────────────────────────────────────────────
# Word pool — scoped to active pack

func introduce_new_words(all_words: Array, max_new: int) -> void:
	var remaining = max_new - _data.new_words_today
	if remaining <= 0:
		return
	var introduced_set = {}
	for rank in _data.words_introduced:
		introduced_set[rank] = true
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
		_data.words_introduced = new_list
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

# ─────────────────────────────────────────────────────────────
# Word seen / mastery

func has_seen(rank: int) -> bool:
	return _data.words_seen.has(rank)

func mark_word_seen(rank: int) -> void:
	if _data.words_seen.has(rank):
		return
	var new_seen = _data.words_seen.duplicate()
	new_seen.append(rank)
	_data.words_seen = new_seen
	var new_levels = _data.word_levels.duplicate()
	if not new_levels.has(str(rank)):
		new_levels[str(rank)] = 0
	_data.word_levels = new_levels
	var new_streaks = _data.word_streaks.duplicate()
	if not new_streaks.has(str(rank)):
		new_streaks[str(rank)] = 0
	_data.word_streaks = new_streaks
	save()

func get_level(rank: int) -> int:
	return _data.word_levels.get(str(rank), 0)

func get_word_streak(rank: int) -> int:
	return _data.word_streaks.get(str(rank), 0)

func record_correct(rank: int) -> void:
	var new_levels  = _data.word_levels.duplicate()
	var new_streaks = _data.word_streaks.duplicate()
	var current_level  = new_levels.get(str(rank), 0)
	var current_streak = new_streaks.get(str(rank), 0) + 1
	if current_streak >= STREAK_TO_LEVEL_UP:
		new_levels[str(rank)]  = min(current_level + 1, MAX_LEVEL)
		new_streaks[str(rank)] = 0
	else:
		new_streaks[str(rank)] = current_streak
	_data.word_levels  = new_levels
	_data.word_streaks = new_streaks
	save()

func record_wrong(rank: int) -> void:
	var new_levels  = _data.word_levels.duplicate()
	var new_streaks = _data.word_streaks.duplicate()
	new_levels[str(rank)]  = max(new_levels.get(str(rank), 0) - 1, 0)
	new_streaks[str(rank)] = 0
	_data.word_levels  = new_levels
	_data.word_streaks = new_streaks
	save()

func reset_word(rank: int) -> void:
	var new_seen = _data.words_seen.duplicate()
	new_seen.erase(rank)
	_data.words_seen = new_seen
	var new_introduced = _data.words_introduced.duplicate()
	new_introduced.erase(rank)
	_data.words_introduced = new_introduced
	var new_levels = _data.word_levels.duplicate()
	new_levels.erase(str(rank))
	_data.word_levels = new_levels
	var new_streaks = _data.word_streaks.duplicate()
	new_streaks.erase(str(rank))
	_data.word_streaks = new_streaks
	save()

# ─────────────────────────────────────────────────────────────

func add_stars(amount: int) -> void:
	_data.total_stars += amount
	save()

func save_settings() -> void:
	_data.saved_move_speed        = QuizManager.base_move_speed
	_data.saved_new_words_per_day = QuizManager.new_words_per_day
	save()

func save() -> void:
	var err = ResourceSaver.save(_data, SAVE_PATH)
	if err != OK:
		printerr("SaveManager: failed to save — error ", err)

func load_save() -> void:
	if not ResourceLoader.exists(SAVE_PATH):
		return
	var loaded = ResourceLoader.load(SAVE_PATH)
	if loaded is SaveData:
		_data = loaded
	else:
		printerr("SaveManager: corrupt save — starting fresh")
		_data = SaveData.new()
