extends Node

# ─────────────────────────────────────────────────────────────
# WordPacks — Autoload singleton  (Scripts/word_packs.gd)
# Add to Autoloads as "WordPacks" (above SaveManager)
#
# Price = size * 20  (e.g. 500 words = 10,000 stars)
# Free packs have price = 0.
# ─────────────────────────────────────────────────────────────

const PRICE_PER_WORD = 20

const PACKS: Array = [
	{
		"id":   "hsk1",
		"name": "HSK 1",
		"desc": "500 most common Mandarin words",
		"file": "res://hsk1_words.json",
		"size": 500,
		"free": true
	},
	
	{
	"id":   "hsk2",
	"name": "HSK 2",
	"desc": "HSK level 2 vocabulary",
	"file": "res://hsk2_words.json",
	"size": 772,
	"free": false
	}
	# Future packs — uncomment and add JSON file when ready:
	# {
	#   "id":   "hsk2",
	#   "name": "HSK 2",
	#   "desc": "HSK level 2 vocabulary",
	#   "file": "res://hsk2_words.json",
	#   "size": 500,
	#   "free": false
	# },
	# {
	#   "id":   "food",
	#   "name": "Food & Drink",
	#   "desc": "Essential food vocabulary",
	#   "file": "res://food_words.json",
	#   "size": 120,
	#   "free": false
	# },
]

func get_pack(id: String) -> Dictionary:
	for pack in PACKS:
		if pack["id"] == id:
			return _with_price(pack)
	return {}

func get_all_packs() -> Array:
	var result = []
	for pack in PACKS:
		result.append(_with_price(pack))
	return result

func _with_price(pack: Dictionary) -> Dictionary:
	var p = pack.duplicate()
	p["price"] = 0 if pack.get("free", false) else pack["size"] * PRICE_PER_WORD
	return p

func load_words_for_pack(id: String) -> Array:
	var pack = get_pack(id)
	if pack.is_empty():
		printerr("WordPacks: pack not found: ", id)
		return []
	var path = pack["file"]
	if not FileAccess.file_exists(path):
		printerr("WordPacks: word file not found: ", path)
		return []
	var file   = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Array else []
