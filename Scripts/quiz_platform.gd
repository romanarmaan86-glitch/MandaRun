extends Node3D

# ─────────────────────────────────────────────────────────────
# quiz_platform.gd
# Attach to a platform scene that is 3× longer than a normal platform
# (PLATFORM_LENGTH = 60.0 recommended so the player has time to read).
#
# This script:
#   1. Asks QuizManager for the current question on _ready
#   2. Spawns 3 answer panels, one per lane, near the far end
#   3. Tells the HUD to show the question
#   4. Listens for QuizManager.question_answered → shows flash overlay
#   5. On exit (platform scrolls off) calls QuizManager.skip_question
#      if the player never hit a panel
# ─────────────────────────────────────────────────────────────

const LANES: Array[float] = [-1.5, 0.0, 1.5]

# How far along the platform (local X) the panels sit.
# Place them toward the end so the player has time to read the question.
const PANEL_X: float = 22.0

# Panel visual dimensions
const PANEL_SIZE: Vector3 = Vector3(0.1, 2.0, 2.8)   # thin, tall, wide per lane

@export var answer_panel_scene: PackedScene   # assign answer_panel.tscn in editor

# Reference to the HUD QuizBox (set by platformspawner or main scene)
var hud_quiz_box: Control = null

var _panels_spawned: bool = false
var _question_done: bool = false

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Generate a fresh question for this platform
	QuizManager.generate_question()

	_spawn_panels()
	_show_hud_question()

	# Listen for answer result
	QuizManager.question_answered.connect(_on_question_answered)

func _spawn_panels() -> void:
	if answer_panel_scene == null:
		printerr("quiz_platform: answer_panel_scene not assigned!")
		return

	var q = QuizManager.current_question
	if q.is_empty():
		return

	for i in 3:
		var panel = answer_panel_scene.instantiate() as Area3D
		panel.lane_index = i
		panel.position = Vector3(PANEL_X, 1.0, LANES[i])

		# Build the mesh programmatically (no dependency on a pre-made mesh)
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = PANEL_SIZE
		mesh_inst.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.15, 0.35)   # dark blue-grey panel
		mat.roughness = 0.8
		mesh_inst.material_override = mat
		panel.add_child(mesh_inst)

		# Collision shape
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = PANEL_SIZE
		col.shape = shape
		panel.add_child(col)

		# Label3D for the answer text
		var lbl = Label3D.new()
		lbl.text = q["answers"][i]
		lbl.font_size = 28
		lbl.modulate = Color.WHITE
		lbl.position = Vector3(0.07, 0.0, 0.0)   # slightly in front of panel face
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		# Rotate label to face the player (player approaches from -X direction)
		lbl.rotation_degrees = Vector3(0, -90, 0)
		panel.add_child(lbl)

		add_child(panel)

	_panels_spawned = true

func _show_hud_question() -> void:
	var q = QuizManager.current_question
	if q.is_empty():
		return

	# Try to find the HUD QuizBox automatically if not set
	if hud_quiz_box == null:
		hud_quiz_box = _find_quiz_box()

	if hud_quiz_box == null:
		printerr("quiz_platform: could not find HUD QuizBox node")
		return

	var word = q["word"]

	# Set labels — the QuizBox Control node should have these children:
	#   Label named "Chinese"  → Chinese character
	#   Label named "Pinyin"   → pinyin
	#   Label named "Meaning"  → English meaning hidden (shown as "???")
	var chinese_lbl = hud_quiz_box.get_node_or_null("Chinese")
	var pinyin_lbl  = hud_quiz_box.get_node_or_null("Pinyin")
	var meaning_lbl = hud_quiz_box.get_node_or_null("Meaning")

	if chinese_lbl: chinese_lbl.text = word["chinese"]
	if pinyin_lbl:  pinyin_lbl.text  = word["pinyin"]
	if meaning_lbl: meaning_lbl.text = "???"   # player must pick the correct meaning

	hud_quiz_box.visible = true

func _find_quiz_box() -> Control:
	# Walk up to the scene root and look for a node named "QuizBox"
	var root = get_tree().current_scene
	if root:
		return root.find_child("QuizBox", true, false) as Control
	return null

# ─────────────────────────────────────────────────────────────
# Called by QuizManager signal after the player hits a panel

func _on_question_answered(correct: bool, correct_lane: int) -> void:
	if _question_done:
		return
	_question_done = true

	_highlight_correct_panel(correct_lane, correct)
	_show_flash_overlay(correct)

	# Hide HUD question after a short delay
	await get_tree().create_timer(1.5).timeout
	_hide_hud_question()

func _highlight_correct_panel(correct_lane: int, _player_was_correct: bool) -> void:
	# Find the panels we added and recolour them
	for child in get_children():
		if child is Area3D and child.has_method("set_answer_text"):
			var mesh = child.get_node_or_null("MeshInstance3D")
			if mesh == null:
				continue
			var mat = StandardMaterial3D.new()
			if child.lane_index == correct_lane:
				mat.albedo_color = Color(0.1, 0.75, 0.2)   # green = correct
			else:
				mat.albedo_color = Color(0.6, 0.1, 0.1)    # red = wrong
			mesh.material_override = mat

func _show_flash_overlay(correct: bool) -> void:
	# Look for a CanvasLayer/ColorRect named "FlashOverlay" in the HUD
	var flash = get_tree().current_scene.find_child("FlashOverlay", true, false) as ColorRect
	if flash == null:
		return
	flash.color = Color(0.1, 0.8, 0.1, 0.35) if correct else Color(0.8, 0.1, 0.1, 0.35)
	flash.visible = true
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func(): flash.visible = false; flash.modulate.a = 1.0)

func _hide_hud_question() -> void:
	if hud_quiz_box:
		hud_quiz_box.visible = false

# ─────────────────────────────────────────────────────────────
# When platform scrolls off screen, mark skipped if unanswered

func _exit_tree() -> void:
	if not _question_done:
		QuizManager.skip_question()
	_hide_hud_question()
	if QuizManager.question_answered.is_connected(_on_question_answered):
		QuizManager.question_answered.disconnect(_on_question_answered)
