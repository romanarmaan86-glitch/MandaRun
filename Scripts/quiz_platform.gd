extends Node3D

# ─────────────────────────────────────────────────────────────
# quiz_platform.gd  (Scripts/quiz_platform.gd)
# ─────────────────────────────────────────────────────────────

const LANES: Array[float]    = [-1.5, 0.0, 1.5]
const PLATFORM_LENGTH: float = 60.0
const PANEL_X: float         = 45.0
const PANEL_SIZE: Vector3    = Vector3(0.2, 3.0, 1.45)

const TRIGGER_SIZE: Vector3  = Vector3(40.0, 4.0, 6.0)
const TRIGGER_X: float       = 20.0

const COLOR_IDLE = Color(0.08, 0.08, 0.45)

const QUIZ_PLATFORM_LENGTH: float = PLATFORM_LENGTH

var _my_question:   Dictionary = {}
var _question_done: bool       = false
var _hud_shown:     bool       = false
var _panel_meshes:  Array      = []

var _quiz_box:    Control   = null
var _lbl_chinese: Label     = null
var _lbl_pinyin:  Label     = null
var _lbl_english: Label     = null
var _flash:       ColorRect = null

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_cache_hud_nodes()
	QuizManager.generate_question()
	_my_question = QuizManager.current_question.duplicate(true)
	_build_trigger_zone()
	_build_panels()
	QuizManager.question_answered.connect(_on_question_answered)

# ─────────────────────────────────────────────────────────────
# TRIGGER ZONE

func _build_trigger_zone() -> void:
	var area  = Area3D.new()
	var col   = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = TRIGGER_SIZE
	col.shape  = shape
	area.add_child(col)
	area.position = Vector3(TRIGGER_X, 1.0, 0.0)
	area.body_entered.connect(_on_trigger_entered)
	add_child(area)

func _on_trigger_entered(body: Node3D) -> void:
	if _hud_shown or not body.is_in_group("player"):
		return
	_hud_shown = true
	_show_hud_question()

# ─────────────────────────────────────────────────────────────
# HUD

func _cache_hud_nodes() -> void:
	var scene = get_tree().current_scene
	_quiz_box    = scene.find_child("QuizBox",      true, false) as Control
	_lbl_chinese = scene.find_child("Chinese",      true, false) as Label
	_lbl_pinyin  = scene.find_child("Pinyin",       true, false) as Label
	_lbl_english = scene.find_child("English",      true, false) as Label
	_flash       = scene.find_child("FlashOverlay", true, false) as ColorRect

func _show_hud_question() -> void:
	if _my_question.is_empty():
		return
	var word = _my_question["word"]
	if _lbl_chinese: _lbl_chinese.text    = word["chinese"]
	if _lbl_pinyin:  _lbl_pinyin.text     = word["pinyin"]
	if _lbl_english:
		_lbl_english.text     = "???"
		_lbl_english.modulate = Color.WHITE
	if _quiz_box:    _quiz_box.visible    = true

# After answering: keep question visible and reveal the correct meaning
func _reveal_hud_answer(correct: bool) -> void:
	if _my_question.is_empty():
		return
	var word = _my_question["word"]
	# Chinese and pinyin stay the same — just reveal the meaning
	if _lbl_english:
		_lbl_english.text     = word["meaning"]
		_lbl_english.modulate = Color(0.3, 1.0, 0.3) if correct else Color(1.0, 0.4, 0.4)
	# QuizBox stays visible so the player can read the answer as they run off

func _hide_hud_question() -> void:
	if _quiz_box: _quiz_box.visible = false

# ─────────────────────────────────────────────────────────────
# ANSWER PANELS

func _build_panels() -> void:
	if _my_question.is_empty():
		return

	for i in 3:
		var area = Area3D.new()

		var col   = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = PANEL_SIZE
		col.shape  = shape
		area.add_child(col)

		var mesh_inst = MeshInstance3D.new()
		var box       = BoxMesh.new()
		box.size      = PANEL_SIZE
		mesh_inst.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = COLOR_IDLE
		mat.roughness    = 0.5
		mesh_inst.material_override = mat
		area.add_child(mesh_inst)
		_panel_meshes.append(mesh_inst)

		var lbl = Label3D.new()
		lbl.text             = _my_question["answers"][i]
		lbl.font_size        = 60
		lbl.modulate         = Color.WHITE
		lbl.outline_size     = 6
		lbl.outline_modulate = Color.BLACK
		lbl.double_sided     = true
		lbl.billboard        = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.rotation_degrees = Vector3(0, -90, 0)
		lbl.pixel_size       = 0.005
		lbl.width            = 280
		lbl.autowrap_mode    = TextServer.AUTOWRAP_WORD
		lbl.position         = Vector3(-0.15, 0.0, 0.0)
		area.add_child(lbl)

		area.position = Vector3(PANEL_X, 1.5, LANES[i])
		area.body_entered.connect(_on_panel_body_entered.bind(i))
		add_child(area)

# ─────────────────────────────────────────────────────────────
# ANSWER LOGIC

func _on_panel_body_entered(body: Node3D, lane: int) -> void:
	if _question_done or not body.is_in_group("player"):
		return
	_question_done = true
	QuizManager.current_question = _my_question.duplicate(true)
	QuizManager.submit_answer(lane)

func _on_question_answered(correct: bool, _correct_lane: int) -> void:
	_reveal_hud_answer(correct)   # show correct meaning in HUD, keep question visible
	_show_flash(correct)

func _show_flash(correct: bool) -> void:
	if _flash == null:
		return
	_flash.color    = Color(0.1, 0.9, 0.1, 0.45) if correct else Color(0.9, 0.1, 0.1, 0.45)
	_flash.modulate = Color.WHITE
	_flash.visible  = true
	var tween = create_tween()
	tween.tween_property(_flash, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func():
		_flash.visible  = false
		_flash.modulate = Color.WHITE
	)

# ─────────────────────────────────────────────────────────────

func _exit_tree() -> void:
	if not _question_done:
		QuizManager.run_results.append({
			"chinese":      _my_question.get("word", {}).get("chinese", ""),
			"pinyin":       _my_question.get("word", {}).get("pinyin", ""),
			"meaning":      _my_question.get("word", {}).get("meaning", ""),
			"correct":      false,
			"answered":     false,
			"correct_lane": _my_question.get("correct_lane", -1),
			"answers":      _my_question.get("answers", [])
		})
	_hide_hud_question()
	if _lbl_english:
		_lbl_english.modulate = Color.WHITE
	if QuizManager.question_answered.is_connected(_on_question_answered):
		QuizManager.question_answered.disconnect(_on_question_answered)
