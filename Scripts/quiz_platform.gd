extends Node3D

# ─────────────────────────────────────────────────────────────
# quiz_platform.gd  (Scripts/quiz_platform.gd)
# ─────────────────────────────────────────────────────────────

const LANES: Array[float]    = [-1.5, 0.0, 1.5]
const PLATFORM_LENGTH: float = 60.0
const PANEL_X: float         = 45.0
const PANEL_SIZE: Vector3    = Vector3(0.2, 3.0, 2.9)

const COLOR_IDLE    = Color(0.08, 0.08, 0.45)
const COLOR_CORRECT = Color(0.08, 0.72, 0.18)
const COLOR_WRONG   = Color(0.72, 0.08, 0.08)

const QUIZ_PLATFORM_LENGTH: float = PLATFORM_LENGTH

var _question_done: bool = false
var _panel_meshes:  Array = []   # MeshInstance3D refs

var _quiz_box:    Control   = null
var _lbl_chinese: Label     = null
var _lbl_pinyin:  Label     = null
var _lbl_english: Label     = null
var _flash:       ColorRect = null

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_cache_hud_nodes()
	QuizManager.generate_question()
	_build_panels()
	_reset_panel_colours()       # always start idle — clears any leftover tint
	_show_hud_question()         # question visible immediately from spawn
	QuizManager.question_answered.connect(_on_question_answered)

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
	var q = QuizManager.current_question
	if q.is_empty():
		return
	var word = q["word"]
	if _lbl_chinese: _lbl_chinese.text    = word["chinese"]
	if _lbl_pinyin:  _lbl_pinyin.text     = word["pinyin"]
	if _lbl_english:
		_lbl_english.text     = "???"
		_lbl_english.modulate = Color.WHITE
	if _quiz_box:    _quiz_box.visible    = true

func _hide_hud_question() -> void:
	if _quiz_box: _quiz_box.visible = false

# ─────────────────────────────────────────────────────────────
# ANSWER PANELS

func _build_panels() -> void:
	var q = QuizManager.current_question
	if q.is_empty():
		return

	for i in 3:
		var area = Area3D.new()

		# Collision
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = PANEL_SIZE
		col.shape = shape
		area.add_child(col)

		# Mesh
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = PANEL_SIZE
		mesh_inst.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = COLOR_IDLE
		mat.roughness = 0.5
		mesh_inst.material_override = mat
		area.add_child(mesh_inst)
		_panel_meshes.append(mesh_inst)

		# Label — FIX: -90 so text faces the approaching player correctly
		var lbl = Label3D.new()
		lbl.text             = q["answers"][i]
		lbl.font_size        = 64
		lbl.modulate         = Color.WHITE
		lbl.outline_size     = 6
		lbl.outline_modulate = Color.BLACK
		lbl.double_sided     = true
		lbl.billboard        = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.rotation_degrees = Vector3(0, -90, 0)   # FIX: was +90, text was mirrored
		lbl.pixel_size       = 0.005
		lbl.width            = 300
		lbl.autowrap_mode    = TextServer.AUTOWRAP_WORD
		lbl.position         = Vector3(-0.15, 0.0, 0.0)
		area.add_child(lbl)

		area.position = Vector3(PANEL_X, 1.5, LANES[i])
		area.body_entered.connect(_on_panel_body_entered.bind(i))
		add_child(area)

# Resets all panels to idle colour — called on _ready to clear
# any colour that leaked from the previous quiz platform instance.
func _reset_panel_colours() -> void:
	for mesh_inst in _panel_meshes:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = COLOR_IDLE
		mat.roughness = 0.5
		mesh_inst.material_override = mat

# ─────────────────────────────────────────────────────────────
# ANSWER LOGIC

func _on_panel_body_entered(body: Node3D, lane: int) -> void:
	if _question_done:
		return
	if not body.is_in_group("player"):
		return
	_question_done = true
	QuizManager.submit_answer(lane)

func _on_question_answered(correct: bool, _correct_lane: int) -> void:
	_reveal_answer(correct)
	_show_flash(correct)

func _reveal_answer(correct: bool) -> void:
	var q = QuizManager.current_question
	if _lbl_english and not q.is_empty():
		_lbl_english.text     = q["word"]["meaning"]
		_lbl_english.modulate = Color(0.3, 1.0, 0.3) if correct else Color(1.0, 0.4, 0.4)

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
		QuizManager.skip_question()
	_hide_hud_question()
	if _lbl_english:
		_lbl_english.modulate = Color.WHITE
	if QuizManager.question_answered.is_connected(_on_question_answered):
		QuizManager.question_answered.disconnect(_on_question_answered)
