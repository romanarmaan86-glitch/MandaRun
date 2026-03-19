extends Resource
class_name SaveData

# save_data.gd  (Scripts/save_data.gd)

@export var last_played_date:        String     = ""
@export var words_introduced:        Array      = []
@export var words_seen:              Array      = []
@export var word_levels:             Dictionary = {}
@export var word_streaks:            Dictionary = {}
@export var new_words_today:         int        = 0
@export var total_stars:             int        = 0
@export var streak:                  int        = 0
@export var saved_move_speed:        float      = 15.0
@export var saved_new_words_per_day: int        = 10
@export var owned_packs:             Array      = ["hsk1"]   # hsk1 is free/default
@export var active_pack:             String     = "hsk1"
