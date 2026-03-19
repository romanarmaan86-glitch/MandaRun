extends Resource
class_name SaveData

# save_data.gd  (Scripts/save_data.gd)
# This is the data container — just properties, no logic.

@export var last_played_date:        String = ""
@export var words_introduced:        Array  = []
@export var new_words_today:         int    = 0
@export var total_stars:             int    = 0
@export var streak:                  int    = 0
@export var saved_move_speed:        float  = 15.0
@export var saved_new_words_per_day: int    = 10
